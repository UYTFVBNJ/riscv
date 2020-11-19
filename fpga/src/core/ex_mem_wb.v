`include "../common.v"

module ex_mem_wb(
	input  wire	clk,
	input  wire	rst,
	
	// 横跨两个周期，需要注意时序
	// 以EX为基准，当EX计算完毕后，计算结果交由MEM进行读取。
	// EX到MEM的上升沿读取结束。
	// 应该在此周期准备好gprs的写回操作。
	// from EX
	input  wire					ex_valid,
	input  wire					ex_mem_ena,
	input  wire	[`REG_BUS]		gprs_waddr_i,
	input  wire	[`DATA_BUS]		gprs_wdata_i,
	
	// from MEM
	input  wire					mem_rw_i,
	input  wire	[`DATA_BUS]		mem_rdata_i,
	
	// to GPRS
	output wire	[`REG_BUS]		gprs_waddr_o,
	output wire	[`DATA_BUS]		gprs_wdata_o,
	
	// asynchronously to cpu_ctrl
	output wire					stall,
	output wire					jump_flag,
	output wire	[`DATA_BUS]		jump_addr
);

	// EX已经计算出最终结果，跳过MEM阶段立即执行写寄存器。
	reg  [`REG_BUS]		through_gprs_waddr_o;
	reg  [`DATA_BUS]	through_gprs_wdata_o;

	always @(*) begin
		if (ex_valid && ex_mem_ena == `DISABLE) begin
			through_gprs_waddr_o <= gprs_waddr_i;
			through_gprs_wdata_o <= gprs_wdata_i;
		end
		else begin
			through_gprs_waddr_o <= `REG_X0;
			through_gprs_wdata_o <= `DATA_ZERO;
		end
	end
	
	wire comb_stall = ex_valid && ex_mem_ena == `ENABLE && mem_rw_i == `MEM_READ;
	reg  stall_state;
	
	always @(posedge clk)
		if (comb_stall)
			stall_state <= 1'b0;
		else
			stall_state <= 1'b1;
	
	assign stall = comb_stall & stall_state;
	
	assign jump_flag = 1'b0;
	assign jump_addr = `DATA_ZERO;


	// 需要读取MEM，在上升沿后才能获取正确写入的值
	reg  [`REG_BUS]		mem_gprs_waddr_o;
	reg  [`DATA_BUS]	mem_gprs_wdata_o;
	
	always @(posedge clk) begin
		if (rst || !ex_valid || ex_mem_ena == `DISABLE) begin
			mem_gprs_waddr_o <= `REG_X0;
			mem_gprs_wdata_o <= `DATA_ZERO;
		end
		else begin
			mem_gprs_waddr_o = gprs_waddr_i;
			mem_gprs_wdata_o = mem_rdata_i;
		end
	end
	
	assign gprs_waddr_o = stall_state ? through_gprs_waddr_o : gprs_waddr_i;
	assign gprs_wdata_o = stall_state ? through_gprs_wdata_o : mem_rdata_i;

endmodule
