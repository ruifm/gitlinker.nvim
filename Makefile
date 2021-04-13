lint:
	luacheck lua/*
format:
	lua-format -i lua/**/*.lua

.PHONY: lint
