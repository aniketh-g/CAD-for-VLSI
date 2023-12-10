import imac::*;
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
	        imac.start(-64'd9223372036854775807, -64'd9223372036854775807);
		end
		else if (cntr == 2) begin
	        imac.start(-64'd9223372036854775807, 64'd9223372036854775807);
		end
		else if (cntr == 3) begin
	        imac.start(-64'd1, 64'd9223372036854775807);
		end
		else if (cntr == 10) begin
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
