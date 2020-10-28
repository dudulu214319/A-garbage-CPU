`include "defines.v"

module if_stage(
    input    wire    cpu_clk_50M,
    input    wire    cpu_rst_n,
    output   reg     ice,
    output   reg[`INST_ADDR_BUS]   pc,
    output   wire[`INST_ADDR_BUS]  iaddr
    );
    
     wire   [`INST_ADDR_BUS]   pc_next;
     assign pc_next = pc+4;   //������һ��ָ��ĵ�ַ

     always@(posedge cpu_clk_50M) begin
        if(cpu_rst_n == `RST_ENABLE) begin
             ice <= `CHIP_DISABLE;   //��λ��ʱ��ָ��洢������
        end else begin
             ice<=`CHIP_ENABLE;     //��λ������ָ��洢��ʹ��
        end
     end    
     
    always@(posedge cpu_clk_50M) begin
       if(ice == `CHIP_DISABLE)
       //ָ��洢�����õ�ʱ�� PC���ֳ�ʼֵ(Mini MIPS 32������Ϊ0x 00000000)
         pc <= `PC_INIT;
       else begin
          pc <= pc_next; 
       end
     end
        
     //��÷���ָ��洢���ĵ�ַ
     assign iaddr = (ice==`CHIP_DISABLE) ?`PC_INIT : pc;
     
endmodule


