module checker_memory (
  // System
  input sys_clk,
  input sys_rst,

  // MPU bus
  input [15:0] mpu_addr,
  output [47:0] mpu_do,

  // Wishbone bus
	input [31:0] wb_adr_i,
	output reg [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	input wb_we_i
);

wire wb_en = wb_cyc_i & wb_stb_i;

// Wb to ram wires
wire [15:0] ram_adr [7:0];
wire [31:0] ram_dat_i [7:0];
wire [7:0] ram_dat_o [7:0];
wire [3:0] ram_we [7:0];
wire [31:0] wb_dat;

/**
 * Converts 4 bytes double words adressing in a quad word adressed ram
 * wb_adr_i is 15 bits because 8 * 4096 is 2 ^ (3 + 12)
 */
checker_wb_to_ram conv(
  .wb_adr_i(wb_adr_i[14:0]),
  .wb_dat_i(wb_dat_i),
  .wb_sel_i({4{wb_en & wb_we_i}} & wb_sel_i),
  .wb_dat_o(wb_dat),
  .ram_adr_0_o(ram_adr[0][14:3]),
  .ram_adr_1_o(ram_adr[1][14:3]),
  .ram_adr_2_o(ram_adr[2][14:3]),
  .ram_adr_3_o(ram_adr[3][14:3]),
  .ram_adr_4_o(ram_adr[4][14:3]),
  .ram_adr_5_o(ram_adr[5][14:3]),
  .ram_adr_6_o(ram_adr[6][14:3]),
  .ram_adr_7_o(ram_adr[7][14:3]),
  .ram_dat_0_o(ram_dat_o[0]),
  .ram_dat_1_o(ram_dat_o[1]),
  .ram_dat_2_o(ram_dat_o[2]),
  .ram_dat_3_o(ram_dat_o[3]),
  .ram_dat_4_o(ram_dat_o[4]),
  .ram_dat_5_o(ram_dat_o[5]),
  .ram_dat_6_o(ram_dat_o[6]),
  .ram_dat_7_o(ram_dat_o[7]),
  .ram_dat_0_i(ram_dat_i[0][7:0]),
  .ram_dat_1_i(ram_dat_i[1][7:0]),
  .ram_dat_2_i(ram_dat_i[2][7:0]),
  .ram_dat_3_i(ram_dat_i[3][7:0]),
  .ram_dat_4_i(ram_dat_i[4][7:0]),
  .ram_dat_5_i(ram_dat_i[5][7:0]),
  .ram_dat_6_i(ram_dat_i[6][7:0]),
  .ram_dat_7_i(ram_dat_i[7][7:0]),
  .ram_we_0_o(ram_we[0][0]),
  .ram_we_1_o(ram_we[1][0]),
  .ram_we_2_o(ram_we[2][0]),
  .ram_we_3_o(ram_we[3][0]),
  .ram_we_4_o(ram_we[4][0]),
  .ram_we_5_o(ram_we[5][0]),
  .ram_we_6_o(ram_we[6][0]),
  .ram_we_7_o(ram_we[7][0])
);

// Generate the 8 RAMS
genvar ram_index;
generate for (ram_index=0; ram_index < 8; ram_index=ram_index+1) 
begin: gen_ram
	RAMB36 #(
		.WRITE_WIDTH_A(9),
		.READ_WIDTH_A(9),
		.WRITE_WIDTH_B(9),
		.READ_WIDTH_B(9),
		.DOA_REG(0),
		.DOB_REG(0),
		.SIM_MODE("SAFE"),
		.INIT_A(9'h000),
		.INIT_B(9'h000),
		.WRITE_MODE_A("WRITE_FIRST"),
		.WRITE_MODE_B("WRITE_FIRST")
	) ram (
		.DIA({24'b0, ram_dat_o[ram_index]}),
		.DIPA(4'h0),
		.DOA(ram_dat_i[ram_index]),
		.ADDRA({1'b0, ram_adr[ram_index][14:3], 3'b0}), 
		.WEA({3'b0, ram_we[ram_index][0]}),
		.ENA(1'b1),
		/* No RSTA port */
		.CLKA(sys_clk),
		
		.DIB(9'b0),
		.DIPB(1'h0),
		.DOB(),
		.ADDRB(15'b0),
		.WEB(1'b0),
		.ENB(1'b0),
		/* No RSTB port */
		.CLKB(sys_clk),

		.REGCEA(1'b0),
		.REGCEB(1'b0),
		
		.SSRA(1'b0),
		.SSRB(1'b0)
	);
end
endgenerate

always @(*) begin
  wb_dat_o = wb_dat;
end

always @(posedge sys_clk) begin
	if(sys_rst)
		wb_ack_o <= 1'b0;
	else begin
		wb_ack_o <= 1'b0;
		if(wb_en & ~wb_ack_o)
			wb_ack_o <= 1'b1;
	end
end

endmodule
