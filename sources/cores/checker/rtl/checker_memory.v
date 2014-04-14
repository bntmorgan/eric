`define CHECKER_MEMORY_SIZE 1024

module checker_memory (
  // System
  input sys_clk,
  input sys_rst,

  // MPU bus
  input [15:0] mpu_addr,
  output [47:0] mpu_do,

  // Wishbone bus
	input [31:0] wb_adr_i,
	output [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	input wb_we_i
);

/**
 * Memory
 */
reg [7:0] mem [`CHECKER_MEMORY_SIZE:0];
// Gives the right bus width modulo CHECKER_MEMORY_SIZE
wire [9:0] wb_addr_s = wb_adr_i[9:0];
wire [9:0] mpu_addr_s = mpu_addr[9:0];

/**
 * Async read for mpu
 */
assign mpu_do = {mem[mpu_addr_s + 5], mem[mpu_addr_s + 4], mem[mpu_addr_s + 3],
  mem[mpu_addr_s + 2], mem[mpu_addr_s + 1], mem[mpu_addr_s + 0]};

/**
 * Wishbone
 */
wire wb_en = wb_cyc_i & wb_stb_i;
// Endianess convertion
wire [31:0] wb_dat_i_le = {wb_dat_i[7:0], wb_dat_i[15:8], wb_dat_i[23:16],
  wb_dat_i[31:24]};
assign wb_dat_o = {wb_dat_o_le[7:0], wb_dat_o_le[15:8], wb_dat_o_le[23:16],
  wb_dat_o_le[31:24]};
wire [3:0] wb_sel_i_le = {wb_sel_i[0], wb_sel_i[1], wb_sel_i[2], wb_sel_i[3]};
reg [31:0] wb_dat_o_le;

// TODO test if byte adressing or double word !!!
always @(posedge sys_clk) begin
  if (sys_rst) begin
    init();
  end else begin
    // Write operations
    if (wb_we_i & wb_en) begin
      if (wb_sel_i_le[0]) begin
        mem[wb_addr_s + 0][7:0] <= wb_dat_i_le[07:00];
      end
      if (wb_sel_i_le[1]) begin
        mem[wb_addr_s + 1][7:0] <= wb_dat_i_le[15:08];
      end
      if (wb_sel_i_le[2]) begin
        mem[wb_addr_s + 2][7:0] <= wb_dat_i_le[23:16];
      end
      if (wb_sel_i_le[3]) begin
        mem[wb_addr_s + 3][7:0] <= wb_dat_i_le[31:24];
      end
    end
    // Read operations
    wb_dat_o_le[31:0] <= {mem[wb_addr_s + 3], mem[wb_addr_s + 2], mem[wb_addr_s + 1],
      mem[wb_addr_s + 0]};
  end
end

// Ack signal one clock after every wb cycle begin
always @(posedge sys_clk) begin
	if(sys_rst)
		wb_ack_o <= 1'b0;
	else begin
		wb_ack_o <= 1'b0;
		if(wb_en & ~wb_ack_o)
			wb_ack_o <= 1'b1;
	end
end

// Memory initialization
initial begin
  init();
  wb_dat_o_le[31:0] <= 32'b0;
end

integer d;
task init;
  begin
    for (d = 0; d < `CHECKER_MEMORY_SIZE; d = d + 1) begin
      mem[d][7:0] <= 8'b0;
    end
  end
endtask

endmodule
