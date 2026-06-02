# 8-Bit CPU in Verilog
### Synthesizable on Xilinx Vivado (Artix-7 / Basys3 / Nexys)

---

## File Overview

| File | Description |
|------|-------------|
| `cpu8_defs.vh`     | Shared constants — opcodes, ALU codes, state IDs |
| `alu.v`            | 8-bit ALU (ADD, SUB, AND, OR, XOR, NOT, SHL, SHR, INC, DEC, CMP) |
| `register_file.v`  | 8 × 8-bit register file (2 read ports, 1 write port) |
| `memory.v`         | 256×8 instruction ROM + 256×8 data RAM |
| `cpu8.v`           | Top-level CPU with 5-stage FSM control unit |
| `cpu8_tb.v`        | Simulation testbench |
| `cpu8.xdc`         | Pin constraints for Basys3 board |
| `create_project.tcl` | Vivado Tcl script to auto-build the project |

---

## Architecture

```
                ┌─────────────────────────────────────────┐
                │              8-bit CPU                  │
  clk/rst ──►  │                                         │
                │  PC ──► InstrMem                        │
                │           │ IR                          │
                │           ▼                             │
                │       Control Unit ──► state machine    │
                │           │                             │
                │           ▼                             │
                │      Register File (R0–R7)              │
                │       │         │                       │
                │      rs1       rs2                      │
                │       └────┬───┘                        │
                │            ▼                            │
                │           ALU ──► Flags (Z C N V)       │
                │            │                            │
                │            ▼                            │
                │        Data Memory (RAM)                │
                │                                         │
                └─────────────────────────────────────────┘
```

### Pipeline stages (FSM)

| State | Action |
|-------|--------|
| FETCH | Load instruction byte 0, increment PC |
| DECODE | Load instruction byte 1, set up register reads |
| EXECUTE | ALU operation / branch / jump / immediate write |
| MEMORY | Wait for RAM read latency (LOAD only) |
| WRITEBACK | Write ALU/memory result to register file |

---

## Instruction Set

All instructions are **2 bytes** except NOP and HALT (1 byte effectively, second byte discarded).

### Byte 0 encoding
```
  [7:4] opcode
  [3:1] Rd  (destination register R0–R7)
  [0]   reserved
```

### Byte 1 encoding
```
  For register ops:  [7:5] Rs1,  [4:2] Rs2,  [1:0] unused
  For immediates:    [7:0] imm8
  For addresses:     [7:0] addr8
  For branches:      [7:0] target PC
```

### Opcode table

| Opcode (4-bit) | Mnemonic | Operation |
|----------------|----------|-----------|
| `0x0` | NOP           | No operation |
| `0x1` | LOADI Rd, #n  | Rd = n |
| `0x2` | ADD Rd, Rs1, Rs2 | Rd = Rs1 + Rs2; flags |
| `0x3` | SUB Rd, Rs1, Rs2 | Rd = Rs1 – Rs2; flags |
| `0x4` (rd≠0) | LOAD Rd, addr | Rd = mem[addr] |
| `0x4` (rd=0) | STORE Rs, addr | mem[addr] = Rs1 |
| `0x5` | AND Rd, Rs1, Rs2 | Rd = Rs1 & Rs2 |
| `0x6` | OR  Rd, Rs1, Rs2 | Rd = Rs1 \| Rs2 |
| `0x7` | XOR Rd, Rs1, Rs2 | Rd = Rs1 ^ Rs2 |
| `0x8` | NOT Rd, Rs1      | Rd = ~Rs1 |
| `0x9` | CMP Rs1, Rs2      | flags = Rs1 – Rs2 (no writeback) |
| `0xA` | JMP addr          | PC = addr |
| `0xB` | BEQ addr          | if Z: PC = addr |
| `0xC` | BNE addr          | if !Z: PC = addr |
| `0xD` | BCS addr          | if C: PC = addr |
| `0xE` | MOV Rd, Rs1       | Rd = Rs1 |
| `0xF` | HALT              | Stop execution |

### Flags
| Flag | Name | Set when |
|------|------|----------|
| Z | Zero | Result == 0 |
| C | Carry | Unsigned overflow |
| N | Negative | Result bit 7 == 1 |
| V | Overflow | Signed overflow |

---

## How to Use in Vivado

### Option A — Tcl script (fastest)
1. Open Vivado → Tcl Console
2. `cd` to the folder containing these files
3. `source create_project.tcl`
4. Project opens automatically

### Option B — Manual
1. **File > Project > New**
2. Add all `.v` files as Design Sources
3. Add `cpu8_tb.v` as Simulation Source
4. Add `cpu8.xdc` as Constraint
5. In each fileset, set **Include Paths** to the project root (so `cpu8_defs.vh` is found)
6. Set top module to `cpu8`

### Simulation
- **Flow > Run Simulation > Run Behavioral Simulation**
- The testbench runs the demo program and prints a cycle log
- VCD is also dumped for GTKWave

### Synthesis & Implementation
- **Flow > Run Implementation**
- **Flow > Generate Bitstream**
- Program with **Flow > Open Hardware Manager**

---

## Writing Your Own Programs

Edit the `initial begin` block inside `instr_mem` in `memory.v`.

**Example — count from 0 to 9:**
```verilog
rom[0]  = 8'h15;  rom[1]  = 8'd0;   // LOADI R5, 0   (counter)
rom[2]  = 8'h13;  rom[3]  = 8'd1;   // LOADI R3, 1   (step)
rom[4]  = 8'h14;  rom[5]  = 8'd10;  // LOADI R4, 10  (limit)
// loop:
rom[6]  = 8'h25;  rom[7]  = 8'h1C;  // ADD R5, R5, R3
rom[8]  = 8'h90;  rom[9]  = 8'hA4;  // CMP R5, R4  (rs1=5=101, rs2=4=100 → 101_100_00=0xB0)
rom[10] = 8'hC0;  rom[11] = 8'd6;   // BNE loop (PC=6)
rom[12] = 8'hFF;                     // HALT
```

**Register encoding in byte 1 (for 3-reg instructions):**
```
byte1 = { rs1[2:0], rs2[2:0], 2'b00 }
```
So rs1=R0(000), rs2=R1(001) → byte1 = `000_001_00` = `0x04`

---

## Board Support

| Board | Part Number | Change in `create_project.tcl` |
|-------|-------------|-------------------------------|
| Basys3 | xc7a35tcpg236-1 | default |
| Nexys A7-50T | xc7a50tcsg324-1 | set part accordingly |
| Arty A7-35 | xc7a35ticsg324-1L | also update XDC pins |

---

## Extending the CPU

Some ideas to build on this foundation:

- Add a **stack pointer** (R7 as SP) and `PUSH`/`POP` instructions
- Add **shift-by-register** (`SHL Rd, Rs1, Rs2`)
- Add a **multiply instruction** (8×8 → 16-bit result in two registers)
- Implement a proper **pipeline** (IF/ID/EX/MEM/WB with hazard detection)
- Add **interrupt handling** with a saved PC register
- Connect to **7-segment display** via an output port register
