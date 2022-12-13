\m4_TLV_version 1d: tl-x.org
\SV
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/1d1023ccf8e7b0a8cf8e8fc4f0a823ebb61008e3/risc-v_defs.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])



   //---------------------------------------------------------------------------------
   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // 
   // Add 1,2,3,...,9 (in that order).
   //
   //       
   m4_asm(SW, x5, 10001)               
   m4_asm(ADDI, x14, x0, 0)             // Initialize sum register a4 with 0
   m4_asm(ADDI, x12, x0, 1010)          // Store count of 10 in register a2.
   m4_asm(ADDI, x13, x0, 1)             // Initialize loop count register a3 with 0                 
   // Loop:
   m4_asm(ADD, x14, x13, x14)           // Incremental summation
   m4_asm(ADDI, x13, x13, 1)            // Increment loop count by 1
   m4_asm(BLT, x13, x12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   // Test result value in x14, and set x31 to reflect pass/fail.
   m4_asm(ADDI,x0,x0,1010)
   //m4_asm(LW, x23, 10011)
   m4_asm(ADDI, x30, x14, 111111010100) // Subtract expected value of 44 to set x30 to 1 if and only iff the result is 45 (1 + 2 + ... + 9).               
   m4_asm(BGE, x0, x0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)                 
   m4_asm_end()
   m4_define(['M4_MAX_CYC'], 50)
   //---------------------------------------------------------------------------------


\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
   /* verilator lint_off WIDTH */                
\TLV
   // to silence warnings for unused variables, a BOGUS_USE command is used
   `BOGUS_USE($rd $rd_valid $rs1 $rs1_valid $rs2 $rs2_valid $funct3 $funct3_valid $imm_valid)
   `BOGUS_USE($is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_add $is_addi)
   $reset = *reset;
   $pc[31:0] = >>1$next_pc[31:0];
   $next_pc[31:0] =
    $reset ? 0 : //reset values to )
    $taken_br || $is_jal? $br_tgt_pc[31:0] : //branch to target PC if in branch command
    $is_jalr ? $jalr_tgt_pc: //jump to jalr target PC if in jalr command
                   $pc + 32'b100; // Default case, always increment by 4
   
   `READONLY_MEM($pc, $$instr[31:0]);//this is a macro read-only memory that constantly reads
   
   
   //decode instruction according to opcode, first two bits are ignored because all instructions are RV321 valid
   $is_u_instr = ($instr[6:2] ==? 5'b0x101); // third bit is a don't care bit
   $is_i_instr = ($instr[6:2] ==? 5'b001x0) || ($instr[6:2] ==? 5'b0000x) || $instr[6:2] == 5'b11001;
   $is_b_instr = $instr[6:2] == 5'b11000;
   $is_j_instr = $instr[6:2] == 5'b11011;
   $is_r_instr = $instr[6:2] == 5'b01011 || $instr[6:2] == 5'b01100 || $instr[6:2] == 5'b10100 || $instr[6:2] == 5'b01110;
   $is_s_instr = $instr[6:2] == 5'b0100x;
   //extracting simple necessary fields for 
   $rs2[4:0] = $instr[24:20];
   $rs1[4:0] = $instr[19:15];
   $rd[4:0] = $instr[11:7];
   $funct3[2:0] = $instr[14:12];
   //examining when these fields are valid, always according to RISC-V base instructions format
   $rs2_valid = $is_r_instr || $is_s_instr || $is_b_instr;
   $rs1_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rd_valid = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
   $funct3_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $imm_valid = ({$is_r_instr,$is_i_instr,$is_s_instr,$is_b_instr,$is_u_instr,$is_j_instr} == 6'b011111);
   //Immediate value assignment
   $imm[31:0] = $is_i_instr ? {  {21{$instr[31]}},  $instr[30:20]  } :
                $is_s_instr ? {  {21{$instr[31]}},  $instr[30:25], $instr[11:8], $instr[7]  } :
                $is_b_instr ? {  {20{$instr[31]}},$instr[7],  $instr[30:25], $instr[11:8], 1'b0  } :
                $is_u_instr ? { $instr[31:12],12'b0  } :
                $is_j_instr ? {  {12{$instr[31]}}, $instr[19:12], $instr[20],  $instr[30:25], $instr[24:21], 1'b0  } :
                              32'b0;  // Default
   // Specific instruction determined by  opcode, instr[30], and funct3 fields
   $opcode[6:0] = $instr[6:0];
   $dec_bits[10:0] = {$instr[30],$funct3,$opcode};
   //decide instructions based on dec_bits
   //branch instructions
   $is_beq = $dec_bits ==? 11'bx0001100011;
   $is_bne = $dec_bits ==? 11'bx0011100011;
   $is_blt = $dec_bits ==? 11'bx1001100011;
   $is_bge = $dec_bits ==? 11'bx1011100011;
   $is_bltu = $dec_bits ==? 11'bx1101100011;
   $is_bgeu = $dec_bits ==? 11'bx1111100011;
   //operations
   $is_sub = $dec_bits ==? {4'b1000,7'b0110011};
   $is_sll = $dec_bits ==? {4'b0001,7'b0110011};
   $is_slt = $dec_bits ==? {4'b0010,7'b0110011};
   $is_sltu = $dec_bits ==? {4'b0011,7'b0110011};
   $is_add = $dec_bits ==? {4'b0000,7'b0110011};
   $is_lui = $dec_bits ==? {4'bxxxx,7'b0110111};
   $is_auipc = $dec_bits ==? {4'bxxxx,7'b0010111};
   $is_jal = $dec_bits ==? {4'bxxxx,7'b1101111};
   $is_jalr = $dec_bits ==? {4'bx000,7'b1100111};
   $is_slti = $dec_bits ==? {4'bx010,7'b0010011};
   $is_sltiu = $dec_bits ==? {4'bx011,7'b0010011};
   $is_xori = $dec_bits ==? {4'bx100,7'b0010011};
   $is_xor = $dec_bits ==? {4'b0100,7'b0110011};
   $is_srl = $dec_bits ==? {4'b0101,7'b0110011};
   $is_sra = $dec_bits ==? {4'b1101,7'b0110011};
   $is_ori = $dec_bits ==? {4'bx110,7'b0010011};
   $is_or = $dec_bits ==? {4'b0110,7'b0110011};
   $is_andi = $dec_bits ==? {4'bx111,7'b0010011};
   $is_and = $dec_bits ==? {4'b0111,7'b0110011};
   $is_slli = $dec_bits ==? {4'b0001,7'b0010011};
   $is_srli = $dec_bits ==? {4'b0101,7'b0010011};
   $is_srai = $dec_bits ==? {4'b1101,7'b0010011};
   $is_load = $dec_bits ==? {4'bx010,7'b0000011};
   $is_s_instr = $dec_bits ==? {4'bx010,7'b0100011};
   //immediate operations
   $is_addi = $dec_bits ==? {4'bx000,7'b0010011};
   //SLTU and SLTI (set if less than, unsigned) results:
   $sltu_rslt[31:0] = {31'b0, $src1_value < $src2_value};
   $sltiu_rslt[31:0] = {31'b0, $src1_value < $imm};
   //SRA and SRAI (shift right, arithmetic) results:
   //     sign-extended src1
   $sext_src1[63:0] = { {32{$src1_value[31]}} , $src1_value};
   //64-bit sign-extended results, to be truncated
   $sra_rslt[63:0] = $sext_src1 >> $src2_value[4:0];
   $srai_rslt[63:0] = $sext_src1 >> $imm[4:0];
      //ALU design assigns result the correct result
   $result[31:0] =
    $is_and ? $src1_value & $src2_value:
    $is_andi ? $src1_value & $imm:
    $is_ori ? $src1_value | $imm:
    $is_or ? $src1_value | $src2_value:
    $is_xori ? $src1_value ^ $imm:
    $is_xor ? $src1_value ^ $src2_value:
    $is_addi ? $src1_value + $imm :
    $is_load ? $src1_value + $imm : // address to load
    $is_s_instr ? $src1_value + $imm : // address to write
    $is_add ? $src1_value + $src2_value :
    $is_sub ? $src1_value - $src2_value :
    $is_sll ? $src1_value << $src2_value[4:0]:
    $is_slli ? $src1_value << $imm[5:0]:
    $is_srl ? $src1_value >> $src2_value[4:0]:
    $is_srli ? $src1_value >> $imm[5:0]:
    $is_sltu ? $sltu_rslt:
    $is_sltiu ? $sltiu_rslt:
    $is_lui  ? {$imm[31:12], 12'b0}:
    $is_auipc ? $pc + $imm:
    $is_jal ? $pc + 32'd4:
    $is_jalr ? $pc + 32'd4:
    $is_slt ? ( ($src1_value[31] == $src2_value[31]) ?
     $sltu_rslt:
     {31'b0,$src1_value[31]}):
    $is_slti ? ( ($src1_value[31] == $src2_value[31]) ?
     $sltiu_rslt:
     {31'b0,$src1_value[31]}):
    $is_sra ? $sra_rslt[31:0]:
    $is_srai ? $srai_rslt[31:0]:
               32'b0;
   //select data to load if is_load is asserted, otherwise choose result           
   $result_rf = $is_load ? $ld_data : $result;
   // Deassert write enbale of register file if destination register is x0, x0 is always  0
   $wr_en = $rd == 5'b0 ? 0 : 1;
   // Determine whether the instruction is a branch
   $taken_br =
    $is_beq ? $src1_value == $src2_value : //branch if equal
    $is_bne ? $src1_value != $src2_value :// branch if not equal
    $is_blt ? ($src1_value < $src2_value ) ^ $src1_value[31]!=$src2_value[31]: //branch if less than signed
    $is_bge ? ($src1_value >= $src2_value ) ^ $src1_value[31]!=$src2_value[31]:// branch if greater than signed
    $is_bltu ? $src1_value < $src2_value: // branch if less than unsigned
    $is_bgeu ? $src1_value >= $src2_value: // branch if greater than unsigned
               1'b0;
   $br_tgt_pc[31:0] = $pc[31:0] + $imm[31:0]; //branch target PC is PC + Immediate value
   $jalr_tgt_pc[31:0] = $src1_value + $imm; // target PC for jalr command. jump and link register
   // Assert these to end simulation (before Makerchip cycle limit).
   //*passed = 1'b0;
   m4+tb()
   *failed = *cyc_cnt > M4_MAX_CYC; //Simulation outputs fail if max cycles are met
   //TL-verilog array definition expanded from M4 macro preprocessor library
   m4+rf(32, 32, $reset, $wr_en, $rd, $result_rf, $rs1_valid, $rs1, $src1_value, $rs2_valid, $rs2, $src2_value)
   //DMem instantiation, similar to register file nad same size, supports loads/stores
   // with naturally alligned addresses only
   m4+dmem(32, 32, $reset, $result[6:2], $is_s_instr, $src2_value, $is_load, $ld_data)
   m4+cpu_viz()
\SV
   endmodule