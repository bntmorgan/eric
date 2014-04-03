module main();

/**
 * Top module signals
 */

// Inputs
reg [15:0] isize;
reg [1:0] op_size;
reg [3:0] op_op;
reg [63:0] op_o0;
reg [63:0] op_o1;
reg [63:0] op_o2;
reg [63:0] op_o3;
reg [2:0] op_s0;
reg [2:0] op_s1;
reg [2:0] op_s2;
reg [2:0] op_s3;
reg [4:0] op_idx0;
reg [4:0] op_idx1;
reg [4:0] op_idx2;
reg [4:0] op_idx3;
reg [63:0] hm_data;

// Outputs
wire [15:0] ip_incr;
wire ip_load;
wire [15:0] ip_data;
wire user_irq;
wire [63:0] user_data;
wire [4:0] w_idx;
wire [63:0] w_data;
wire [2:0] w_sel;
wire [2:0] w_r_sel;
wire [1:0] w_size;
wire we;
wire [63:0] hm_addr;
wire hm_start;

/**
 * Tested components
 */
mpu_execution exe (
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

initial begin
  isize <= 16'b0;
  op_size <= 2'b0;
  op_op <= 4'b0;
  op_o0 <= 64'b0;
  op_o1 <= 64'b0;
  op_o2 <= 64'b0;
  op_o3 <= 64'b0;
  op_s0 <= 3'b0;
  op_s1 <= 3'b0;
  op_s2 <= 3'b0;
  op_s3 <= 3'b0;
  op_idx0 <= 5'b0;
  op_idx1 <= 5'b0;
  op_idx2 <= 5'b0;
  op_idx3 <= 5'b0;
  hm_data <= 64'b0;
end

always @(*) begin
  $display("-");
  $display("isize %x", isize);
  $display("op_size %x", op_size);
  $display("op_op %x", op_op);
  $display("op_o0 %x", op_o0);
  $display("op_o1 %x", op_o1);
  $display("op_o2 %x", op_o2);
  $display("op_o3 %x", op_o3);
  $display("op_s0 %x", op_s0);
  $display("op_s1 %x", op_s1);
  $display("op_s2 %x", op_s2);
  $display("op_s3 %x", op_s3);
  $display("op_idx0 %x", op_idx0);
  $display("op_idx1 %x", op_idx1);
  $display("op_idx2 %x", op_idx2);
  $display("op_idx3 %x", op_idx3);
  $display("hm_data %x", hm_data);
  $display("ip_incr %x", ip_incr);
  $display("ip_load %x", ip_load);
  $display("ip_data %x", ip_data);
  $display("user_irq %x", user_irq);
  $display("user_data %x", user_data);
  $display("w_idx %x", w_idx);
  $display("w_data %x", w_data);
  $display("w_sel %x", w_sel);
  $display("w_r_sel %x", w_r_sel);
  $display("w_size %x", w_size);
  $display("we %x", we);
  $display("hm_addr %x", hm_addr);
  $display("hm_start %x", hm_start);
end

/**
 * Simulation
 */
initial begin
  # 8 $display("--- mask ff ff ff ffff");
  isize <= 16'h5;
  op_op <= 4'h1;
  op_o0[7:0] <= 8'hff;
  op_o1[7:0] <= 8'hff;
  op_o2[7:0] <= 8'hff;
  op_o3[15:0] <= 16'hffff;
  # 8 $display("--- mask ff ff f0 ffff");
  isize <= 16'h5;
  op_op <= 4'h1;
  op_o0[7:0] <= 8'hff;
  op_o1[7:0] <= 8'hff;
  op_o2[7:0] <= 8'hf0;
  op_o3[15:0] <= 16'hffff;
  # 8 $display("--- jmp ffff");
  isize <= 16'h2;
  op_op <= 4'hf;
  op_o0[15:0] <= 16'hffff;
  op_o1[7:0] <= 8'h00;
  op_o2[7:0] <= 8'h00;
  op_o3[15:0] <= 16'h0000;
  # 8 $display("--- load reg0:0 ffffffff");
  isize <= 16'h6;
  op_op <= 4'he;
  op_o0[15:0] <= 16'h0000;
  op_o1[31:0] <= 32'hffffffff;
  op_o2[7:0] <= 8'h00;
  op_o3[15:0] <= 16'h0000;
  # 8 $display("--- load reg0:1 ffffffff");
  isize <= 16'h6;
  op_op <= 4'he;
  op_o0[15:0] <= 16'h0000;
  op_s0 <= 3'b001;
  op_o1[31:0] <= 32'hffffffff;
  op_o2[7:0] <= 8'h00;
  op_o3[15:0] <= 16'h0000;
  # 8 $display("--- mload ff");
  isize <= 16'h2;
  op_op <= 4'hd;
  op_o0[7:0] <= 8'h00;
  op_s0 <= 3'b000;
  op_o1[31:0] <= 32'h000000ff;
  op_o2[7:0] <= 8'h00;
  op_o3[7:0] <= 8'h00;
  # 8 $finish();
end

endmodule
