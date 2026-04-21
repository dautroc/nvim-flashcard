.PHONY: test lint format

test:
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/flashcard { minimal_init = 'tests/minimal_init.lua' }"

lint:
	stylua --check lua/ tests/ plugin/

format:
	stylua lua/ tests/ plugin/
