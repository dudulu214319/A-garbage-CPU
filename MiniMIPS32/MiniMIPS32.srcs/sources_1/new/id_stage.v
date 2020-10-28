`include "defines.v"

module id_stage(
    input  wire                     cpu_rst_n,
    
    // 从取指阶段获得的PC值
    input  wire [`INST_ADDR_BUS]    id_pc_i,

    // 从指令存储器读出的指令字
    input  wire [`INST_BUS     ]    id_inst_i,

    // 从通用寄存器堆读出的数据 
    input  wire [`REG_BUS      ]    rd1,
    input  wire [`REG_BUS      ]    rd2,
      
    // 送至执行阶段的译码信息
    output wire [`ALUTYPE_BUS  ]    id_alutype_o,
    output wire [`ALUOP_BUS    ]    id_aluop_o,
    output wire                     id_whilo_o,
    output wire                     id_mreg_o,
    output wire [`REG_ADDR_BUS ]    id_wa_o,
    output wire                     id_wreg_o,
    output wire [`REG_BUS]          id_din_o, //?
    
    // 送至执行阶段的源操作数1、源操作数2
    output wire [`REG_BUS      ]    id_src1_o,
    output wire [`REG_BUS      ]    id_src2_o,
      
    // 送至读通用寄存器堆端口的使能和地址
    output wire                     rreg1,
    output wire [`REG_ADDR_BUS ]    ra1,
    output wire                     rreg2,
    output wire [`REG_ADDR_BUS ]    ra2
    );
    
    // 根据小端模式组织指令字
    wire [`INST_BUS] id_inst = {id_inst_i[7:0], id_inst_i[15:8], id_inst_i[23:16], id_inst_i[31:24]};

    // 提取指令字中各个字段的信息
    wire [5 :0] op   = id_inst[31:26];
    wire [5 :0] func = id_inst[5 : 0];
    wire [4 :0] rd   = id_inst[15:11];
    wire [4 :0] rs   = id_inst[25:21];
    wire [4 :0] rt   = id_inst[20:16];
    wire [4 :0] sa   = id_inst[10: 6];
    wire [15:0] imm  = id_inst[15: 0]; 

    /*-------------------- 第一级译码逻辑：确定当前需要译码的指令 --------------------*/
    wire inst_reg  = ~|op;
    wire inst_add = inst_reg&func[5] &~func[4] &~func[3] &~func[2] &~func[1] &~func[0];
    wire inst_addu = inst_reg&func[5]&~func[4] &~func[3] &~func[2] &~func[1] &func[0];
    wire inst_sub=inst_reg&func[5] &~func[4] &~func[3] &~func[2] &func[1] &~func[0];
    wire inst_subu=inst_reg&func[5] &~func[4] &~func[3] &~func[2] &func[1] &func[0];
    wire inst_slt=inst_reg&func[5] &~func[4] &func[3] &~func[2] &func[1] &~func[0];
    wire inst_sltu=inst_reg&func[5] &~func[4] &func[3] &~func[2] &func[1] &func[0];
    wire inst_and=inst_reg&func[5] &~func[4] &~func[3] &func[2] &~func[1] &~func[0];
    wire inst_mult=inst_reg&~func[5] &func[4] &func[3] &~func[2] &~func[1] &~func[0];
    wire inst_multu=inst_reg&~func[5] &func[4] &func[3] &~func[2] &~func[1] &func[0];
    wire inst_mfhi=inst_reg&~func[5] &func[4] &~func[3] &~func[2] &~func[1] &~func[0];
    wire inst_mflo=inst_reg&~func[5] &func[4]&~func [3] &~func[2] &func[1] &~func[0];
    wire inst_sll=inst_reg&~func[5] &~func[4] &~func[3] &~func[2] &~func[1] &~func[0];
    wire inst_ori=~op[5] &~op[4] &op[3] &op[2] &~op[1] &op[0];
    wire inst_lui=~op[5] &~op[4] &op[3] &op[2] &op[1] &op[0];
    wire inst_addi = ~op[5] &~op[4] &op[3] &~op[2] &~op[1] &~op[0];
    wire inst_addiu=~op[5] &~op[4] &op[3] &~op[2] &~op[1] &op[0];
    wire inst_slti=~op[5] &~op[4] &op[3] &~op[2] &op[1] &~op[0];
    wire inst_sltiu=~op[5] &~op[4] &op[3] &~op[2] &op[1] &op[0];
    wire inst_lb=op[5] &~op[4] &~op[3] &~op[2] &~op[1] &~op[0];
    wire inst_lw=op[5] &~op[4] &~op[3] &~op[2] &op[1] &op[0];
    wire inst_sb=op[5] &~op[4] &op[3] &~op[2] &~op[1] &~op[0];
    wire inst_sw=op[5]&~op[4]&op[3]&~op[2]&op[1]&op[0];
    /*------------------------------------------------------------------------------*/

    /*-------------------- 第二级译码逻辑：生成具体控制信号 --------------------*/
    // 操作类型alutype
   assign id_alutype_o [2] = (cpu_rst_n==`RST_ENABLE) ?1'b0:inst_sll; //?
   assign id_alutype_o [1] = (cpu_rst_n==`RST_ENABLE) ?1'b0:
   (inst_and | inst_mfhi | inst_mflo | inst_ori | inst_lui);
   assign id_alutype_o [0] =(cpu_rst_n==`RST_ENABLE) ?1'b0:
   (inst_add | inst_addu | inst_sub | inst_subu | inst_slt | inst_sltu | inst_mfhi | inst_mflo |
   inst_addiu| inst_addi| inst_sltiu | inst_slti |inst_lb | inst_lw |inst_sb |inst_sw);
 
   //内部操作码aluop  0001 0101
   assign id_aluop_o[7] = (cpu_rst_n==`RST_ENABLE) ?1'b0:(inst_lb | inst_lw |inst_sb | inst_sw); //访存指令 
   assign id_aluop_o[6] = 1'b0;
   assign id_aluop_o[5] = (cpu_rst_n==`RST_ENABLE) ?1'b0:(inst_slt | inst_sltu | inst_sltiu | inst_slti); //slt指令
   assign id_aluop_o[4] = (cpu_rst_n==`RST_ENABLE) ?1'b0:
   (inst_add | inst_addu | inst_addi | inst_sub | inst_subu | inst_and | inst_mult| inst_multu | inst_sll| inst_ori |inst_addiu| inst_lb | inst_lw | inst_sb | inst_sw);
   assign id_aluop_o[3] = (cpu_rst_n==`RST_ENABLE) ?1'b0:
   (inst_add | inst_addu | inst_subu | inst_and | inst_mfhi| inst_mflo | inst_ori| inst_addiu| inst_sb | inst_sw);
   assign id_aluop_o[2] =(cpu_rst_n==`RST_ENABLE) ?1'b0:
   (inst_slt | inst_sltu | inst_sub | inst_and | inst_mult | inst_multu | inst_mfhi| inst_mflo | inst_ori | inst_addi | inst_slti | inst_lui| inst_sltiu);
   assign id_aluop_o[1] =(cpu_rst_n==`RST_ENABLE) ?1'b 0:
   (inst_addu | inst_sub | inst_addi | inst_subu | inst_slt | inst_sltiu | inst_lw | inst_sw);
   assign id_aluop_o[0] =(cpu_rst_n==`RST_ENABLE) ?1'b0:
   (inst_subu | inst_sub | inst_sltu | inst_mflo | inst_sll | inst_ori | inst_lui | inst_addiu | inst_sltiu| inst_multu );
   
    // 写通用寄存器使能信号
    assign id_wreg_o  = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_add | inst_addu | inst_sub | inst_subu | inst_slt | inst_sltu | inst_and | inst_mfhi | inst_mflo | inst_sll |
    inst_ori | inst_lui | inst_addi| inst_addiu | inst_sltiu | inst_slti | inst_lb | inst_lw );
    
    //写HILO寄存器使能信号
    assign id_whilo_o =(cpu_rst_n == `RST_ENABLE) ? 1'b0 : inst_mult | inst_multu;
    //移位使能指令
    wire shift = inst_sll;
    //立即数使能信号
    wire immsel=inst_ori | inst_addi | inst_lui| inst_addiu | inst_sltiu | inst_slti | inst_lb | inst_lw| inst_sb | inst_sw;
    //目的寄存器选择信号
    wire rtsel = inst_ori | inst_lui | inst_addi | inst_addiu | inst_sltiu | inst_slti | inst_lb | inst_lw;
    //符号扩展使能信号
    wire sext = inst_addiu | inst_addi | inst_sltiu | inst_slti | inst_lb | inst_lw | inst_sb | inst_sw;
    //加载高半字使能信号
    wire upper=inst_lui;
    //存储器到寄存器使能信号
    assign id_mreg_o = (cpu_rst_n==`RST_ENABLE) ?1'b0:(inst_lb|inst_lw) ;
    //读通用寄存器堆端口1使能信号
    assign rreg1 = (cpu_rst_n==`RST_ENABLE) ?1'b0:
    (inst_add | inst_sub | inst_addu | inst_addi | inst_subu | inst_slt | inst_sltu | inst_and | inst_mult| inst_multu | inst_ori | inst_addiu | inst_sltiu | inst_slti | inst_lb | inst_lw | inst_sb | inst_sw);

 
//读通用寄存器堆读端口2使能信号
assign rreg2=(cpu_rst_n==`RST_ENABLE) ?1'b0:
(inst_add | inst_sub | inst_addu | inst_subu | inst_slt | inst_sltu | inst_and | inst_mult | inst_multu | inst_sll | inst_sb | inst_sw) ;
/*-------------------------------------------------------------------------------------*/

