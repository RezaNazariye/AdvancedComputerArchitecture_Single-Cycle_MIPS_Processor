# Single-Cycle MIPS Processor (ACA-MIPS)

## Overview
This project involves the design and implementation of the core datapath and control logic for a 32-bit **Single-Cycle MIPS** processor. The processor supports a subset of the ACA-MIPS instruction set architecture (ISA), including arithmetic, logical, memory access, and branch instructions.

*Note: The memory modules, Register File, ALU, and testbenches were provided as part of the course scaffolding. The author's primary contribution was the structural design of the top-level datapath and the implementation of the fully combinational Control Unit.*

**Course:** Advanced Computer Architecture  
**Institution:** Sharif University of Technology  
**Instructor:** Dr. Movahedin

## Architecture & Supported Instructions
The processor features a standard MIPS datapath consisting of an ALU, Register File, Control Unit, Instruction/Data Memories, and a Program Counter.

![MIPS Datapath](images/mips_datapath.png)
*Figure 1: Single-Cycle MIPS Datapath Architecture.*

**Supported Instructions:**
The processor decodes and executes the following instructions:
| Format | Instructions |
| :--- | :--- |
| **R-Type** | `add`, `sub`, `addu`, `subu`, `and`, `or`, `xor`, `nor`, `slt`, `sltu` |
| **I-Type** | `addi`, `addiu`, `slti`, `sltiu`, `andi`, `ori`, `xori`, `lui`, `beq`, `bne`, `lw`, `sw` |
| **J-Type** | `j` (Jump) |

## Verification & Testing
The processor was rigorously verified using two distinct ModelSim testbenches. these tests were provided by the course:

### 1. Basic Test (`tb_basic.v`)
Tests individual instructions and data hazards. 
### 2. Insertion Sort Test (`tb_isort.v`)
A comprehensive program that generates an array of 32-bit numbers, sorts them using an insertion sort algorithm, and stores them back in memory. 
*   **Verification Mechanism:** The testbench checks two conditions: (1) if the array is actually sorted (`err_unsorted`), and (2) if the sorted numbers match the golden reference `exp_sorted_numbers.hex` (`err_exp`).

### Results
*   **Basic Test:** All expected values were printed to the memory dump.
*   **isort Test:** The processor successfully executed the sorting algorithm. The simulation log printed `PASS1, All Sorted!` and `Pass2, Output Matches the expected Numbers!`, and finished well within the time constraint.

![Basic Simulation Results](images/basic_result.png)

![isort Simulation Results](images/isort_result.png)
*Figure 3: ModelSim console showing successful insertion sort execution within the time constraint.*
