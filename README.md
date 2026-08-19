# AHB-Lite to APB Bridge

## Overview

This project implements an **AHB-Lite to APB Bridge** in Verilog HDL. The bridge enables communication between an **AHB-Lite master** and multiple **APB peripherals** by translating AHB-Lite transactions into APB-compliant transfers.

The design supports both **read and write transactions**, performs **address decoding**, validates transfer size and address alignment, generates APB control signals, and handles APB wait states and error responses.

> **Note:** This implementation supports only **single AHB-Lite transfers** and does **not support burst transactions (INCR, WRAP, INCR4/8/16, WRAP4/8/16)**.

---

## Features

- AHB-Lite Slave Interface
- APB Master Interface
- Single Read Transactions
- Single Write Transactions
- Address Decoding for Multiple APB Slaves
- Address Range Validation
- Transfer Size Validation
- Address Alignment Checking
- APB Wait-State Handling using PREADY
- APB Error Handling using PSLVERR
- Pipelined Address/Data Capture
- Synthesizable RTL Design
- Verified using Verilog Testbench

---

## Architecture

```
                +------------------+
                |   AHB-Lite       |
                |     Master       |
                +--------+---------+
                         |
                         |
                 AHB-Lite Bus
                         |
        +-------------------------------+
        |       AHB-Lite to APB         |
        |            Bridge             |
        |                               |
        |  +-------------------------+  |
        |  |      Control Path       |  |
        |  +-------------------------+  |
        |                               |
        |  +-------------------------+  |
        |  |       Data Path         |  |
        |  +-------------------------+  |
        +---------------+---------------+
                        |
                      APB Bus
                        |
       +--------+--------+--------+--------+
       |        |        |        |        |
     PSEL0    PSEL1    PSEL2    PSEL3   ...
```

---

## Supported Transfers

### Write Transfer

1. AHB master places address and control information.
2. Bridge validates address and transfer size.
3. Address and data are captured in pipeline registers.
4. APB setup phase is generated.
5. APB access phase is initiated.
6. Transfer completes when `PREADY = 1`.

### Read Transfer

1. AHB master issues read request.
2. Bridge captures address and control signals.
3. APB read transaction is generated.
4. APB peripheral returns data through `PRDATA`.
5. Data is forwarded to `HRDATA`.

---

## AHB-Lite Interface Signals

| Signal | Direction | Description |
|----------|----------|-------------|
| HCLK | Input | AHB Clock |
| HRESET | Input | Reset |
| HSELB | Input | Slave Select |
| HWRITE | Input | Read/Write Control |
| HADDR | Input | Address Bus |
| HWDATA | Input | Write Data |
| HRDATA | Output | Read Data |
| HTRANS | Input | Transfer Type |
| HSIZE | Input | Transfer Size |
| HREADY | Output | Transfer Ready |
| HRESP | Output | Transfer Response |

---

## APB Interface Signals

| Signal | Direction | Description |
|----------|----------|-------------|
| PADDR | Output | APB Address |
| PWDATA | Output | APB Write Data |
| PRDATA | Input | APB Read Data |
| PSEL0-PSEL3 | Output | Peripheral Select |
| PENABLE | Output | APB Enable |
| PWRITE | Output | Read/Write Control |
| PREADY | Input | APB Ready |
| PSLVERR | Input | APB Error Response |

---

## Address Mapping

The bridge supports four APB peripheral regions.

| Address Range | APB Select |
|--------------|------------|
| 0x00 - 0x1F | PSEL0 |
| 0x20 - 0x3F | PSEL1 |
| 0x40 - 0x5F | PSEL2 |
| 0x60 - 0x7F | PSEL3 |

Address decoding is performed using:

```verilog
addr_reg2[6:5]
```

---

## Address Validation

The bridge validates incoming addresses before initiating APB transfers.

Supported address range:

```text
0x00 - 0x7C
```

Invalid addresses generate:

```text
HRESP = 1
```

---

## Transfer Size Validation

Supported transfer sizes:

| HSIZE | Transfer |
|--------|----------|
| 000 | Byte |
| 001 | Halfword |
| 010 | Word |

Unsupported sizes generate an error response.

---

## Alignment Checking

### Byte Access

No alignment restrictions.

### Halfword Access

```text
Address[0] = 0
```

### Word Access

```text
Address[1:0] = 00
```

Misaligned accesses generate:

```text
HRESP = 1
```

---

## Control Path FSM

The bridge control path uses a finite-state machine.

### States

| State | Description |
|---------|------------|
| IDLE | Waiting for valid transfer |
| SETUP_W | APB write setup phase |
| SETUP_R | APB read setup phase |
| ACCESS | APB access phase |
| ERROR | Error response state |

### State Flow

```text
IDLE
  |
  +----> SETUP_W ----+
  |                  |
  |                  v
  +----> SETUP_R --> ACCESS
                        |
                        +--> ERROR
                        |
                        +--> IDLE
```

---

## Wait-State Handling

The bridge remains in the APB ACCESS state until:

```verilog
PREADY = 1
```

This allows APB peripherals to insert wait states when required.

---

## Error Handling

Errors can be generated due to:

### Invalid Address

```text
Address outside supported range
```

### Invalid Transfer Size

```text
Unsupported HSIZE value
```

### Misaligned Access

```text
Halfword/Word alignment violation
```

### APB Slave Error

```text
PSLVERR = 1
```

Error response:

```text
HRESP = 1
```

---

## Pipeline Handling

The bridge captures AHB signals using internal pipeline registers:

```verilog
addr_reg1
addr_reg2
data_reg1
hwrite_reg
```

This ensures correct alignment between:

- Address Phase
- Data Phase
- APB Transfer Generation

---

## Limitations

### Burst Transfers Not Supported

The current implementation does **not support**:

- SINGLE Burst Sequences
- INCR
- WRAP
- INCR4
- INCR8
- INCR16
- WRAP4
- WRAP8
- WRAP16

Only individual non-burst AHB-Lite transactions are supported.

### APB Version

Current implementation targets:

```text
AMBA APB3
```

---

## Verification

The bridge has been verified for:

- Single Write Transfers
- Single Read Transfers
- Address Decoding
- Invalid Address Detection
- Transfer Size Validation
- Alignment Checking
- APB Wait States
- APB Error Responses
- Consecutive Transactions
- Read/Write Switching

---

## Tools Used

- Verilog HDL
- Icarus Verilog
- GTKWave

---

## Simulation

### Compile

```bash
iverilog -g2012 -o simv tb/*.v bridge/*.v
```

### Run

```bash
vvp simv
```

### View Waveforms

```bash
gtkwave waveform.vcd
```

---

## Future Improvements

- Burst Transfer Support
- APB4 Support
- Configurable Address Mapping
- Multiple Outstanding Requests
- UVM-Based Verification
- FIFO-Based Burst Buffering
- Protocol Assertions (SVA)

---

## Author

**Ansh Shinde**
