module mpu_memory (
  // System
  input sys_clk,
  input sys_rst,

  // Memory read
  input [15:0] r_addr,
  output [47:0] r_data,

  // Memory write
  input we,
  input [15:0] w_addr,
  input [32:0] w_data
);

// Memory
reg [7:0] mem [128:0];

assign r_data = {mem[r_addr + 5], mem[r_addr + 4], mem[r_addr + 3], mem[r_addr
  + 2], mem[r_addr + 1], mem[r_addr + 0]};

integer d;
task init;
  begin
    for (d = 0; d < 128; d = d + 1) begin
      mem[d][7:0] = 8'b0;
    end
  end
endtask

reg [31:0] i;
initial i = 0;
task init_tests;
  begin
    for (i = 0; i < 128; i = i + 1) begin
      mem[i][7:0] <= 8'b0;
    end
    i = 0;
    // load
    $display("load @%x\n", i);
    mem[i + 0][7:0] <= {`MPU_OP_LOAD, 2'b00, 2'b00}; // OP
    mem[i + 1][7:0] <= 8'b00000_000; // reg0
    mem[i + 2][7:0] <= 8'hff      ; // imm
    i = i + 3;
    // load
    $display("load @%x\n", i);
    mem[i + 0][7:0] <= {`MPU_OP_LOAD, 2'b00, 2'b00}; // OP
    mem[i + 1][7:0] <= 8'b00001_000; // reg1
    mem[i + 2][7:0] <= 8'hff      ; // imm
    i = i + 3;
    // load
    $display("load @%x\n", i);
    mem[i + 0][7:0] <= {`MPU_OP_LOAD, 2'b00, 2'b00}; // OP
    mem[i + 1][7:0] <= 8'b00010_000; // reg2
    mem[i + 2][7:0] <= 8'hff      ; // imm
    i = i + 3;
    // load
    $display("load @%x\n", i);
    mem[i + 0][7:0] <= {`MPU_OP_LOAD, 2'b00, 2'b01}; // OP
    mem[i + 1][7:0] <= 8'b00011_000; // reg3
    mem[i + 2][7:0] <= 8'hff       ; // imm0
    mem[i + 3][7:0] <= 8'h00       ; // imm1
    i = i + 4;
    // load
    $display("load @%x\n", i);
    mem[i + 0][7:0] <= {`MPU_OP_LOAD, 2'b00, 2'b01}; // OP
    mem[i + 1][7:0] <= 8'b00100_000; // reg3
    mem[i + 2][7:0] <= 8'h00       ; // imm0
    mem[i + 3][7:0] <= 8'h00       ; // imm1
    i = i + 4;
    // Mask
    $display("Mask @%x\n", i);
    mem[i + 0][7:0] <= {`MPU_OP_MASK, 2'b00, 2'b00}; // OP
    mem[i + 1][7:0] <= 8'b00000_000; // reg0
    mem[i + 2][7:0] <= 8'b00001_000; // reg1
    mem[i + 3][7:0] <= 8'b00010_000; // reg2
    mem[i + 4][7:0] <= 8'b00011_000; // reg3
    i = i + 5;
    // User interrupt
    $display("Int @%x\n", i);
    mem[i + 0][7:0] <= {`MPU_OP_INT, 2'b00, 2'b11}; // OP
    mem[i + 1][7:0] <= 8'b00001_000; // reg1
    i = i + 2;
    // Jmp to the beginning
    $display("Jmp @%x\n", i);
    mem[i + 0][7:0] <= {`MPU_OP_JMP, 2'b00, 2'b00}; // OP
    mem[i + 1][7:0] <= 8'b00100_000; // reg4
    i = i + 2;
  end
endtask

initial begin
  // init();
  init_tests();
end

always @(posedge sys_clk) begin
  if (sys_rst) begin
    init_tests();
  end else begin
    if (we == 1'b1) begin
      mem[w_addr + 0] <= w_data[7 : 0];
      mem[w_addr + 1] <= w_data[15: 8];
      mem[w_addr + 2] <= w_data[23:16];
      mem[w_addr + 3] <= w_data[31:24];
    end
  end
end

endmodule
