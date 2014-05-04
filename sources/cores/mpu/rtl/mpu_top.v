module mpu_top (
  // System
  input sys_clk,
  input sys_rst,
  input en,

  // Instruction bus, synchronous memory for instructions
  output [15:0] i_addr,
  input [47:0] i_data,

  // Mpu user interruptions
  output user_irq,
  output [63:0] user_data,
  
  // Data bus Memory to check, clock might be async so we acknoledge the data
  // receive
  output [63:0] hm_addr,
  output hm_start,
  input [63:0] hm_data,

  // Error
  output error
);

// Interconnection wires
wire [15:0] ip_incr;
wire [15:0] ip_data;
wire ip_load;

wire [1:0] op_size;
wire [3:0] op_op;
wire [63:0] op_o0;
wire [63:0] op_o1;
wire [63:0] op_o2;
wire [63:0] op_o3;
wire [2:0] op_s0;
wire [2:0] op_s1;
wire [2:0] op_s2;
wire [2:0] op_s3;
wire [4:0] op_idx0;
wire [4:0] op_idx1;
wire [4:0] op_idx2;
wire [4:0] op_idx3;
wire [15:0] isize;
wire [63:0] r_data0;
wire [63:0] r_data1;
wire [63:0] r_data2;
wire [63:0] r_data3;

wire [4:0] w_idx;
wire [63:0] w_data;
wire [2:0] w_sel;
wire [2:0] w_r_sel;
wire [1:0] w_size;
wire we;

mpu_counter ip (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .out(i_addr),
  .en(en),
  .incr(ip_incr[15:0]),
  .data(ip_data[15:0]),
  .load(ip_load)
);

// Decoder
mpu_decoder decoder (
  .i(i_data),
  .isize(isize),
  .op_size(op_size),
  .r_data0(r_data0),
  .r_data1(r_data1),
  .r_data2(r_data2),
  .r_data3(r_data3),
  .op_op(op_op),
  .op_o0(op_o0),
  .op_o1(op_o1),
  .op_o2(op_o2),
  .op_o3(op_o3),
  .op_idx0(op_idx0),
  .op_idx1(op_idx1),
  .op_idx2(op_idx2),
  .op_idx3(op_idx3),
  .op_s0(op_s0),
  .op_s1(op_s1),
  .op_s2(op_s2),
  .op_s3(op_s3),
  .error(error)
);

// Execution
mpu_execution execution (
  .isize(isize),
  .op_size(op_size),
  .op_op(op_op),
  .op_o0(op_o0),
  .op_o1(op_o1),
  .op_o2(op_o2),
  .op_o3(op_o3),
  .op_s0(op_s0),
  .op_s1(op_s1),
  .op_s2(op_s2),
  .op_s3(op_s3),
  .op_idx0(op_idx0),
  .op_idx1(op_idx1),
  .op_idx2(op_idx2),
  .op_idx3(op_idx3),
  .ip_incr(ip_incr),
  .ip_load(ip_load),
  .ip_data(ip_data),
  .user_irq(user_irq),
  .user_data(user_data),
  .w_idx(w_idx),
  .w_data(w_data),
  .w_sel(w_sel),
  .w_r_sel(w_r_sel),
  .w_size(w_size),
  .we(we),
  .hm_addr(hm_addr),
  .hm_start(hm_start),
  .hm_data(hm_data)
);

// Registers
mpu_registers registers (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .en(en),
  .r_idx0(op_idx0[4:0]),
  .r_idx1(op_idx1[4:0]),
  .r_idx2(op_idx2[4:0]),
  .r_idx3(op_idx3[4:0]),
  .r_data0(r_data0),
  .r_data1(r_data1),
  .r_data2(r_data2),
  .r_data3(r_data3),
  .w_idx(w_idx),
  .w_data(w_data),
  .w_sel(w_sel),
  .w_r_sel(w_r_sel),
  .w_size(w_size),
  .we(we)
);

endmodule
