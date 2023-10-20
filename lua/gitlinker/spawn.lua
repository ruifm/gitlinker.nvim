-- port from: https://github.com/linrongbin16/fzfx.nvim/main/lua/fzfx/utils.lua

--- @param s string
--- @param t string
--- @param start integer?
--- @return integer?
local function string_find(s, t, start)
    -- start = start or 1
    -- local result = vim.fn.stridx(s, t, start - 1)
    -- return result >= 0 and (result + 1) or nil

    start = start or 1
    for i = start, #s do
        local match = true
        for j = 1, #t do
            if i + j - 1 > #s then
                match = false
                break
            end
            local a = string.byte(s, i + j - 1)
            local b = string.byte(t, j)
            if a ~= b then
                match = false
                break
            end
        end
        if match then
            return i
        end
    end
    return nil
end

--- @param filename string
--- @param opts {trim:boolean?}|nil
--- @return string?
local function readfile(filename, opts)
    opts = opts or { trim = true }
    opts.trim = opts.trim == nil and true or opts.trim

    local f = io.open(filename, "r")
    if f == nil then
        return nil
    end
    local content = vim.trim(f:read("*a"))
    f:close()
    return content
end

--- @param filename string
--- @return string[]?
local function readlines(filename)
    local results = {}
    for line in io.lines(filename) do
        table.insert(results, line)
    end
    return results
end

--- @alias SpawnLineConsumer fun(line:string):any
--- @class Spawn
--- @field cmds string[]
--- @field cwd string?
--- @field fn_out_line_consumer SpawnLineConsumer
--- @field fn_err_line_consumer SpawnLineConsumer
--- @field out_pipe uv_pipe_t
--- @field err_pipe uv_pipe_t
--- @field out_buffer string?
--- @field err_buffer string?
--- @field process_handle uv_process_t?
--- @field process_id integer|string|nil
--- @field _close_count integer
--- @field result {code:integer?,signal:integer?}?
local Spawn = {}

--- @param line string
local function dummy_stderr_line_consumer(line)
    -- if type(line) == "string" then
    --     io.write(string.format("AsyncSpawn:_on_stderr:%s", vim.inspect(line)))
    --     error(string.format("AsyncSpawn:_on_stderr:%s", vim.inspect(line)))
    -- end
end

--- @param cmds string[]
--- @param opts {on_stdout:SpawnLineConsumer,on_stderr:SpawnLineConsumer?,cwd:string?}
--- @return Spawn?
function Spawn:make(cmds, opts)
    local out_pipe = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
    local err_pipe = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
    if not out_pipe or not err_pipe then
        return nil
    end

    local o = {
        cmds = cmds,
        cwd = opts.cwd or vim.fn.getcwd(),
        fn_out_line_consumer = opts.on_stdout,
        fn_err_line_consumer = opts.on_stderr or dummy_stderr_line_consumer,
        out_pipe = out_pipe,
        err_pipe = err_pipe,
        out_buffer = nil,
        err_buffer = nil,
        process_handle = nil,
        process_id = nil,
        _close_count = 0,
        result = nil,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @param buffer string
--- @param fn_line_processor SpawnLineConsumer
--- @return integer
function Spawn:_consume_line(buffer, fn_line_processor)
    local i = 1
    while i <= #buffer do
        local newline_pos = string_find(buffer, "\n", i)
        if not newline_pos then
            break
        end
        local line = buffer:sub(i, newline_pos - 1)
        fn_line_processor(line)
        i = newline_pos + 1
    end
    return i
end

--- @param handle uv_handle_t
function Spawn:_close_handle(handle)
    if handle and not handle:is_closing() then
        handle:close(function()
            self._close_count = self._close_count + 1
            if self._close_count >= 3 then
                vim.loop.stop()
            end
        end)
    end
end

--- @param err string?
--- @param data string?
--- @return nil
function Spawn:_on_stdout(err, data)
    if err then
        self.out_pipe:read_stop()
        self:_close_handle(self.out_pipe)
        return
    end

    if data then
        -- append data to data_buffer
        self.out_buffer = self.out_buffer and (self.out_buffer .. data) or data
        self.out_buffer = self.out_buffer:gsub("\r\n", "\n")
        -- foreach the data_buffer and find every line
        local i = self:_consume_line(self.out_buffer, self.fn_out_line_consumer)
        -- truncate the printed lines if found any
        self.out_buffer = i <= #self.out_buffer
                and self.out_buffer:sub(i, #self.out_buffer)
            or nil
    else
        if self.out_buffer then
            -- foreach the data_buffer and find every line
            local i =
                self:_consume_line(self.out_buffer, self.fn_out_line_consumer)
            if i <= #self.out_buffer then
                local line = self.out_buffer:sub(i, #self.out_buffer)
                self.fn_out_line_consumer(line)
                self.out_buffer = nil
            end
        end
        self.out_pipe:read_stop()
        self:_close_handle(self.out_pipe)
    end
end

--- @param err string?
--- @param data string?
--- @return nil
function Spawn:_on_stderr(err, data)
    if err then
        io.write(
            string.format(
                "AsyncSpawn:_on_stderr, err:%s, data:%s",
                vim.inspect(err),
                vim.inspect(data)
            )
        )
        error(
            string.format(
                "AsyncSpawn:_on_stderr, err:%s, data:%s",
                vim.inspect(err),
                vim.inspect(data)
            )
        )
        self.err_pipe:read_stop()
        self:_close_handle(self.err_pipe)
        return
    end

    if data then
        -- append data to data_buffer
        self.err_buffer = self.err_buffer and (self.err_buffer .. data) or data
        self.err_buffer = self.err_buffer:gsub("\r\n", "\n")
        -- foreach the data_buffer and find every line
        local i = self:_consume_line(self.err_buffer, self.fn_err_line_consumer)
        -- truncate the printed lines if found any
        self.err_buffer = i <= #self.err_buffer
                and self.err_buffer:sub(i, #self.err_buffer)
            or nil
    else
        if self.err_buffer then
            -- foreach the data_buffer and find every line
            local i =
                self:_consume_line(self.err_buffer, self.fn_err_line_consumer)
            if i <= #self.err_buffer then
                local line = self.err_buffer:sub(i, #self.err_buffer)
                self.fn_err_line_consumer(line)
                self.err_buffer = nil
            end
        end
        self.err_pipe:read_stop()
        self:_close_handle(self.err_pipe)
    end
end

function Spawn:run()
    self.process_handle, self.process_id = vim.loop.spawn(self.cmds[1], {
        args = vim.list_slice(self.cmds, 2),
        cwd = self.cwd,
        stdio = { nil, self.out_pipe, self.err_pipe },
        hide = true,
        -- verbatim = true,
    }, function(code, signal)
        self.result = { code = code, signal = signal }
        self:_close_handle(self.process_handle)
    end)

    self.out_pipe:read_start(function(err, data)
        self:_on_stdout(err, data)
    end)
    self.err_pipe:read_start(function(err, data)
        self:_on_stderr(err, data)
    end)
    vim.loop.run()

    local max_timeout = 2 ^ 31
    vim.wait(max_timeout, function()
        return self._close_count == 3
    end)
end

local M = {
    string_find = string_find,
    readfile = readfile,
    readlines = readlines,
    Spawn = Spawn,
}

return M
