-- install packer
local fn = vim.fn

local install_path = '/tmp/nvim/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  vim.fn.execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
end

vim.cmd [[set packpath=/tmp/nvim/site]]
vim.cmd [[autocmd BufWritePost minimal_init.lua PackerCompile]]
vim.cmd [[autocmd BufWritePost minimal_init.lua PackerInstall]]

local use = require('packer').use
require("packer").startup(
  {
    function()
      use 'wbthomason/packer.nvim'
      use {
          'ruifm/gitlinker.nvim',
          requires = 'nvim-lua/plenary.nvim',
      }
    end,
    config = {package_root = '/tmp/nvim/site/pack'}
  }
)
