// ============================================================
//  8-bit CPU — Top-Level Module
//
//  Pipeline: FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK
//
//  Instruction set:
//    NOP, LOADI, ADD, SUB, AND, OR, XOR, NOT
//    LOAD, STORE, CMP, MOV
//    JMP, BEQ, BNE, BCS, HALT
// ============================================================
`include "cpu8_defs.vh"

module cpu8 (
    input  wire        clk,
    input  wire        rst,
    // Debug/observation ports
    output wire [7:0]  dbg_pc,
    output wire [7:0]  dbg_acc,
    output wire [3:0]  dbg_flags,   // {overflow, negative, carry, zero}
    output wire [2:0]  dbg_state,
    output wire        halted
);

    // ----------------------------------------------------------
    //  Internal signals
    // ----------------------------------------------------------
    reg  [7:0]  pc;          // Program counter
    reg  [7:0]  ir0, ir1;    // Instruction register (2 bytes)
    reg  [2:0]  state;       // FSM state
    reg         halt_flag;

    // Decoded fields
    wire [3:0]  opcode  = ir0[7:4];
    wire [2:0]  rd_f    = ir0[3:1];  // Destination register field
    wire [2:0]  rs1_f   = ir1[7:5];  // Source register 1
    wire [2:0]  rs2_f   = ir1[4:2];  // Source register 2

    // Register file wires
    reg  [2:0]  rf_rd1, rf_rd2, rf_wr;
    reg  [7:0]  rf_wdata;
    reg         rf_wen;
    wire [7:0]  rf_rdata1, rf_rdata2;

    // ALU wires
    reg  [3:0]  alu_op;
    wire [7:0]  alu_result;
    wire        alu_zero, alu_carry, alu_neg, alu_ov;

    // Flags register
    reg         flag_z, flag_c, flag_n, flag_v;

    // Memory wires
    reg  [7:0]  mem_addr;
    reg  [7:0]  mem_wdata;
    reg         mem_wen;
    wire [7:0]  mem_rdata;

    // Instruction memory wire
    wire [7:0]  imem_data;

    // Temporary registers for multi-cycle ops
    reg  [7:0]  alu_result_r;

    // ----------------------------------------------------------
    //  Sub-modules
    // ----------------------------------------------------------
    register_file rf (
        .clk      (clk),
        .rst      (rst),
        .rd_addr1 (rf_rd1),
        .rd_addr2 (rf_rd2),
        .wr_addr  (rf_wr),
        .wr_data  (rf_wdata),
        .wr_en    (rf_wen),
        .rd_data1 (rf_rdata1),
        .rd_data2 (rf_rdata2)
    );

    alu alu0 (
        .a        (rf_rdata1),
        .b        (rf_rdata2),
        .op       (alu_op),
        .result   (alu_result),
        .zero     (alu_zero),
        .carry    (alu_carry),
        .negative (alu_neg),
        .overflow (alu_ov)
    );

    instr_mem imem (
        .addr (pc),
        .data (imem_data)
    );

    data_mem dmem (
        .clk     (clk),
        .wr_en   (mem_wen),
        .addr    (mem_addr),
        .wr_data (mem_wdata),
        .rd_data (mem_rdata)
    );

    // ----------------------------------------------------------
    //  Debug outputs
    // ----------------------------------------------------------
    assign dbg_pc    = pc;
    assign dbg_acc   = rf_rdata1;   // Shows R0
    assign dbg_flags = {flag_v, flag_n, flag_c, flag_z};
    assign dbg_state = state;
    assign halted    = halt_flag;

    // ----------------------------------------------------------
    //  Default combinational register-file read addresses
    // ----------------------------------------------------------
    always @(*) begin
        rf_rd1 = rs1_f;
        rf_rd2 = rs2_f;
    end

    // ----------------------------------------------------------
    //  FSM
    // ----------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc           <= 8'd0;
            ir0          <= 8'd0;
            ir1          <= 8'd0;
            state        <= `ST_FETCH;
            halt_flag    <= 1'b0;
            flag_z       <= 1'b0;
            flag_c       <= 1'b0;
            flag_n       <= 1'b0;
            flag_v       <= 1'b0;
            rf_wen       <= 1'b0;
            mem_wen      <= 1'b0;
            alu_op       <= 4'd0;
            alu_result_r <= 8'd0;
        end else begin

            // Default de-assert strobes every cycle
            rf_wen  <= 1'b0;
            mem_wen <= 1'b0;

            case (state)

                // ==================================================
                //  FETCH — load byte 0 of instruction
                // ==================================================
                `ST_FETCH: begin
                    if (!halt_flag) begin
                        ir0   <= imem_data;
                        pc    <= pc + 8'd1;
                        state <= `ST_DECODE;
                    end
                end

                // ==================================================
                //  DECODE — load byte 1 (or 0 for 1-byte instrs)
                //           set up ALU inputs
                // ==================================================
                `ST_DECODE: begin
                    ir1   <= imem_data;   // always read; may be unused
                    pc    <= pc + 8'd1;
                    state <= `ST_EXECUTE;
                end

                // ==================================================
                //  EXECUTE — ALU / branch / jump decisions
                // ==================================================
                `ST_EXECUTE: begin
                    case (opcode)

                        `OP_NOP: begin
                            // Undo spurious PC increment from DECODE
                            // NOP is 1-byte; byte1 was fetched but unused
                            pc    <= pc - 8'd1;
                            state <= `ST_FETCH;
                        end

                        `OP_LOADI: begin
                            // Rd = ir1 (immediate)
                            rf_wr    <= rd_f;
                            rf_wdata <= ir1;
                            rf_wen   <= 1'b1;
                            state    <= `ST_FETCH;
                        end

                        `OP_ADD: begin
                            alu_op       <= `ALUF_ADD;
                            alu_result_r <= alu_result;
                            state        <= `ST_WRITEBACK;
                        end

                        `OP_SUB: begin
                            alu_op       <= `ALUF_SUB;
                            alu_result_r <= alu_result;
                            state        <= `ST_WRITEBACK;
                        end

                        // OP_LOAD / OP_STORE share opcode 4'h4
                        // Distinguished by rd_f: 0 = STORE, else LOAD
                        4'h4: begin
                            if (rd_f == 3'd0) begin
                                // STORE: mem[ir1] = Rrs1
                                mem_addr  <= ir1;
                                mem_wdata <= rf_rdata1;
                                mem_wen   <= 1'b1;
                                state     <= `ST_FETCH;
                            end else begin
                                // LOAD: Rd = mem[ir1]
                                mem_addr  <= ir1;
                                mem_wen   <= 1'b0;
                                state     <= `ST_MEMORY;
                            end
                        end

                        `OP_AND: begin
                            alu_op       <= `ALUF_AND;
                            alu_result_r <= alu_result;
                            state        <= `ST_WRITEBACK;
                        end

                        `OP_OR: begin
                            alu_op       <= `ALUF_OR;
                            alu_result_r <= alu_result;
                            state        <= `ST_WRITEBACK;
                        end

                        `OP_XOR: begin
                            alu_op       <= `ALUF_XOR;
                            alu_result_r <= alu_result;
                            state        <= `ST_WRITEBACK;
                        end

                        `OP_NOT: begin
                            alu_op       <= `ALUF_NOT;
                            alu_result_r <= alu_result;
                            state        <= `ST_WRITEBACK;
                        end

                        `OP_CMP: begin
                            // Compare: update flags only, no writeback
                            alu_op  <= `ALUF_CMP;
                            flag_z  <= alu_zero;
                            flag_c  <= alu_carry;
                            flag_n  <= alu_neg;
                            flag_v  <= alu_ov;
                            pc      <= pc - 8'd1; // 2-byte instr, already consumed both
                            state   <= `ST_FETCH;
                        end

                        `OP_JMP: begin
                            pc    <= ir1;
                            state <= `ST_FETCH;
                        end

                        `OP_BEQ: begin
                            pc    <= flag_z ? ir1 : pc;
                            state <= `ST_FETCH;
                        end

                        `OP_BNE: begin
                            pc    <= (!flag_z) ? ir1 : pc;
                            state <= `ST_FETCH;
                        end

                        `OP_BCS: begin
                            pc    <= flag_c ? ir1 : pc;
                            state <= `ST_FETCH;
                        end

                        `OP_MOV: begin
                            // Rd = Rs1  (alu pass-through)
                            alu_op       <= `ALUF_PASS;
                            alu_result_r <= rf_rdata1;
                            state        <= `ST_WRITEBACK;
                        end

                        `OP_HALT: begin
                            halt_flag <= 1'b1;
                            state     <= `ST_HALT;
                        end

                        default: state <= `ST_FETCH;
                    endcase
                end

                // ==================================================
                //  MEMORY — wait for data memory read
                // ==================================================
                `ST_MEMORY: begin
                    // mem_rdata is valid this cycle (synchronous RAM
                    // latches on the previous clock edge)
                    alu_result_r <= mem_rdata;
                    state        <= `ST_WRITEBACK;
                end

                // ==================================================
                //  WRITEBACK — write result to register file
                // ==================================================
                `ST_WRITEBACK: begin
                    rf_wr    <= rd_f;
                    rf_wdata <= alu_result_r;
                    rf_wen   <= 1'b1;
                    // Latch flags for ALU results
                    flag_z   <= alu_zero;
                    flag_c   <= alu_carry;
                    flag_n   <= alu_neg;
                    flag_v   <= alu_ov;
                    state    <= `ST_FETCH;
                end

                `ST_HALT: begin
                    // Stay here until reset
                    state <= `ST_HALT;
                end

                default: state <= `ST_FETCH;
            endcase
        end
    end

    // ----------------------------------------------------------
    //  ALU always uses current register file outputs
    //  (alu_op is registered, so result is valid next cycle)
    // ----------------------------------------------------------
    always @(*) begin
        case (opcode)
            `OP_ADD:  alu_op = `ALUF_ADD;
            `OP_SUB:  alu_op = `ALUF_SUB;
            `OP_AND:  alu_op = `ALUF_AND;
            `OP_OR:   alu_op = `ALUF_OR;
            `OP_XOR:  alu_op = `ALUF_XOR;
            `OP_NOT:  alu_op = `ALUF_NOT;
            `OP_CMP:  alu_op = `ALUF_CMP;
            `OP_MOV:  alu_op = `ALUF_PASS;
            default:  alu_op = `ALUF_PASS;
        endcase
    end

endmodule
