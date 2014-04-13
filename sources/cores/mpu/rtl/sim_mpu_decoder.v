module main();

/**
 * Top module signals
 */

// Inputs
reg [47:0] i;
wire [63:0] r_data0;
wire [63:0] r_data1;
wire [63:0] r_data2;
wire [63:0] r_data3;

// Outputs
wire [15:0] isize;
wire error;
wire [1:0] op_size;
wire [3:0] op_op;
wire [63:0] op_o0;
wire [63:0] op_o1;
wire [63:0] op_o2;
wire [63:0] op_o3;
wire [4:0] op_idx0;
wire [4:0] op_idx1;
wire [4:0] op_idx2;
wire [4:0] op_idx3;
wire [2:0] op_s0;
wire [2:0] op_s1;
wire [2:0] op_s2;
wire [2:0] op_s3;

// FakeMemory
assign r_data0[63:0] = {
  8'haa,
  8'haa,
  8'haa,
  8'haa,
  8'haa,
  8'haa,
  8'haa,
  8'haa
};

assign r_data1[63:0] = {
  8'hbb,
  8'hbb,
  8'hbb,
  8'hbb,
  8'hbb,
  8'hbb,
  8'hbb,
  8'hbb
};

assign r_data2[63:0] = {
  8'hcc,
  8'hcc,
  8'hcc,
  8'hcc,
  8'hcc,
  8'hcc,
  8'hcc,
  8'hcc
};

assign r_data3[63:0] = {
  8'hdd,
  8'hdd,
  8'hdd,
  8'hdd,
  8'hdd,
  8'hdd,
  8'hdd,
  8'hdd
};

/**
 * Tested components
 */
mpu_decoder decoder (
  .i(i),
  .r_data0(r_data0),
  .r_data1(r_data1),
  .r_data2(r_data2),
  .r_data3(r_data3),
  .isize(isize),
  .error(error),
  .op_size(op_size),
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
  .op_s3(op_s3)
);

initial begin
  i <= 80'b0;
end

always @(*) begin
  $display("-");
  $display("i %b_%b_%b_%b_%b_%b", i[47:40], i[39:32], i[31:24], i[23:16], i[15:8], i[7:0]);
  $display("r_data0 0x%x", r_data0);
  $display("r_data1 0x%x", r_data1);
  $display("r_data2 0x%x", r_data2);
  $display("isize 0x%x", isize);
  $display("error 0x%x", error);
  $display("op_size 0x%x", op_size);
  $display("op_op 0x%x", op_op);
  $display("op_o0 0x%x", op_o0);
  $display("op_o1 0x%x", op_o1);
  $display("op_o2 0x%x", op_o2);
  $display("op_o3 0x%x", op_o3);
  $display("r_idx0 0x%x", op_idx0);
  $display("r_idx1 0x%x", op_idx1);
  $display("r_idx2 0x%x", op_idx2);
  $display("r_idx3 0x%x", op_idx3);
  $display("op_s0 0x%x", op_s0);
  $display("op_s1 0x%x", op_s1);
  $display("op_s2 0x%x", op_s2);
  $display("op_s3 0x%x", op_s3);
end

`define OP_MASK 4'h1
`define OP_CMP 4'h2
`define OP_LT 4'h3
`define OP_MLOAD 4'hd
`define OP_LOAD 4'he
`define OP_JMP 4'hf

/**
 * Simulation
 */
initial begin
  # 2 $display("--- mask[01] reg mask0 mask1 (8-bit)");
  i[47:0] <= {8'h00, 8'hb00011_000, 8'b00000_000, 8'b00001_001, 8'b00010_010, `OP_MASK, 2'b00,
    2'b01};
//   # 2 $display("--- cmp reg0 reg1 m (8-bit)");
//   i[47:0] <= {8'h00, 8'hb00011_000, 8'b00000_000, 8'b00001_001, 8'b00010_010, `OP_CMP, 2'b00,
//     2'b01};
//   # 2 $display("--- lt reg0 reg1 (8-bit)");
//   i[47:0] <= {16'h0000, 8'hb00011_000, 8'b00001_001, 8'b00010_010, `OP_LT, 2'b00,
//     2'b01};
//   # 2 $display("--- mload reg (8-bit)");
//   i[47:0] <= {32'h00000000, 8'b00001_000, `OP_MLOAD, 2'b00, 2'b01};
//   # 2 $display("--- load reg imm8 (8-bit)");
//   i[47:0] <= {24'h000000, 8'hff, 8'b00001_010, `OP_LOAD, 2'b00, 2'b01};
//   # 2 $display("--- jmp addr");
//   i[47:0] <= {32'h000000,8'h00011_000, `OP_JMP, 2'b00, 2'b10};
  # 2 $finish();
end

endmodule
