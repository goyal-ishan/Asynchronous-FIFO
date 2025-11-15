# Dual-Clock Asynchronous FIFO

A CDC-safe asynchronous FIFO using Gray-coded read/write pointers and two-flop synchronizers.

## Features
- Independent write and read clock domains
- 8-bit data width
- 8-entry FIFO depth
- Gray-coded pointer crossing
- Two-flop synchronizers in both directions
- Full detection in the write domain
- Empty detection in the read domain
- Registered read data
- Verification with mismatched clocks: `wr_clk = 10 ns`, `rd_clk = 14 ns`

The architecture follows the standard asynchronous FIFO pattern: only Gray-coded pointers cross clock domains, while the memory is accessed locally by each domain. This avoids sampling a multi-bit binary counter directly across an asynchronous boundary.

## Architecture

```text
                 WRITE DOMAIN                    READ DOMAIN

 wr_clk                                      rd_clk
   |                                           |
   v                                           v
+--------+    Gray ptr     +----------+    +--------+
| Write  | ---------------->| 2-FF     |    | Read   |
| Pointer|                  | Sync     |    | Pointer|
+--------+                  +----------+    +--------+
    |                                             |
    | write                                  read |
    v                                             v
             +-----------------------------+
             |      FIFO memory             |
             |        8 x 8                 |
             +-----------------------------+

        Read pointer Gray code is synchronized back
        into the write clock domain for FULL logic.
```

## Full / Empty Logic

For a power-of-two asynchronous FIFO, an extra pointer bit distinguishes wrap-around. The write-side full comparison inverts the two most significant bits of the synchronized read Gray pointer; the read-side empty comparison occurs when the Gray pointers are equal. This is the conventional Gray-pointer FIFO technique.

## Clock-Domain Crossing

The testbench deliberately uses different clock periods:

- Write clock: 10 ns
- Read clock: 14 ns

This creates changing phase relationships rather than assuming a shared clock.

## Files

```text
dual_clock_async_fifo/
├── README.md
├── rtl/
│   └── async_fifo.v
└── tb/
    └── tb_async_fifo.v
```

## Simulation

With Icarus Verilog:

```bash
iverilog -g2012 -o fifo_sim rtl/async_fifo.v tb/tb_async_fifo.v
vvp fifo_sim
```

With Vivado, add `rtl/async_fifo.v` as a design source and `tb/tb_async_fifo.v` as a simulation source.

## Important Design Notes

- FIFO depth must be a power of two for this Gray-pointer full detection scheme.
- The synchronizers are intentionally simple two-flop chains.
- In an ASIC flow, CDC constraints and synchronizer-cell attributes should be added according to the target library/flow.
- In an FPGA flow, constrain the independent clocks and verify the inferred memory implementation.

## Resume claim supported by this repository

> Engineered a dual-clock asynchronous FIFO using Gray-code pointers and two-flop synchronizers for safe CDC; verified operation under mismatched 10 ns write and 14 ns read clock periods.
