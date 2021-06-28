all: lint format

lint:
	luacheck lua/*
format:
	stylua lua
