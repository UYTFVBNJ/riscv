`include "../common.v"

module id(
	// from IF
	input  wire	[`DATA_BUS]	instr_i,
	input  wire [`DATA_BUS] pc_i,
	
	// asynchronously from gprs
	input  wire	[`DATA_BUS]	gprs_rdata1_i,
	input  wire	[`DATA_BUS]	gprs_rdata2_i,
	
	// asynchronously to gprs
	output reg	[`REG_BUS]	gprs_raddr1,
	output reg	[`REG_BUS]	gprs_raddr2,
	
	// 转发 from EX
	input  wire [`REG_BUS]	ex_gprs_waddr,
	input  wire [`DATA_BUS]	ex_gprs_wdata,
	
	// to ID_EX
	output reg	[`RTLOP_BUS]	rtlop_o,
	output reg	[`RTLTYPE_BUS]	rtltype_o,
	output reg	[`DATA_BUS]		pc_o,
	output reg	[`DATA_BUS]		src1_o,
	output reg	[`DATA_BUS]		src2_o,
	output reg	[`REG_BUS]		gprs_waddr_o,
	
	// to cpu_ctrl
	output reg	error_o
);

	wire [6:0] opcode = instr_i[6:0];
	wire [2:0] funct3 = instr_i[14:12];
	wire [6:0] funct7 = instr_i[31:25];
	wire [4:0] rd  = instr_i[11:7];
	wire [4:0] rs1 = instr_i[19:15];
	wire [4:0] rs2 = instr_i[24:20];
	
	wire [`DATA_BUS] I_imm = {{20{instr_i[31]}}, instr_i[31:20]};
	wire [`DATA_BUS] S_imm = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
	wire [`DATA_BUS] B_imm = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
	wire [`DATA_BUS] U_imm = {instr_i[31:12], {12{1'b0}}};
	wire [`DATA_BUS] J_imm = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
	
	reg  [`DATA_BUS] reg_src1, reg_src2;
	
	// 分支指令
	wire b_eq = reg_src1 == reg_src2;
	wire b_lt = $signed(reg_src1) < $signed(reg_src2);
	wire b_ltu = reg_src1 < reg_src2;
	wire [1:0] b_funct2 = funct3[2:1];
	wire b_cmp_res = b_funct2 == `FUNCT2_BEQ ? b_eq : b_funct2 == `FUNCT2_BLT ? b_lt : b_ltu;
	wire b_res = b_cmp_res ^ funct3[0];
	
	
	always @(*) begin
		error_o		= 1'b0;
		rtlop_o		= `RTLOP_ADD;
		rtltype_o	= `RTLTYPE_ARICH;
		pc_o		= pc_i;
		gprs_raddr1  = rs1;
		gprs_raddr2  = rs2;
		gprs_waddr_o = `REG_X0;
		
		// 接收转发的寄存器值
		reg_src1	= gprs_rdata1_i;
		reg_src2	= gprs_rdata2_i;
		if (ex_gprs_waddr != `REG_X0) begin
			if (gprs_raddr1 == ex_gprs_waddr)
				reg_src1 = ex_gprs_wdata;
			if (gprs_raddr2 == ex_gprs_waddr)
				reg_src2 = ex_gprs_wdata;
		end
		src1_o		= reg_src1;
		src2_o		= reg_src2;
		
		case (opcode)
			// 寄存器与立即数的算术运算
			`INSTRGROUP_I: begin
				src2_o = I_imm;
				gprs_waddr_o = rd;
				
				rtltype_o = `RTLTYPE_ARICH;
				rtlop_o = {1'b0, funct3};
				case (funct3)
					`FUNCT3_SR: case (funct7)
						`FUNCT7_SHR:	rtlop_o = `RTLOP_SHR;
						`FUNCT7_SAR:	rtlop_o = `RTLOP_SAR;
						default:		error_o = 1'b1;
					endcase
					default:	rtlop_o = {1'b0, funct3};
				endcase
			end
			
			// 寄存器与寄存器的算术运算
			`INSTRGROUP_R: begin
				gprs_waddr_o = rd;
				
				rtltype_o = `RTLTYPE_ARICH;
				rtlop_o = {1'b0, funct3};
				case (funct3)
					`FUNCT3_ADD: case (funct7)
						`FUNCT7_ADD:	src2_o = src2_o;
						`FUNCT7_SUB:	src2_o = ~src2_o + 1'b1;
						default:		error_o = 1'b1;
					endcase
					`FUNCT3_SR: case (funct7)
						`FUNCT7_SHR:	rtlop_o = `RTLOP_SHR;
						`FUNCT7_SAR:	rtlop_o = `RTLOP_SAR;
						default:		error_o = 1'b1;
					endcase
					default: case (funct7)
						`FUNCT7_ZERO:	rtlop_o = {1'b0, funct3};
						default:		error_o = 1'b1;
					endcase
				endcase
			end
			
			// 从内存读取数据到寄存器
			`INSTRGROUP_L: begin
				// 读取地址为 rs1 + offset 处共 funct3 byte 到 rd 寄存器中
				src2_o = I_imm;
				gprs_waddr_o = rd;
				
				rtltype_o = `RTLTYPE_RMEM;
				rtlop_o = `RTLOP_ADD;
				
				// TODO: 需要更多补充信息来指示读取的长度。此处默认全部为4byte
				
			end
			
			// 写入数据到内存
			`INSTRGROUP_S: begin
				// 将 rs2 寄存器的值写入到地址为 rs1 + offset 处共 funct3 byte
				src1_o = reg_src1 + S_imm;
				
				rtltype_o = `RTLTYPE_WMEM;
				rtlop_o = `RTLOP_ADD;
				
				// TODO: 需要更多补充信息来指示读取的长度。此处默认全部为4byte
				
			end
			
			// 相对PC跳转
			`INSTR_JAL: begin
				// 相对于 pc 进行跳转
				src1_o = pc_i;
				src2_o = J_imm;
				gprs_waddr_o = rd;
				
				rtltype_o = `RTLTYPE_JUMP;
				rtlop_o = `RTLOP_ADD;
			end
			
			// 间接跳转
			`INSTR_JALR: begin
				// 相对于 rs1 进行跳转
				src2_o = I_imm;
				gprs_waddr_o = rd;
				
				rtltype_o = `RTLTYPE_JUMP;
				rtlop_o = `RTLOP_ADD;
			end
			
			// 分支指令
			`INSTRGROUP_B: begin
				// 相对于 pc 进行跳转
				src1_o = pc_i;
				src2_o = B_imm;
				
				// 如果条件不成立，退化成空指令
				rtltype_o = b_res ? `RTLTYPE_JUMP : `RTLTYPE_ARICH;
				rtlop_o = `RTLOP_ADD;
			end
			
			// 加载立即数到寄存器的高位中
			`INSTR_LUI: begin
				src1_o = U_imm;
				src2_o = `DATA_ZERO;
				gprs_waddr_o = rd;
				
				rtltype_o = `RTLTYPE_ARICH;
				rtlop_o = `RTLOP_ADD;
			end
			
			// 将 pc + offset 赋值给寄存器
			`INSTR_AUIPC: begin
				src1_o = pc_i;
				src2_o = U_imm;
				gprs_waddr_o = rd;
				
				rtltype_o = `RTLTYPE_ARICH;
				rtlop_o = `RTLOP_ADD;
			end
			
			default: begin
				error_o = 1'b1;
			end
		endcase
	end
	
endmodule
