`define CHECKER_MEMORY_SIZE 65536

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

/**
 * Async read for mpu
 */
assign mpu_do = {mem[mpu_addr + 5], mem[mpu_addr + 4], mem[mpu_addr + 3],
  mem[mpu_addr + 2], mem[mpu_addr + 1], mem[mpu_addr + 0]};

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
// Gives the right bus width modulo 2 ^ 16
wire [15:0] addr = wb_adr_i[15:0];

// TODO test if byte adressing or double word !!!
always @(posedge sys_clk) begin
  if (sys_rst) begin
    init();
  end else begin
    // Write operations
    if (wb_we_i & wb_en) begin
      if (wb_sel_i_le[0]) begin
        mem[addr][7:0] <= wb_dat_i_le[ 7: 0];
      end
      if (wb_sel_i_le[1]) begin
        mem[addr + 1][7:0] <= wb_dat_i_le[15:8];
      end
      if (wb_sel_i_le[2]) begin
        mem[addr + 2][7:0] <= wb_dat_i_le[23:16];
      end
      if (wb_sel_i_le[3]) begin
        mem[addr + 3][7:0] <= wb_dat_i_le[31:24];
      end
    end
    // Read operations
    wb_dat_o_le[31:0] <= {mem[addr + 3], mem[addr + 2], mem[addr + 1],
      mem[addr + 0]};
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
    for (d = 0; d < `CHECKER_MEMORY_SIZE; d = d + 64) begin
      mem[d +  0][7:0] = 8'b0;
      mem[d +  1][7:0] = 8'b0;
      mem[d +  2][7:0] = 8'b0;
      mem[d +  3][7:0] = 8'b0;
      mem[d +  4][7:0] = 8'b0;
      mem[d +  5][7:0] = 8'b0;
      mem[d +  6][7:0] = 8'b0;
      mem[d +  7][7:0] = 8'b0;
      mem[d +  8][7:0] = 8'b0;
      mem[d +  9][7:0] = 8'b0;
      mem[d + 10][7:0] = 8'b0;
      mem[d + 11][7:0] = 8'b0;
      mem[d + 12][7:0] = 8'b0;
      mem[d + 13][7:0] = 8'b0;
      mem[d + 14][7:0] = 8'b0;
      mem[d + 15][7:0] = 8'b0;
      mem[d + 16][7:0] = 8'b0;
      mem[d + 17][7:0] = 8'b0;
      mem[d + 18][7:0] = 8'b0;
      mem[d + 19][7:0] = 8'b0;
      mem[d + 20][7:0] = 8'b0;
      mem[d + 21][7:0] = 8'b0;
      mem[d + 22][7:0] = 8'b0;
      mem[d + 23][7:0] = 8'b0;
      mem[d + 24][7:0] = 8'b0;
      mem[d + 25][7:0] = 8'b0;
      mem[d + 26][7:0] = 8'b0;
      mem[d + 27][7:0] = 8'b0;
      mem[d + 28][7:0] = 8'b0;
      mem[d + 29][7:0] = 8'b0;
      mem[d + 30][7:0] = 8'b0;
      mem[d + 31][7:0] = 8'b0;
      mem[d + 32][7:0] = 8'b0;
      mem[d + 33][7:0] = 8'b0;
      mem[d + 34][7:0] = 8'b0;
      mem[d + 35][7:0] = 8'b0;
      mem[d + 36][7:0] = 8'b0;
      mem[d + 37][7:0] = 8'b0;
      mem[d + 38][7:0] = 8'b0;
      mem[d + 39][7:0] = 8'b0;
      mem[d + 40][7:0] = 8'b0;
      mem[d + 41][7:0] = 8'b0;
      mem[d + 42][7:0] = 8'b0;
      mem[d + 43][7:0] = 8'b0;
      mem[d + 44][7:0] = 8'b0;
      mem[d + 45][7:0] = 8'b0;
      mem[d + 46][7:0] = 8'b0;
      mem[d + 47][7:0] = 8'b0;
      mem[d + 48][7:0] = 8'b0;
      mem[d + 49][7:0] = 8'b0;
      mem[d + 50][7:0] = 8'b0;
      mem[d + 51][7:0] = 8'b0;
      mem[d + 52][7:0] = 8'b0;
      mem[d + 53][7:0] = 8'b0;
      mem[d + 54][7:0] = 8'b0;
      mem[d + 55][7:0] = 8'b0;
      mem[d + 56][7:0] = 8'b0;
      mem[d + 57][7:0] = 8'b0;
      mem[d + 58][7:0] = 8'b0;
      mem[d + 59][7:0] = 8'b0;
      mem[d + 60][7:0] = 8'b0;
      mem[d + 61][7:0] = 8'b0;
      mem[d + 62][7:0] = 8'b0;
      mem[d + 63][7:0] = 8'b0;
    end
  end
endtask

endmodule
