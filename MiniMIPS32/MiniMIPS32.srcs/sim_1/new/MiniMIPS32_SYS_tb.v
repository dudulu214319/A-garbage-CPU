`timescale 1ns / 1ps

module MiniMIPS32_SYS_tb();

    // Inputs
	reg sys_clk_100M;
	reg sys_rst_n;
	
	MiniMIPS32_SYS SoC (
		.sys_clk_100M(sys_clk_100M),
		.sys_rst_n(sys_rst_n)
	);
	
	initial begin
		// Initialize Inputs
		sys_clk_100M = 0;
		sys_rst_n = 0;
		
		sys_rst_n = 1'b0;
		#200
		sys_rst_n = 1'b1;
		
		#100000 $stop;
	end
	
	initial begin
	  sys_clk_100M = 1'b0;                 // 每隔5ns，sys_clk_100M信号翻转一次，所以一个周期是10ns，对应100MHz
	  forever #5 sys_clk_100M  = ~sys_clk_100M ;
	end

endmodule
