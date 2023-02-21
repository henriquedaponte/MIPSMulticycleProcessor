// ucsbece154a_datapath.v
// All Rights Reserved
// Copyright (c) 2022 UCSB ECE
// Distribution Prohibited


// TODO: Implement datapath
//  • fill flip-flop D values
//  • fill rf and alu
//  • add the rest of your code
//  • BE SURE TO HANDLE YOUR CONTROL VALUES WITH THE PARAMS IN THE "defines.vh" FILE!
module ucsbece154a_datapath (
    input               clk, reset,
    input               PCWrite_i,
    input         [1:0] PCSrc_i,
    input               ALUSrcA_i,
    input         [1:0] ALUSrcB_i,
    input               RegWrite_i,
    input               IorD_i,
    input               IRWrite_i,
    input               RegDst_i,
    input               Branch_i,
    input               MemToReg_i,
    input         [2:0] ALUControl_i,
    input               ZeroExtImm_i,
    output reg   [31:0] a_o,
    output wire  [31:0] wd_o,
    input        [31:0] rd_i,
    output wire   [5:0] op_o,
    output wire   [5:0] funct_o
);

`include "ucsbece154a_defines.vh"

// flip flops
reg [31:0] pc;
reg [31:0] instr;
reg [31:0] data;
reg [31:0] a;
reg [31:0] b;
reg [31:0] aluout;

wire pcen = (Branch_i & zero) | PCWrite_i;

always @(posedge clk) begin
    if (reset) begin
        pc <= pc_start;
        instr <= {32{1'bx}};
        data <= {32{1'bx}};
        a <= {32{1'bx}};
        b <= {32{1'bx}};
        aluout <= {32{1'bx}};
    end else begin
        // FILL FLIP FLOP D VALUES
        if (pcen) pc <= pcNext;
        if (IRWrite_i) instr <= rd_i;
        data <= rd_i;
        a <= RD1;
        b <= RD2;
        aluout <= aluResult;
    end
end

// **PUT THE REST OF YOUR CODE HERE**
reg [31:0] aluSrcA;
reg [31:0] aluSrcB;
reg [4:0] regWrite;
reg [31:0] pcNext;
wire [31:0] immediateExt;
wire [31:0] result;
wire [31:0] RD1;
wire [31:0] RD2;
wire [31:0] signZeroExt;
wire zero;
wire [31:0] aluResult;

assign immediateExt = instr[15] ? {16'hFFFF, instr[15:0]} : {16'h0000, instr[15:0]};
assign signZeroExt = ZeroExtImm_i ? {16'h0000, instr[15:0]} : immediateExt;  
    
always @ * begin
  case(ALUSrcA_i)
    ALUSrcA_pc: aluSrcA = pc;
    ALUSrcA_rf: aluSrcA = a;
  endcase

  case(ALUSrcB_i)
    ALUSrcB_rf: aluSrcB = b;
    ALUSrcB_4: aluSrcB = 4;
    ALUSrcB_immext: aluSrcB = signZeroExt;
    ALUSrcB_pcoffset: aluSrcB = {signZeroExt[29:0],2'h0}; 
  endcase

  case(IorD_i)
    IorD_I: a_o = pc;
    IorD_D: a_o = aluout;
  endcase

  case(PCSrc_i)
    PCSrc_aluresult: pcNext = aluResult;
    PCSrc_aluout: pcNext = aluout;
    PCSrc_jump: pcNext = {pc[31:28],{instr[25:0],2'b00}};
    default: pcNext = {32{1'bx}};
  endcase

  case(RegDst_i)
    RegDst_I: regWrite = instr[20:16];
    RegDst_R: regWrite = instr[15:11];
  endcase

  end

	assign result = MemToReg_i ? data : aluout;
  assign op_o = instr[31:26];
  assign funct_o = instr[5:0];
  assign wd_o = RD2;

ucsbece154a_rf rf (
  .clk(clk),
	.a1_i(instr[25:21]),
	.a2_i(instr[20:16]),
	.a3_i(regWrite),
  .rd1_o(RD1),
	.rd2_o(RD2),
  .we3_i(RegWrite_i),
	.wd3_i(result)
);

ucsbece154a_alu alu (
  .a_i(aluSrcA),
	.b_i(aluSrcB),
	.f_i(ALUControl_i),
  .y_o(aluResult),
	.zero_o(zero)
);

endmodule
