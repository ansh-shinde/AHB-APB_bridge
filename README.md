AHB-Lite to APB Bridge (Verilog HDL)
Overview

This project implements an AMBA AHB-Lite to APB Bridge in Verilog HDL. The bridge enables communication between an AHB-Lite master and APB peripherals by translating AHB-Lite transactions into APB-compliant transfers.

The design supports both read and write single transfers and handles address decoding, transfer validation, APB control generation, and protocol error reporting.

The bridge is intended for low-speed peripherals such as UARTs, timers, GPIOs, and other APB-based devices.

Note: This implementation supports only single AHB-Lite transfers and does not support burst transactions (INCR, WRAP, or undefined-length bursts).

Features
AMBA AHB-Lite Slave Interface
AMBA APB Master Interface
Single Read Transfers
Single Write Transfers
Address Validation
Transfer Size Validation
Address Alignment Checking
APB Peripheral Selection (4 Slaves)
AHB Response Generation
APB Error Propagation
Pipelined Address/Data Handling
Synthesizable RTL Design
Verified using Verilog Testbench
Supported Transfers
AHB-Lite Transfers
Transfer Type	Supported
IDLE	Yes
BUSY	Yes
NONSEQ	Yes
SEQ	Treated as Single Transfer
Burst Transfers	No
Transfer Sizes
Size	Supported
Byte (8-bit)	Yes
Halfword (16-bit)	Yes
Word (32-bit)	Yes

The bridge performs alignment checks according to the transfer size:

Byte → Any address
Halfword → Address[0] = 0
Word → Address[1:0] = 00

Invalid alignments generate an AHB error response.

Architecture
                 AHB-Lite Master
                        |
                        |
                +-------+-------+
                |               |
                |  AHB-APB      |
                |   Bridge      |
                |               |
                +-------+-------+
                        |
                APB Master Bus
                        |
       +--------+--------+--------+--------+
       |        |        |        |        |
     PSEL0    PSEL1    PSEL2    PSEL3   ...

The bridge is divided into two major blocks:

Control Path

Responsible for:

AHB/APB protocol conversion
State machine control
APB setup and access phase generation
HREADY generation
HRESP generation
PWRITE generation
Error handling
Data Path

Responsible for:

Address pipelining
Data pipelining
Transfer validation
Address decoding
APB peripheral selection
Read data return path
AHB-Lite Interface
Inputs
Signal	Description
HCLK	System Clock
HRESET	Reset
HSELB	Bridge Select
HWRITE	Read/Write Control
HTRANS	Transfer Type
HSIZE	Transfer Size
HADDR	Address
HWDATA	Write Data
Outputs
Signal	Description
HREADY	Transfer Completion
HRESP	Error Response
HRDATA	Read Data
APB Interface
Outputs
Signal	Description
PSEL0-PSEL3	Peripheral Select
PENABLE	APB Enable
PWRITE	APB Read/Write
PADDR	APB Address
PWDATA	APB Write Data
Inputs
Signal	Description
PRDATA	APB Read Data
PREADY	APB Ready
PSLVERR	APB Error Response
Address Map

The bridge supports four APB peripherals using address decoding based on address bits [6:5].

Address Range	Selected Peripheral
0x00 – 0x1F	PSEL0
0x20 – 0x3F	PSEL1
0x40 – 0x5F	PSEL2
0x60 – 0x7F	PSEL3

Addresses outside this range are considered invalid.

Error Handling

The bridge generates HRESP = 1 under the following conditions:

Invalid Address

Address outside:

0x00 – 0x7C
Invalid Transfer Alignment

Examples:

Halfword @ 0x01
Word     @ 0x02
APB Slave Error

When:

PSLVERR = 1

from the selected APB peripheral.

Finite State Machine

The control path uses a 5-state FSM:

State	Function
IDLE	Wait for valid transfer
SETUP_W	APB Write Setup
SETUP_R	APB Read Setup
ACCESS	APB Access Phase
ERROR	Error Response
Limitations

Current implementation does not support:

AHB Burst Transfers
SINGLE ✔
INCR ✘
WRAP4 ✘
WRAP8 ✘
WRAP16 ✘
INCR4 ✘
INCR8 ✘
INCR16 ✘
APB4 Features
Multiple Outstanding Transactions
Split/Retry Responses
DMA Support

The bridge processes one AHB transaction at a time and waits for APB completion before accepting the next transaction.

Verification

The bridge has been verified using Verilog testbenches covering:

Single Write Transfers
Single Read Transfers
Address Decoding
Invalid Address Detection
Transfer Size Validation
Alignment Checking
APB Wait-State Handling
APB Error Handling
HREADY Generation
HRESP Generation
Tools Used
Verilog HDL
Icarus Verilog
GTKWave
Simulation
Compile
iverilog -g2012 -o simv tb/*.v bridge/*.v
Run
vvp simv
View Waveforms
gtkwave *.vcd
Author

Ansh Shinde

Project Type: AMBA Bus Architecture / RTL Design / Digital Design Verification
