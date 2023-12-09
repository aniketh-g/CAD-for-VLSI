package multiplier;
// Package Imports
import Vector :: *;
import FIFO :: *;
// Project Imports
import imac_types :: *;

export multiplier::*;

// `define debug_functionality
// `define debug_pipeline

// Configure Signed/Unsigned Property of multiplier
`define SIGN 1'b1

// Adders
function Bit#(n) gen_carry(Bit#(n) snew_prev, Bit#(n) s, Bit#(n) cin);
    Bit#(n) cout = 0;
    for(Integer i=0; i<valueOf(n); i=i+1)
        if(i != valueOf(n) - 1) cout[i] = (snew_prev[i+1]&s[i])|(snew_prev[i+1]&cin[i])|(s[i]&cin[i]);
        else                    cout[i] = (s[i]&cin[i]);
    return cout;
endfunction
function Bit#(n) gen_sum(Bit#(n) snew_prev, Bit#(n) s, Bit#(n) cin);
    Bit#(n) sout;
    for(Integer i=0; i<valueOf(n); i=i+1)
        if(i != valueOf(n) - 1) sout[i] = snew_prev[i+1]^s[i]^cin[i];
        else                    sout[i] = (s[i]^cin[i]);
    return sout;
endfunction

// Pipelined IMAc unit
module mkIMAc(Ifc_IMAC#(n, m))
    provisos(Add#(1, b__, n));
    Reg#(MultState) state <- mkReg(Idle);
    Wire#(MultState) wr_state <- mkDWire(Idle);
    Reg#(Bit#(TAdd#(n, m))) product <- mkReg(0);
	Reg#(Maybe#(Bit#(TAdd#(n, m)))) accum <- mkReg(tagged Invalid);

    Wire#(Bit#(n)) wr_a <- mkDWire(0);
    Wire#(Bit#(m)) wr_b <- mkDWire(0);

    Reg#(Bit#(m)) p_reg_array_sum <- mkReg(0);
    Reg#(Bit#(TSub#(n,1))) p_reg_snew <- mkReg(0);
    Reg#(Bit#(n)) p_reg_carries <- mkReg(0);


    `ifdef debug_pipeline Reg#(Bit#(4)) counter <- mkReg(0); `endif
    
    rule rl_compute_mult;
        `ifdef debug_pipeline $display("wr_a = %d\nwr_b = %d", wr_a, wr_b); `endif
        Vector#(m, Bit#(n)) s = newVector();
        Vector#(m, Bit#(n)) snew = newVector();
        Vector#(m, Bit#(n)) carries = newVector();  

        for(Integer i = 0; i < valueOf(m); i = i + 1)
            for(Integer j = 0; j < valueOf(n); j = j + 1)
                if(((j == valueOf(n) - 1) || (i == valueOf(m) - 1)) && !((j == valueOf(n) - 1) && (i == valueOf(m) - 1))) s[i][j] = (wr_a[j] & wr_b[i])^`SIGN;
                else s[i][j] = wr_a[j] & wr_b[i];

        `ifdef debug_functionality for(Integer i = 0; i < valueOf(m); i = i + 1) $display("s[%d] = %b", i, s[i]); `endif

        carries[0] = 0;
        if(valueOf(n) == valueOf(m)) carries[0][valueOf(n)-1] = `SIGN;
        else begin
            carries[0][valueOf(n)-2] = `SIGN;
            carries[0][valueOf(m)-2] = `SIGN;
        end

        snew[0] = s[0];
        Bit#(m) array_sum = 0;
        for(Integer v = 0; v < valueOf(m); v = v + 1)
            if(v != valueOf(m) - 1) begin
                array_sum[v] = snew[v][0];
                `ifdef debug_functionality
                $write("snew[%d] %b, ", v, snew[v]);
                $write("s[%d] %b, ", v+1, s[v+1]);
                $write("carries[%d] %b\n", v, carries[v]);
                `endif
                carries[v+1] = gen_carry(snew[v], s[v+1], carries[v]);
                snew[v+1] = gen_sum(snew[v], s[v+1], carries[v]);
                `ifdef debug_functionality $display("carries[%d] = %b, snew[%d] = %b", v, carries[v], v, snew[v]); `endif
            end
            else begin
                array_sum[v] = snew[v][0];
                `ifdef debug_functionality $display("carries[%d] = %b, snew[%d] = %b", v, carries[v], v, snew[v]); `endif
            end
        if(wr_state == Compute_Mult) begin
            p_reg_array_sum <= array_sum;
            p_reg_snew      <= snew[valueOf(m)-1][valueOf(n)-1:1];
            p_reg_carries   <= carries[valueOf(m)-1];
        end
        state <= wr_state;
    endrule : rl_compute_mult

	rule rl_compute_add;
        Bit#(n) ripple_sum = {`SIGN, p_reg_snew}+p_reg_carries;
        `ifdef debug_functionality $display("fs:%ba:%b", ripple_sum, array_sum); `endif
        
        let p = {ripple_sum, p_reg_array_sum};

        if(state == Compute_Mult) begin
            product <= p;
            accum <= tagged Valid (fromMaybe(0, accum) + p);
        end
        `ifdef debug_pipeline $display("accum_old = %d\np = %d", accum, p); `endif
	endrule: rl_compute_add

    method Action start(Bit#(n) inpA, Bit#(m) inpB);
        wr_a <= inpA;
        wr_b <= inpB;
        wr_state <= Compute_Mult;
        `ifdef debug_pipeline $display("mkMult16 method start, inputs %d, %d\n", inpA, inpB); `endif
        `ifdef debug_functionality $display("mkMult16 method start; Idle (state %b)", state); `endif
	endmethod

	method Action rst;
		accum <= tagged Invalid;
	endmethod

	method Bit#(1) isRdy;
		return pack(isValid(accum));
	endmethod

    method Bit#(TAdd#(n,m)) result;
        `ifdef debug_functionality $display("mkMult16 method result; AddPPs (state %b)", state); `endif
		return fromMaybe(?, accum);
    endmethod

endmodule : mkIMAc
endpackage : multiplier