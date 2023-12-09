import multiplier::*;
import imac_types :: *; 

(* synthesize *)
module imac_tb(Empty);
	Ifc_IMAC#(64,64) imac <- mkIMAc;
	Reg#(Bit#(32)) cntr <- mkReg(0);

	rule count;
		cntr <= cntr + 1;
	endrule

	rule tb;
		if (cntr == 1) begin
	        imac.start(64'd2, 64'd3);
		end
		else if (cntr == 2) begin
	        imac.start(64'd3, 64'd4);
		end
		else if (cntr == 3) begin
	        imac.start(64'd4, 64'd5);
		end
		else if (cntr == 5) begin
	        imac.start(64'd5, 64'd6);
		end
		if (imac.isRdy() == 1) begin
			Bit#(128) ans = imac.result();
			$display("%d [TB] %d", cntr, ans);
		end

		if (cntr == 50) begin
			$display("[TB] timeout\n");
			$finish;
		end
	endrule

endmodule
