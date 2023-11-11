package multiplier;
// Package Imports
import Vector :: *;
import FIFO :: *;
// Project Imports
import imac_types :: *;

export multiplier::*;

// `define debug_functionality
`define debug_pipeline

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

// Pipelined Multiplier
module mkUSMult16(Ifc_IMAC#(n, m))
    provisos(Add#(1, b__, n));
    Reg#(MultState)                  state <- mkReg(Idle);
    FIFO#(Maybe#(Bit#(TAdd#(n, m)))) product <- mkFIFO;
    Reg#(Bit#(n))                    a <- mkReg(0);
    Reg#(Bit#(m))                    b <- mkReg(0);

    rule idle (state == Idle);
        product.clear();
        a       <= 0;
        b       <= 0;
    endrule : idle

    `ifdef debug_pipeline Reg#(Bit#(4)) counter <- mkReg(0); `endif
    
    rule compute;
        `ifdef debug_pipeline
        if(counter <= 12) counter <= counter + 1;
        if(counter <= 12) $display("State Compute a=%d, b=%d\n", a, b);
        else state <= Finish;
        `endif
        `ifdef debug_functionality $display("mkMult16 method compute; Compute (state %b)", state); `endif
        Vector#(m, Bit#(n)) s = newVector();
        Vector#(m, Bit#(n)) snew = newVector();
        Vector#(m, Bit#(n)) carries = newVector();
        
        `ifdef debug_functionality $display("sign_config = ", `SIGN); `endif

        for(Integer i = 0; i < valueOf(m); i = i + 1)
            for(Integer j = 0; j < valueOf(n); j = j + 1)
                if(((j == valueOf(n) - 1) || (i == valueOf(m) - 1)) && !((j == valueOf(n) - 1) && (i == valueOf(m) - 1))) s[i][j] = (a[j] & b[i])^`SIGN;
                else s[i][j] = a[j] & b[i];

        `ifdef debug_functionality for(Integer i = 0; i < valueOf(m); i = i + 1) $display("s[%d] = %b", i, s[i]); `endif

        carries[0] = 0;
        if(valueOf(n) == valueOf(m)) carries[0][valueOf(n)-1] = `SIGN;
        else begin
            carries[0][valueOf(n)-2] = `SIGN;
            carries[0][valueOf(m)-2] = `SIGN;
        end

        snew[0] = s[0];
        Bit#(TSub#(m,0)) array_sum = 0;
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

        Bit#(n) ripple_sum = {`SIGN, snew[valueOf(m)-1][valueOf(n)-1:1]}+carries[valueOf(m)-1];
        `ifdef debug_functionality $display("fs:%ba:%b", ripple_sum, array_sum); `endif
        
        let p = {ripple_sum, array_sum};
        product.enq(tagged Valid p);
    endrule : compute

    method Action start(Bit#(n) inpA, Bit#(m) inpB) if (state != Finish);
        a <= inpA;
        b <= inpB;
        state <= Compute;
        `ifdef debug_pipeline $display("mkMult16 method start, inputs %d, %d\n", inpA, inpB); `endif
        `ifdef debug_pipeline $display("mkMult16 method start, a = %d, b = %d\n", a, b); `endif
        `ifdef debug_functionality $display("mkMult16 method start; Idle (state %b)", state); `endif
    endmethod

    method ActionValue#(Bit#(TAdd#(n,m))) result if(isValid(product.first) && state != Finish);
        `ifdef debug_functionality $display("mkMult16 method result; AddPPs (state %b)", state); `endif
        let ans = product.first;
        product.deq();
        return fromMaybe(?, ans);
    endmethod

endmodule : mkUSMult16
endpackage : multiplier