`default_nettype none

`define DATA_WIDTH		32
`define DATA_BUS		`DATA_WIDTH - 1 : 0
`define DATA_ZERO		32'd0

`define CPU_RESET_ADDR	32'h0

`define REG_COUNT		32
`define REG_BUS			4 : 0

`define REG_X0			5'd0



// 立即数计算
`define INSTRGROUP_I	7'b0010011
// 寄存器计算
`define INSTRGROUP_R	7'b0110011
`define FUNCT3_ADD		3'b000
`define FUNCT3_SLL		3'b001
`define FUNCT3_SLT		3'b010
`define FUNCT3_SLTU		3'b011
`define FUNCT3_XOR		3'b100
`define FUNCT3_SR		3'b101
`define FUNCT3_OR		3'b110
`define FUNCT3_AND		3'b111

`define FUNCT7_ZERO		7'b0000000
`define FUNCT7_ADD		7'b0000000
`define FUNCT7_SUB		7'b0100000
`define FUNCT7_SHR		7'b0000000
`define FUNCT7_SAR		7'b0100000

// 读取内存
`define INSTRGROUP_L	7'b0000011
`define INSTR_LB		3'b000
`define INSTR_LH		3'b001
`define INSTR_LW		3'b010
`define INSTR_LBU		3'b100
`define INSTR_LHU		3'b101

// 写入内存
`define INSTRGROUP_S	7'b0100011
`define INSTR_SB		3'b000
`define INSTR_SH		3'b001
`define INSTR_SW		3'b010

// 跳转
`define INSTR_JAL		7'b1101111
`define INSTR_JALR		7'b1100111

// 其他
`define INSTR_LUI		7'b0110111
`define INSTR_AUIPC		7'b0010111

// 条件跳转
`define INSTRGROUP_B	7'b1100011
`define INSTR_BEQ		3'b000
`define INSTR_BNE		3'b001
`define INSTR_BLT		3'b100
`define INSTR_BGE		3'b101
`define INSTR_BLTU		3'b110
`define INSTR_BGEU		3'b111


// RTL
`define RTLOP_BUS		3 : 0
`define RTLTYPE_BUS		2 : 0

// 计算
`define RTLOP_ADD		4'b0000
`define RTLOP_SLL		4'b0001
`define RTLOP_SLT		4'b0010
`define RTLOP_SLTU		4'b0011
`define RTLOP_XOR		4'b0100
`define RTLOP_SHR		4'b0101
`define RTLOP_SAR		4'b1101
`define RTLOP_OR		4'b0110
`define RTLOP_AND		4'b0111

// 将计算结果直接存入寄存器
`define RTLTYPE_CALC	3'b000
// 将计算结果作为内存地址并读取
`define RTLTYPE_RMEM	3'b010
// 将计算结果作为内存地址并写入
`define RTLTYPE_WMEM	3'b011
// 将计算结果作为跳转地址
`define RTLTYPE_JUMP	3'b100
// 将计算结果作为跳转地址
`define RTLTYPE_BRANCH	3'b101
