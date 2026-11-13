NVIM ?= nvim

.PHONY: test

test:
	$(NVIM) --headless -u NONE -l tests/smoke.lua
