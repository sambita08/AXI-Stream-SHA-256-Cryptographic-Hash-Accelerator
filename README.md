# AXI-Stream-SHA-256-Cryptographic-Hash-Accelerator

# SHA-256 Hardware Accelerator — Verilog RTL

A fully pipelined, synthesisable SHA-256 hardware core implemented in Verilog-2001, compliant with **FIPS 180-4**. Designed for FPGA/ASIC deployment with an AXI4-Stream inspired byte-streaming interface.

---

## Features

- **Full SHA-256 pipeline** — input buffering → message schedule → 64-round compression → 256-bit digest
- **Hardware-managed padding** — automatic 0x80 append, zero-fill, and 64-bit big-endian length field via FSM
- **16-word sliding window** message schedule — 75% register reduction over naive 64-word implementation
- **AXI4-Stream interface** — `tvalid/tready/tlast/tid` handshake with full back-pressure support
- **32-bit message ID tag** — propagates through pipeline for multi-message in-flight tracking
- **Davies-Meyer addback** — implemented via `hsave/hadder` registers for correct one-way compression

---

## Module Structure

```
sha256.v          ← Top-level RTL core
tb_sha.v          ← Self-checking testbench
test_data/
  test1.bin       ← Empty file
  test2.bin       ← "a"
  test3.bin       ← "abc"  (NIST standard test vector)
  test4.bin       ← "hello world"
 
```

---

## Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | Input | 1 | System clock (100 MHz) |
| `rstn` | Input | 1 | Active-low reset |
| `tvalid` | Input | 1 | Input byte valid |
| `tready` | Output | 1 | Module ready to accept |
| `tlast` | Input | 1 | Last byte of message |
| `tid` | Input | 32 | Message ID tag |
| `tdata` | Input | 8 | Input data byte |
| `ovalid` | Output | 1 | Hash output valid |
| `oid` | Output | 32 | Message ID of completed hash |
| `olen` | Output | 61 | Original message length (bytes) |
| `osha` | Output | 256 | SHA-256 digest |

---

## Simulation — Vivado

**1. Create test files** — in Vivado Tcl Console (before running simulation):
```tcl
set simdir "D:/YOUR_PROJECT_PATH/SHA_256.sim/sim_1/behav/xsim"
file mkdir "$simdir/test_data"

set fp [open "$simdir/test_data/test1.bin" wb]; close $fp
set fp [open "$simdir/test_data/test2.bin" wb]; puts -nonewline $fp "a";           close $fp
set fp [open "$simdir/test_data/test3.bin" wb]; puts -nonewline $fp "abc";         close $fp
set fp [open "$simdir/test_data/test4.bin" wb]; puts -nonewline $fp "hello world"; close $fp

```

**2. Run simulation:**
```tcl
run 500000ns
```

**3. Check Tcl Console for output:**
```
id=00000111   len=     0   sha256=e3b0c44298fc1c149afbf4c8996fb924...
id=00000222   len=     1   sha256=ca978112ca1bbdcafac231b39a23dc4d...
id=00000333   len=     3   sha256=ba7816bf8f01cfea414140de5dae2ec7...
```

---


## Simulation Output

<!-- Add your Vivado simulation screenshot here -->
  <img width="1590" height="754" alt="sha256" src="https://github.com/user-attachments/assets/63fcbfcc-ec9a-471a-aaf2-999160b2d7bd" />



---

## Tools

| Tool | Version |
|------|---------|
| Xilinx Vivado | 2023.1 |
| Language | Verilog-2001 |
| Simulator | XSim (Behavioral) |
| Target | FPGA / ASIC (synthesisable RTL) |

---

## References

- FIPS 180-4 — Secure Hash Standard, NIST
- SHA-256 Algorithm Specification, Section 6.2.2
