all: lint format

lint:
	luacheck lua/*
format:
	lua-format -i lua/**/*.lua
