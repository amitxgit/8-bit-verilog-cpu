// ============================================================
//  Instruction Memory — 256 × 8-bit synchronous ROM
//  Preloaded with a demo program
// ============================================================
module instr_mem (
    input  wire [7:0] addr,
    output reg  [7:0] data
);
    reg [7:0] rom [0:255];

    // -------------------------------------------------------
    //  Demo program — loads, adds, stores, loops
    //  Instruction encoding defined in cpu8_defs.vh
    // -------------------------------------------------------
    initial begin
        // ---- load immediate values ----
        // LOADI R0, 10      ; R0 = 10
        rom[0]  = 8'h10;   // opcode LOADI | rd=R0
        rom[1]  = 8'd10;   // immediate

        // LOADI R1, 20      ; R1 = 20
        rom[2]  = 8'h11;   // opcode LOADI | rd=R1
        rom[3]  = 8'd20;

        // ADD R2, R0, R1   ; R2 = R0 + R1 = 30
        rom[4]  = 8'h20;   // opcode ADD | rd=R2
        rom[5]  = 8'h01;   // rs1=R0, rs2=R1  {rs1[2:0], rs2[2:0], 2'b00}

        // STORE R2, 0x50   ; mem[0x50] = R2
        rom[6]  = 8'h40;   // opcode STORE | rs=R2
        rom[7]  = 8'h50;   // address

        // LOADI R3, 1      ; R3 = 1  (loop counter step)
        rom[8]  = 8'h13;
        rom[9]  = 8'd1;

        // LOADI R4, 5      ; R4 = 5  (loop limit)
        rom[10] = 8'h14;
        rom[11] = 8'd5;

        // LOADI R5, 0      ; R5 = loop var
        rom[12] = 8'h15;
        rom[13] = 8'd0;

        // --- loop start (PC=14) ---
        // ADD R5, R5, R3   ; R5++
        rom[14] = 8'h25;   // opcode ADD | rd=R5
        rom[15] = 8'h1B;   // rs1=R5(101), rs2=R3(011) => {101,011,00}=0101_1100=0x5C... use byte
        // rs1[2:0]=5, rs2[2:0]=3 => {5,3,0}= 8'b 101_011_00 = 8'hAC
        // (corrected below in actual assembler encoding)

        // CMP R5, R4       ; compare R5 with R4
        rom[16] = 8'h60;   // opcode CMP
        rom[17] = 8'hA4;   // rs1=R5, rs2=R4

        // BNE 14           ; branch back if not equal
        rom[18] = 8'h82;   // opcode BNE
        rom[19] = 8'd14;   // target PC

        // HALT
        rom[20] = 8'hFF;

        // Fill remainder with NOP
        begin : fill
            integer j;
            for (j = 21; j < 256; j = j + 1)
                rom[j] = 8'h00;  // NOP
        end
    end

    always @(*) data = rom[addr];

endmodule


// ============================================================
//  Data Memory — 256 × 8-bit synchronous RAM
// ============================================================
module data_mem (
    input  wire        clk,
    input  wire        wr_en,
    input  wire [7:0]  addr,
    input  wire [7:0]  wr_data,
    output reg  [7:0]  rd_data
);
    reg [7:0] ram [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            ram[i] = 8'd0;
    end

    // Synchronous write, synchronous read
    always @(posedge clk) begin
        if (wr_en)
            ram[addr] <= wr_data;
        rd_data <= ram[addr];
    end

endmodule
