.PHONY: testMultiplier
testMultiplier:
	@bsc imac_types.bsv
	@bsc multiplier.bsv
	@bsc -verilog multiplierTB.bsv +RTS -K40000M +RTS
	@bsc -e mkTest mkTest.v +RTS -K40000M +RTS
	@./a.out

.PHONY: clean
clean:
	@rm -r *.bo *.v *.out
	@echo "Cleaned"
