# uart-vhdl Makefile

# Include configuration file
include config.mk

# Help message
help:
	@echo "Usage:"
	@echo "  make init " - Initialize the project, runs the init.sh script
	@echo ""
	@echo "Variables:"
	@echo ""
	
init:
	@echo "Initializing project..."
	@./init.sh
	@echo "Project has been initialized."
