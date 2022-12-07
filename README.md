# Complete-pipelined-RISC-V-CPU-core-
### This is a project I was able to develop while taking a course from Linux Foundation on Building a RISC-V CPU Core (LFD111x). It implements a complete RISC-V CPU core. I am using Transaction-Level Verilog (TLV) language extension, to perform instruction-level parallelism, by dividing incoming instructions into a series of sequential steps (the eponymous "pipeline"). This arrangement lets the CPU complete an instruction on each clock cycle. Using the Makerchip online integrated development environment (IDE), an open source tool that can easily be accessed by anyone. It is also an evolving platform.

## About Makerchip IDE
Although you can edit your code live on web browser in the Makerhcip IDE, you can also launch Makerchip from your desktop to work with a local TL-Verilog source file. Makerchip will run in your browser, but autosaves back to your desktop. You can install the Makerchip app first:
```
pip3 install makerchip-app
```
Then launch the makerchip app at a path where you store your local TL-Verilog source file:
```
makerchip <path>/<local_TL_file>.tlv
```

 Makerchip provides random stimulus for dangling inputs, making it a really convenient tool to use, as there is no need to write a test bench to provide stimulus (input) to your design. When opening any available example of the platform, one can play and get familiar real quick with it. It consists of an editor pane, where you can edit your own circuit, everything is written in (\TLV code blocks in this design) a NAV-TLV pane where TLV macros are expanded and a log outputs tab, where one can track for errors or warnings. Compilation and simulation happen at the same time, resulting in a logic diagramm of the circuit designed, while also providing with the output waveforms tab. VIZ tab could be used to further simplify debug for large designs.

Typically, you would create your own custom visualizations as you develop your circuit, so you can see the big picture simulation behavior more easily. However, thanks to the course benefits, this was provided for me. You can see the visualization code in the NAV-TLV pane, where macros are expanded.

### Before jumping in the actual design though, it is worth mentioning a few things about TL-Verilog. 

 TL-Verilog source file is first processed by a macro preprocessor called M4. This is how visualization was also implemented, importing its library and instantiating. The resulting TL-Verilog file is processed into SystemVerilog or Verilog by Redwood EDA’s SandPiper™ tool. Verilator is an open-source tool used to compile your Verilog code into a C++ simulator. This simulator is run to produce the trace data that you can view in the waveform viewer. The LOG tab shows output from all these tools. Output from M4 and SandPiper is in blue, and output from Verilator and its resulting simulation are in black. TL-Verilog features are used to define the logic within a (System)Verilog module.

 TL-Verilog is really a Verilog implementation of TL-X, a language extension defined to layer atop any HDL to extend it with transaction-level features. So there is a migration path from any supported HDL (and, as of this writing, Verilog is the only one). The ultimate goal of this Verilog evolution, is to eventually introduce a new modeling language philosophically different from Verilog in all respects. This will play out over the next decade or decades. In the meantime, this is done incrementally, layering on Verilog as a working starting point, with TL-Verilog as a language extension to Verilog. This layering also provides an essential and incremental migration path. And, as tools mature, it is always possible to fall back on Verilog.

## About RISC-V architecture 
 RISC-V has very rapidly gained popularity due to its open nature--its explicit lack of patent protection and its community focus. Following the lead of RISC-V, MIPS and PowerPC have subsequently gone open as well. "RISC", in fact, stands for "reduced instruction set computing" and contrasts with "complex instruction set computing" (CISC). RISC-V (pronounced "risk five") is the fifth in a series of RISC ISAs from UC Berkeley. Like other RISC (and even CISC) ISAs, RISC-V is a load-store architecture. It contains a register file capable of storing up to 32 values. Load and store instructions transfer values between memory and the register file. All instructions are 32 bits.
RISC-V instructions may provide the following fields:
 * opcode: Provides a general classification of the instruction and determines which of the remaining fields are needed, and how they are laid out, or encoded, in the remaining instruction bits.
 * function field(funct3/funct7)
 * rs1/rs2: The indices (0-31) identifying the register(s) in the register file containing the source operand values on which the instruction operates.
 * rd: The index (0-31) of the register into which the instruction’s result is written.
 * immediate: A value contained within the instruction bits themselves. This value may provide an offset for indexing into memory or a value upon which to operate (in place of the register value indexed by rs2).

Below a RISC-V base instruction format is presented, from ![RISC-V specifications](https://riscv.org/technical/specifications/ "RISC-V base insturction format showing immediate variants")
![My Image](RISC-V_ISA.jpg)

To determine the type of instruction , you can examine its opcode, first two bits must be 2'b11 for valid RV321 instructions, every instruction is assumed to be valid. The ISA defines the instruction type to be determined as follows. Gray cells can be ignored as these are not used in RV321
![My Image](instruction_type.jpg)
