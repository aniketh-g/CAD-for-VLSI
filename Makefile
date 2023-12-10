.PHONY: test
test:
	@bsc imac_types.bsv
	@bsc -verilog imac.bsv +RTS -K40000M +RTS
	@bsc -verilog imac_tb.bsv +RTS -K40000M +RTS
	@bsc -e imac_tb imac_tb.v +RTS -K40000M +RTS
	@./a.out

.PHONY: synthesize
synthesize:
	@yosys -o output.blif -S mkIMAc64.v 

.PHONY: clean
clean:
	@rm -r *.bo *.v *.out *.blif
	@echo "Cleaned"
