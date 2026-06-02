// ============================================================
//  cpu8_defs.vh  —  Shared constants for the 8-bit CPU
// ============================================================

// ------------------------------------------------------------------
//  INSTRUCTION FORMAT
//
//  Every instruction is 1 or 2 bytes wide:
//
//  Byte 0: [ opcode[3:0] | rd[2:0] | 1'b0 ]   (or flag bits)
//  Byte 1: immediate / address / {rs1[2:0], rs2[2:0], 2'b00}
//
//  opcode[3:0] field in high nibble of byte 0:
// ------------------------------------------------------------------

// ---- Instruction opcodes (top nibble of byte 0) ----
`define OP_NOP    4'h0   // No operation
`define OP_LOADI  4'h1   // Load immediate:  Rd = imm8
`define OP_ADD    4'h2   // Add:             Rd = Rs1 + Rs2
`define OP_SUB    4'h3   // Subtract:        Rd = Rs1 - Rs2
`define OP_LOAD   4'h4   // Load from mem:   Rd = mem[addr]  (addr in byte 1, upper nibble=1)
`define OP_STORE  4'h4   // Store to mem:    mem[addr] = Rs  (addr in byte 1, upper nibble=0)
`define OP_AND    4'h5   // Bitwise AND:     Rd = Rs1 & Rs2
`define OP_OR     4'h6   // Bitwise OR:      Rd = Rs1 | Rs2
`define OP_XOR    4'h7   // Bitwise XOR:     Rd = Rs1 ^ Rs2
`define OP_NOT    4'h8   // Bitwise NOT:     Rd = ~Rs1       (1-byte: {8'h8, rd[2:0], 1'b0})
`define OP_CMP    4'h9   // Compare:         flags = Rs1 - Rs2 (result discarded)
`define OP_JMP    4'hA   // Jump:            PC = imm8
`define OP_BEQ    4'hB   // Branch if Zero:  if Z  PC = imm8
`define OP_BNE    4'hC   // Branch if !Zero: if !Z PC = imm8
`define OP_BCS    4'hD   // Branch if Carry: if C  PC = imm8
`define OP_MOV    4'hE   // Move:            Rd = Rs
`define OP_HALT   4'hF   // Halt execution

// ---- ALU function codes (passed to alu.v) ----
`define ALUF_ADD  4'd0
`define ALUF_SUB  4'd1
`define ALUF_AND  4'd2
`define ALUF_OR   4'd3
`define ALUF_XOR  4'd4
`define ALUF_NOT  4'd5
`define ALUF_SHL  4'd6
`define ALUF_SHR  4'd7
`define ALUF_INC  4'd8
`define ALUF_DEC  4'd9
`define ALUF_CMP  4'd10
`define ALUF_PASS 4'd11

// ---- CPU states ----
`define ST_FETCH   3'd0
`define ST_DECODE  3'd1
`define ST_EXECUTE 3'd2
`define ST_MEMORY  3'd3
`define ST_WRITEBACK 3'd4
`define ST_HALT    3'd5
