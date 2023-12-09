.PHONY: testMultiplier
testMultiplier:
	@bsc imac_types.bsv
	@bsc multiplier.bsv
	@bsc -verilog imac_tb.bsv +RTS -K40000M +RTS
	@bsc -e imac_tb imac_tb.v +RTS -K40000M +RTS
	@./a.out

.PHONY: clean
clean:
	@rm -r *.bo *.v *.out
	@echo "Cleaned"
