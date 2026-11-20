//===========================================================
//
//			Name & Student ID: Reza Nazariye 405202795
//
//			Implemented Instructions are:
//			R format:  add(u), sub(u), and, or, xor, nor, slt, sltu;
//			I format:  beq, bne, lw, sw, addi, addiu, slti, sltiu, andi, ori, xori, lui.
//
//===========================================================

`timescale 1ns/1ns

`define ADD  3'b000
`define SUB  3'b001
`define SLT  3'b010
`define SLTU 3'b011
`define AND  3'b100
`define OR   3'b101
`define NOR  3'b110
`define XOR  3'b111


module single_cycle_mips 
(
	input clk,
	input reset
);
 
	initial begin
		$display("Single Cycle ACA-MIPS Implemention");
		$display("Reza Nazariye 405202795");
	end

	reg [31:0] PC;          // Keep PC as it is, its name is used in higher level test bench
   

	// YOUR DESIGN COMES HERE

   //control wires:
   wire [2:0] ALUControl;
   wire MemWrite;
   wire ALUSrc;
   wire MemtoReg;
   wire RegDst;
   wire Branch;
   wire PCSrc; 
   wire RegWrite;
   wire Jump;

   // REZA: additional control wires:
   wire S_Z_extend; // if 0 Zero extend, else sign extend
   wire BranchN; // works for bne
   wire LoadUpeerIm;
   

   // normal logics
   wire [31:0] Instr;
   wire [31:0] SignImm;
   wire [31:0] ZeroXtnd; 
   wire [31:0] SrcA;
   wire [31:0] SrcB;
   wire Alu_Zero;
   wire [31:0] ALUResult;
   wire [31:0] Result;

   //MEM
   wire [31:0] ReadData;
   wire [31:0] WriteData;
   wire [4:0] WriteReg;

   //PC
   wire [31:0] PCPlus4;
   wire [31:0] NextPC;
   wire [31:0] PCBranch;
   wire [31:0] PCJump;


   //REZA: wire added by me:
   wire [31:0] Immdiate_Xtended;
   wire [31:0] UpperImmdiate;
   wire [31:0] Immdiate;
   wire Beq_src;
   wire Bne_src;
   
// Assignments
   assign SignImm = {{16{Instr[15]}}, Instr[15:0]};
   assign ZeroXtnd = {{16{1'b0}}, Instr[15:0]};
   assign UpperImmdiate = {Instr[15:0], {16{1'b0}}};
   assign Beq_src = Alu_Zero & Branch;
   assign Bne_src = (!Alu_Zero) & BranchN;

   // PC assigments:
   assign PCPlus4 = PC + 32'd4;
   assign PCSrc = Beq_src | Bne_src;
   assign PCBranch = PCPlus4 + {SignImm[29:0], 2'b00};
   assign PCJump =  {PCPlus4[31:28], Instr[25:0], 2'b00};
   assign NextPC = Jump ? PCJump : (PCSrc ? PCBranch : PCPlus4);
   assign Immdiate_Xtended = S_Z_extend ? SignImm : ZeroXtnd;
   assign Immdiate = LoadUpeerIm ? UpperImmdiate : Immdiate_Xtended;

   // control MUXs:
   assign SrcB = ALUSrc ? Immdiate : WriteData;
   assign Result = MemtoReg ? ReadData : ALUResult;
   assign WriteReg = RegDst ? Instr[15:11] : Instr [20:16];



   always @ (posedge clk)
   begin
      if(reset)
      begin
         PC <= 0;
      end
      else
      begin
         PC <= NextPC;
      end
   end
	
//========================================================== 
//	instantiated modules
//========================================================== 

//	Instruction Memory
	async_mem imem			// keep the exact instance name
	(
		.clk		   (1'b0),
		.write		(1'b0),		// no write for instruction memory
		.address	   ( PC ),	   // address instruction memory with pc
		.write_data	('bx),
		.read_data	( Instr )   // REZA
	);
	
// Data Memory
	async_mem dmem			// keep the exact instance name
	(
		.clk		   ( clk ),
		.write		( MemWrite ),
		.address	   ( ALUResult ),
		.write_data	( WriteData ),
		.read_data	( ReadData )
	);

// REZA: Reg file

   reg_file reg_file(
      .clk(clk),
      .write(RegWrite),
      .WR(WriteReg),
      .WD(Result),
      .RR1(Instr[25:21]),
      .RR2(Instr[20:16]),
      .RD1(SrcA),
      .RD2( WriteData )
   );

// REZA: ALU
   my_alu ALU(
      .Op(ALUControl),
      .A(SrcA),
      .B(SrcB),
      .X(ALUResult),
      .Z(Alu_Zero)
   );

//REZA: my control unit
   controlUnit ctrl(
      .reset(reset),
      .OP(Instr[31:26]),
      .Funct(Instr[5:0]),
      .MemtoReg(MemtoReg),
      .MemWrite(MemWrite),
      .Branch(Branch),
      .ALUOP(ALUControl),
      .ALUSrc(ALUSrc),
      .RegDst(RegDst),
      .RegWrite(RegWrite),
      .Jump(Jump),
      .SZ_extend(S_Z_extend),
      .BranchN(BranchN),
      .LUI(LoadUpeerIm)
   );
endmodule

//REZA control unit
module controlUnit
(
   input wire reset,
   input wire [5:0] OP,
   input wire [5:0] Funct,
   output reg MemtoReg,
   output reg MemWrite,
   output reg Branch,
   output reg [2:0] ALUOP,
   output reg ALUSrc,
   output reg RegDst,
   output reg RegWrite,
   output reg Jump,
   // REZA: wires added by me
   output reg SZ_extend,
   output reg BranchN,
   output reg LUI
);

always @ (*)
begin
   if(reset)
   begin
      RegWrite =  1'b0;
      RegDst   =  1'b0;
      ALUSrc   =  1'b0;
      Branch   =  1'b0;
      MemWrite =  1'b0;
      MemtoReg =  1'b0;
      Jump     =  1'b0;
      ALUOP    =  3'b000;
      SZ_extend=  1'b0;
      BranchN  =  1'b0;
   end
   else
   begin
      case (OP)
         6'b000000: // Rtype OPrations
         begin
            RegWrite =  1'b1;
            RegDst   =  1'b1;
            ALUSrc   =  1'b0;
            Branch   =  1'b0;
            MemWrite =  1'b0;
            MemtoReg =  1'b0;
            Jump     =  1'b0;

            SZ_extend=  1'bx;
            BranchN  =  1'b0;
            LUI      =  1'b0;
            case  (Funct)
               6'b100000: //add
               begin
                  ALUOP = `ADD;
               end
               6'b100001: //addu
               begin
                  ALUOP = `ADD;
               end
               6'b100010: //sub
               begin
                  ALUOP = `SUB;
               end
               6'b100011: //subu
               begin
                  ALUOP = `SUB;
               end
               6'b100100: //and
               begin
                  ALUOP = `AND;
               end
               6'b100101: //or
               begin
                  ALUOP = `OR;
               end
               6'b100110: //XOR
               begin
                  ALUOP = `XOR;
               end
               6'b100111: //nor
               begin
                  ALUOP = `NOR;
               end
               6'b101010: //slt
               begin
                  ALUOP = `SLT;
               end
               6'b101011: //sltu
               begin
                  ALUOP = `SLTU;
               end
            endcase
         end
         6'b100011: // LW
         begin
            RegWrite =  1'b1;
            RegDst   =  1'b0;
            ALUSrc   =  1'b1;
            Branch   =  1'b0;
            MemWrite =  1'b0;
            MemtoReg =  1'b1;
            ALUOP    =  `ADD;
            Jump     =  1'b0;

            SZ_extend=  1'bx;
            BranchN  =  1'b0;
            LUI      =  1'b0;
         end
         6'b101011: // SW
         begin
            RegWrite =  1'b0;
            RegDst   =  1'bx;
            ALUSrc   =  1'b1;
            Branch   =  1'b0;
            MemWrite =  1'b1;
            MemtoReg =  1'bx;
            ALUOP    =  `ADD;
            Jump     =  1'b0;

            SZ_extend=  1'bx;
            BranchN  =  1'b0;
            LUI      =  1'b0;
         end
         6'b000100: // beq
         begin
            RegWrite =  1'b0;
            RegDst   =  1'bx;
            ALUSrc   =  1'b0;
            Branch   =  1'b1;
            MemWrite =  1'b0;
            MemtoReg =  1'bx;
            ALUOP    =  `SUB;
            Jump     =  1'b0;

            SZ_extend=  1'bx;
            BranchN  =  1'b0;
            LUI      =  1'b0;
         end
         6'b000101: // bne
         begin
            RegWrite =  1'b0;
            RegDst   =  1'bx;
            ALUSrc   =  1'b0;
            Branch   =  1'b0;
            MemWrite =  1'b0;
            MemtoReg =  1'bx;
            ALUOP    =  `SUB;
            Jump     =  1'b0;

            SZ_extend=  1'bx;
            BranchN  =  1'b1;
            LUI      =  1'b0;
         end
         6'b001000: // addi
         begin
            RegWrite =  1'b1;
            RegDst   =  1'b0;
            ALUSrc   =  1'b1;
            Branch   =  1'b0;
            MemWrite =  1'b0;
            MemtoReg =  1'b0;
            ALUOP    =  `ADD;
            Jump     =  1'b0;

            SZ_extend=  1'b1;
            BranchN  =  1'b0;
            LUI      =  1'b0;
         end
         6'b001001: // addiu
         begin
            RegWrite =  1'b1;
            RegDst   =  1'b0;
            ALUSrc   =  1'b1;
            Branch   =  1'b0;
            MemWrite =  1'b0;
            MemtoReg =  1'b0;
            ALUOP    =  `ADD;
            Jump     =  1'b0;

            SZ_extend=  1'b1;
            BranchN  =  1'b0;
            LUI      =  1'b0;
         end
         6'b001010: // slti
         begin
            RegWrite =  1'b1;
            RegDst   =  1'b0;
            ALUSrc   =  1'b1;
            Branch   =  1'b0;
            MemWrite =  1'b0;
            MemtoReg =  1'b0;
            ALUOP    =  `SLT;
            Jump     =  1'b0;

            SZ_extend=  1'b1;
            BranchN  =  1'b0;
            LUI      =  1'b0;
         end
         6'b001011: // sltiu
         begin
            RegWrite =  1'b1;
            RegDst   =  1'b0;
            ALUSrc   =  1'b1;
            Branch   =  1'b0;
            MemWrite =  1'b0;
            MemtoReg =  1'b0;
            ALUOP    =  `SLTU;
            Jump     =  1'b0;

            SZ_extend=  1'b0;
            BranchN  =  1'b0;
            LUI      =  1'b0;
         end
         6'b001100: // andi
         begin
            RegWrite =  1'b1;
            RegDst   =  1'b0;
            ALUSrc   =  1'b1;
            Branch   =  1'b0;
            MemWrite =  1'b0;
            MemtoReg =  1'b0;
            ALUOP    =  `AND;
            Jump     =  1'b0;

            SZ_extend=  1'b0;
            BranchN  =  1'b0;
            LUI      =  1'b0;
         end
         6'b001101: // ori
         begin
            RegWrite =  1'b1;
            RegDst   =  1'b0;
            ALUSrc   =  1'b1;
            Branch   =  1'b0;
            MemWrite =  1'b0;
            MemtoReg =  1'b0;
            ALUOP    =  `OR;
            Jump     =  1'b0;

            SZ_extend=  1'b0;
            BranchN  =  1'b0;
            LUI      =  1'b0;
         end
         6'b001110: // xori
         begin
            RegWrite =  1'b1;
            RegDst   =  1'b0;
            ALUSrc   =  1'b1;
            Branch   =  1'b0;
            MemWrite =  1'b0;
            MemtoReg =  1'b0;
            ALUOP    =  `XOR;
            Jump     =  1'b0;

            SZ_extend=  1'b0;
            BranchN  =  1'b0;
            LUI      =  1'b0;
         end
         6'b001111: // lui
         begin    // TODO
            RegWrite =  1'b1;
            RegDst   =  1'b0;
            ALUSrc   =  1'b1;
            Branch   =  1'b0;
            MemWrite =  1'b0;
            MemtoReg =  1'b0;
            ALUOP    =  `ADD;
            Jump     =  1'b0;

            SZ_extend=  1'bx;
            BranchN  =  1'b0;
            LUI      =  1'b1;
         end
         6'b000010: // jump
         begin
            RegWrite =  1'b0;
            RegDst   =  1'bx;
            ALUSrc   =  1'bx;
            Branch   =  1'bx;
            MemWrite =  1'b0;
            MemtoReg =  1'bx;
            ALUOP    =  3'bxxx;
            Jump     =  1'b1;

            SZ_extend=  1'bx;
            BranchN  =  1'b0;
            LUI      =  1'b0;
         end



         default: // TODO
         begin

         end
      endcase
   end
end

endmodule

//==============================================================================
// This is a sample ALU, You may need to change it
// Note: You have to define Op case constants
//==============================================================================

module my_alu(
   input  [2:0] Op,
   input  [31:0] A,
   input  [31:0] B,
   output [31:0] X,
   output        Z
   );

   wire sub = Op != `ADD;
   wire [31:0] bb = sub ? ~B : B;
   wire [32:0] sum = A + bb + sub;
   wire sltu = ! sum[32];

   wire v = sub ?
            ( A[31] != B[31] && A[31] != sum[31] )
          : ( A[31] == B[31] && A[31] != sum[31] );

   wire slt = v ^ sum[31];

   reg [31:0] x;

   always @( * )
      case( Op )
         `ADD : x = sum;
         `SUB : x = sum;
         `SLT : x = slt;
         `SLTU: x = sltu;
         `AND : x = A & B;
         `OR  : x = A | B;
         `NOR : x = ~(A | B);
         `XOR : x = A ^ B;
         default : x = 32'hxxxxxxxx;
      endcase

   assign X = x;
   assign Z = x == 32'h00000000;

endmodule

//============================================================================


