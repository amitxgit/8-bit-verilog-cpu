// ============================================================
//  8-bit ALU
//  Operations selected by 4-bit opcode
// ============================================================
module alu (
    input  wire [7:0] a,        // Operand A
    input  wire [7:0] b,        // Operand B
    input  wire [3:0] op,       // ALU operation select
    output reg  [7:0] result,   // Result
    output wire       zero,     // Zero flag
    output wire       carry,    // Carry flag
    output wire       negative, // Negative flag (MSB)
    output wire       overflow  // Signed overflow flag
);

    // ALU opcodes
    localparam ALU_ADD  = 4'd0;
    localparam ALU_SUB  = 4'd1;
    localparam ALU_AND  = 4'd2;
    localparam ALU_OR   = 4'd3;
    localparam ALU_XOR  = 4'd4;
    localparam ALU_NOT  = 4'd5;
    localparam ALU_SHL  = 4'd6;  // Shift left logical
    localparam ALU_SHR  = 4'd7;  // Shift right logical
    localparam ALU_INC  = 4'd8;
    localparam ALU_DEC  = 4'd9;
    localparam ALU_CMP  = 4'd10; // Compare (SUB, discard result)
    localparam ALU_PASS = 4'd11; // Pass A through

    reg [8:0] full;  // 9-bit to capture carry

    always @(*) begin
        full = 9'd0;
        case (op)
            ALU_ADD:  full = {1'b0, a} + {1'b0, b};
            ALU_SUB:  full = {1'b0, a} - {1'b0, b};
            ALU_AND:  full = {1'b0, a & b};
            ALU_OR:   full = {1'b0, a | b};
            ALU_XOR:  full = {1'b0, a ^ b};
            ALU_NOT:  full = {1'b0, ~a};
            ALU_SHL:  full = {a[7], a << 1};
            ALU_SHR:  full = {a[0], a >> 1};
            ALU_INC:  full = {1'b0, a} + 9'd1;
            ALU_DEC:  full = {1'b0, a} - 9'd1;
            ALU_CMP:  full = {1'b0, a} - {1'b0, b};
            ALU_PASS: full = {1'b0, a};
            default:  full = {1'b0, a};
        endcase
        result = full[7:0];
    end

    assign zero     = (full[7:0] == 8'd0);
    assign carry    = full[8];
    assign negative = full[7];
    // Overflow: sign of a and b same, but sign of result differs
    assign overflow = (op == ALU_ADD) ?
                      (~a[7] & ~b[7] &  full[7]) | (a[7] &  b[7] & ~full[7]) :
                      (op == ALU_SUB || op == ALU_CMP) ?
                      (~a[7] &  b[7] &  full[7]) | (a[7] & ~b[7] & ~full[7]) :
                      1'b0;

endmodule
