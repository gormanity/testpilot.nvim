test:
	nvim --headless -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/testpilot {minimal_init='tests/minimal_init.lua'}" \
		-c "qa"
