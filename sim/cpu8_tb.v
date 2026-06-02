// ============================================================
//  Testbench for 8-bit CPU
//  Run in Vivado Simulator (xsim) or any Verilog simulator
// ============================================================
`timescale 1ns / 1ps

module cpu8_tb;

    reg  clk, rst;

    wire [7:0] dbg_pc;
    wire [7:0] dbg_acc;
    wire [3:0] dbg_flags;
    wire [2:0] dbg_state;
    wire       halted;

    // Instantiate CPU
    cpu8 uut (
        .clk       (clk),
        .rst       (rst),
        .dbg_pc    (dbg_pc),
        .dbg_acc   (dbg_acc),
        .dbg_flags (dbg_flags),
        .dbg_state (dbg_state),
        .halted    (halted)
    );

    // 100 MHz clock (10 ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // State name function
    function [63:0] state_name;
        input [2:0] s;
        case (s)
            3'd0: state_name = "FETCH   ";
            3'd1: state_name = "DECODE  ";
            3'd2: state_name = "EXECUTE ";
            3'd3: state_name = "MEMORY  ";
            3'd4: state_name = "WRITEBCK";
            3'd5: state_name = "HALT    ";
            default: state_name = "UNKNOWN ";
        endcase
    endfunction

    // Simulation
    integer cycle;
    initial begin
        $display("=== 8-bit CPU Simulation Start ===");
        $display("Time | Cycle | State    | PC  | Flags(VNCZ) | Halted");
        $display("---------------------------------------------------------");

        rst   = 1;
        cycle = 0;
        #20;
        rst = 0;

        // Run until halted or timeout
        repeat (500) begin
            @(posedge clk);
            cycle = cycle + 1;
            $display("%4t |  %4d | %s | %3d | %4b        | %b",
                $time, cycle,
                state_name(dbg_state),
                dbg_pc,
                dbg_flags,
                halted);
            if (halted) begin
                $display("--- CPU halted at cycle %0d ---", cycle);
                $finish;
            end
        end

        $display("--- Simulation timeout ---");
        $finish;
    end

    // VCD waveform dump (open in GTKWave)
    initial begin
        $dumpfile("cpu8_sim.vcd");
        $dumpvars(0, cpu8_tb);
    end

endmodule
