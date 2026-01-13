# UART-16550 RTL Design

This project implements a UART-16550 compatible core in SystemVerilog. The design includes a transmitter, receiver, register file, baud rate generator, and FIFO buffers for both TX and RX paths.

The UART supports configurable word length, parity modes, stop bits, FIFO enable and thresholds, and standard UART status and control registers. The RTL is organized into modular blocks for clarity, reuse, and easy integration into larger SoC designs.

A basic directed testbench is included to configure the UART registers, program the baud rate divisor, transmit data, and observe serialized output behavior.
## Repository Structure

- `rtl/` – SystemVerilog RTL implementation of the UART core
- `tb/`  – Basic directed testbench for UART bring-up and transmit verification