//读通用寄存器堆端口1的地址为rs字段，读端口2的地址为rt字段
assign ra1 =(cpu_rst_n==`RST_ENABLE) ?`ZERO_WORD:rs;
assign ra2 =(cpu_rst_n==`RST_ENABLE) ?`ZERO_WORD:rt;
//获得指令操作所需的立即数
wire[31:0] imm_ext = (cpu_rst_n==`RST_ENABLE) ?`ZERO_WORD:
                       (upper == `UPPER_ENABLE) ?(imm<<16) :
                       (sext == `SIGNED_EXT) ?{{16{imm[15]}},imm}:{{16{1'b0}},imm};
//获得待写入目的寄存器的地址(rt或rd)
assign id_wa_o=(cpu_rst_n==`RST_ENABLE) ?`ZERO_WORD:(rtsel==`RT_ENABLE  )?rt:rd;
//获得访存阶段要存入数据存储器的数据(来自通用寄存器堆读数据端口2)
assign id_din_o = (cpu_rst_n==`RST_ENABLE) ?`ZERO_WORD:rd2;

//获得源操作数1。如果shift信号有效， 则源操作数1为移位位数， 否则为从读通用寄存器堆端口1获行
assign id_src1_o = (cpu_rst_n==`RST_ENABLE) ?`ZERO_WORD:
                   (shift==`SHIFT_ENABLE) ?{27'b0, sa} :
                   (rreg1==`READ_ENABLE) ? rd1:`ZERO_WORD;
//获得源操作数2。如果imms el信号有效， 则源操作数1为立即数， 否则为从读通用寄存器堆端口2获
assign id_src2_o = (cpu_rst_n==`RST_ENABLE) ?`ZERO_WORD:
                   (immsel==`IMM_ENABLE) ?imm_ext:
                   (rreg2 == `READ_ENABLE) ?rd2:`ZERO_WORD;




endmodule
