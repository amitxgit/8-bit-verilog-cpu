// ============================================================
//  8 × 8-bit Register File
//  Two async read ports, one sync write port
// ============================================================
module register_file (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  rd_addr1,  // Read address port 1
    input  wire [2:0]  rd_addr2,  // Read address port 2
    input  wire [2:0]  wr_addr,   // Write address
    input  wire [7:0]  wr_data,   // Write data
    input  wire        wr_en,     // Write enable
    output wire [7:0]  rd_data1,  // Read data port 1
    output wire [7:0]  rd_data2   // Read data port 2
);

    reg [7:0] regs [0:7];
    integer i;

    // Synchronous write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 8'd0;
        end else if (wr_en) begin
            regs[wr_addr] <= wr_data;
        end
    end

    // Asynchronous read (combinational)
    assign rd_data1 = regs[rd_addr1];
    assign rd_data2 = regs[rd_addr2];

endmodule
