package imac_types;
import Vector :: *;
import FIFO :: *;

typedef struct {
    Bit#(n)      a;
    Bit#(m)      b;
    Bit#(id_len) id;
} IMAcInput;

typedef struct {
    Bit#(l)      result;
    Bit#(id_len) id;
} IMAcOutput;

interface Ifc_IMAC#(numeric type n, numeric type m);
    method Action start(Bit#(n) inpA, Bit#(m) inpB);
    method ActionValue#(Bit#(TAdd#(n, m))) result;
endinterface : Ifc_IMAC

typedef enum {Idle, Compute, Finish} MultState deriving (Bits, Eq);

endpackage : imac_types