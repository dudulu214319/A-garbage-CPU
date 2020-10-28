`include "defines.v"

module MiniMIPS32_SYS(
    input wire sys_clk_100M,
    input wire sys_rst_n
    );

    wire                  cpu_clk_50M;
    wire [`INST_ADDR_BUS] iaddr;
    wire                  ice;
    wire [`INST_BUS     ] inst;
    wire                  dce;
    wire [`DATA_ADDR_BUS] daddr;
    wire [`WORD_BUS     ] dm;
    wire [`BSEL_BUS     ] we;
    wire [`WORD_BUS     ] din;
    
    clk_wiz_0 clocking
    (
        // Clock out ports
        .clk_out1(cpu_clk_50M),     // output clk_out1
        // Clock in ports
        .clk_in1(sys_clk_100M)
    );      // input clk_in1
    
    inst_rom inst_rom0 (
      .clka(cpu_clk_50M),    // input wire clka
      .ena(ice),      // input wire ena
      .addra(iaddr[12:2]),  // input wire [10 : 0] addra
      .douta(inst)  // output wire [31 : 0] douta
    );
    
    //新建立的8k的数据存储器
    data_ram data_rom0 (
      .clka(cpu_clk_50M),    // input wire clka
      .ena(dce),      // input wire ena
      .wea(we),      // input wire [3 : 0] wea
      .addra(daddr[12:2]),  // input wire [10 : 0] addra
      .dina(din),    // input wire [31 : 0] dina
      .douta(dm)  // output wire [31 : 0] douta
    );
    
    
    MiniMIPS32 minimips32 (
        .cpu_clk_50M(cpu_clk_50M),
        .cpu_rst_n(sys_rst_n),
        .iaddr(iaddr),
        .ice(ice),
        .inst(inst),
        .dce(dce),
        .daddr(daddr),
        .din(din),
        .we(we),
        .dm(dm)
    );

endmodule
