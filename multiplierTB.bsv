import multiplier::*;
import imac_types :: *;
typedef enum {Idle, Cycle1, Cycle2, Cycle3, Finish} TbState deriving (Bits, Eq);

(*synthesize*)
module mkTest(Empty);
    Ifc_IMAC#(64,64) usMult <- mkUSMult16;
    Reg#(TbState) tbstate <- mkReg(Idle);

    rule start (tbstate == Idle);
        tbstate <= Cycle1;
        usMult.start(-64'd9223372036854775807, -64'd9223372036854775807);
    endrule
    
    rule cycle1 (tbstate == Cycle1);
        tbstate <= Cycle2;
        let ans <- usMult.result;
        usMult.start(64'd2, -64'd9223372036854775807);
        $display("Cycle 1 ans = %b = %d = -%d", ans, ans, ~ans+1);
    endrule : cycle1

    rule cycle2 (tbstate == Cycle2);
        tbstate <= Cycle3;
        let ans <- usMult.result;
        usMult.start(64'd3, -64'd9223372036854775807);
        $display("Cycle 2 ans = %b = %d = -%d", ans, ans, ~ans+1);
    endrule : cycle2

    rule cycle3 (tbstate == Cycle3);
        tbstate <= Finish;
        let ans <- usMult.result;
        usMult.start(64'd4, -64'd9223372036854775807);
        $display("Cycle 3 ans = %b = %d = -%d", ans, ans, ~ans+1);
    endrule : cycle3
   
endmodule : mkTest