module checker_memory (
  // System
  input sys_clk,
  input sys_rst,
  input mpu_clk,

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
wire [31:0] wb_dat_i_le = {
  wb_dat_i[7:0],
  wb_dat_i[15:8], 
  wb_dat_i[23:16],
  wb_dat_i[31:24]
};
wire [3:0] wb_sel_i_le = {
  wb_sel_i[0],
  wb_sel_i[1],
  wb_sel_i[2],
  wb_sel_i[3]
};
//wire [31:0] wb_dat_i_le = {
//  wb_dat_i[31:24],
//  wb_dat_i[23:16],
//  wb_dat_i[15:8],
//  wb_dat_i[7:0]
//};
//wire [3:0] wb_sel_i_le = {
//  wb_sel_i[3],
//  wb_sel_i[2],
//  wb_sel_i[1],
//  wb_sel_i[0]
//};

// Wb to ram wires
wire [11:0] wb_ram_adr [7:0];
wire [31:0] wb_ram_dat_i [7:0];
wire [7:0] wb_ram_dat_o [7:0];
wire wb_ram_we [7:0];
wire [11:0] mpu_ram_adr [7:0];
wire [31:0] mpu_ram_dat_i [7:0];
wire [31:0] wb_dat;

/**
 * Converts 4 bytes double words adressing in a byte adresse ram made of RAMB36
 * Xilinx blocks wb_adr_i is 15 bits because 8 * 4096 is 2 ^ (3 + 12)
 */
checker_wb_to_ram conv_wb (
  .wb_adr_i(wb_adr_i[14:0]),
  .wb_dat_i(wb_dat_i_le),
  .wb_sel_i({4{wb_en & wb_we_i}} & wb_sel_i_le),
  .wb_dat_o(wb_dat),
  .ram_adr_0_o(wb_ram_adr[0]),
  .ram_adr_1_o(wb_ram_adr[1]),
  .ram_adr_2_o(wb_ram_adr[2]),
  .ram_adr_3_o(wb_ram_adr[3]),
  .ram_adr_4_o(wb_ram_adr[4]),
  .ram_adr_5_o(wb_ram_adr[5]),
  .ram_adr_6_o(wb_ram_adr[6]),
  .ram_adr_7_o(wb_ram_adr[7]),
  .ram_dat_0_o(wb_ram_dat_o[0]),
  .ram_dat_1_o(wb_ram_dat_o[1]),
  .ram_dat_2_o(wb_ram_dat_o[2]),
  .ram_dat_3_o(wb_ram_dat_o[3]),
  .ram_dat_4_o(wb_ram_dat_o[4]),
  .ram_dat_5_o(wb_ram_dat_o[5]),
  .ram_dat_6_o(wb_ram_dat_o[6]),
  .ram_dat_7_o(wb_ram_dat_o[7]),
  .ram_dat_0_i(wb_ram_dat_i[0][7:0]),
  .ram_dat_1_i(wb_ram_dat_i[1][7:0]),
  .ram_dat_2_i(wb_ram_dat_i[2][7:0]),
  .ram_dat_3_i(wb_ram_dat_i[3][7:0]),
  .ram_dat_4_i(wb_ram_dat_i[4][7:0]),
  .ram_dat_5_i(wb_ram_dat_i[5][7:0]),
  .ram_dat_6_i(wb_ram_dat_i[6][7:0]),
  .ram_dat_7_i(wb_ram_dat_i[7][7:0]),
  .ram_we_0_o(wb_ram_we[0]),
  .ram_we_1_o(wb_ram_we[1]),
  .ram_we_2_o(wb_ram_we[2]),
  .ram_we_3_o(wb_ram_we[3]),
  .ram_we_4_o(wb_ram_we[4]),
  .ram_we_5_o(wb_ram_we[5]),
  .ram_we_6_o(wb_ram_we[6]),
  .ram_we_7_o(wb_ram_we[7])
);

checker_mpu_to_ram conv_mpu (
  .i_data_o(mpu_do),
  .i_addr_i(mpu_addr[14:0]),
  .ram_adr_0_o(mpu_ram_adr[0]),
  .ram_adr_1_o(mpu_ram_adr[1]),
  .ram_adr_2_o(mpu_ram_adr[2]),
  .ram_adr_3_o(mpu_ram_adr[3]),
  .ram_adr_4_o(mpu_ram_adr[4]),
  .ram_adr_5_o(mpu_ram_adr[5]),
  .ram_adr_6_o(mpu_ram_adr[6]),
  .ram_adr_7_o(mpu_ram_adr[7]),
  .ram_dat_0_i(mpu_ram_dat_i[0][7:0]),
  .ram_dat_1_i(mpu_ram_dat_i[1][7:0]),
  .ram_dat_2_i(mpu_ram_dat_i[2][7:0]),
  .ram_dat_3_i(mpu_ram_dat_i[3][7:0]),
  .ram_dat_4_i(mpu_ram_dat_i[4][7:0]),
  .ram_dat_5_i(mpu_ram_dat_i[5][7:0]),
  .ram_dat_6_i(mpu_ram_dat_i[6][7:0]),
  .ram_dat_7_i(mpu_ram_dat_i[7][7:0])
);

// Generate the 8 RAMS
`ifndef SIMULATION
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
		.DIA({24'b0, wb_ram_dat_o[ram_index]}),
		.DIPA(4'h0),
		.DOA(wb_ram_dat_i[ram_index]),
		.ADDRA({1'b0, wb_ram_adr[ram_index], 3'b0}), 
		.WEA({3'b0, wb_ram_we[ram_index]}),
		.ENA(1'b1),
		/* No RSTA port */
		.CLKA(sys_clk),
		
		.DIB(32'b0),
		.DIPB(4'h0),
		.DOB(mpu_ram_dat_i[ram_index]),
		.ADDRB({1'b0, mpu_ram_adr[ram_index], 3'b0}), 
		.WEB(4'b0),
		.ENB(1'b1),
		/* No RSTB port */
		.CLKB(mpu_clk),

		.REGCEA(1'b0),
		.REGCEB(1'b0),
		
		.SSRA(1'b0),
		.SSRB(1'b0)
	);
end
endgenerate
`else
genvar ram_index;
generate for (ram_index=0; ram_index < 8; ram_index=ram_index+1) 
begin: gen_ram
  checker_memory_8 ram (
		.DIA({24'b0, wb_ram_dat_o[ram_index]}),
		.DOA(wb_ram_dat_i[ram_index]),
		.ADDRA({1'b0, wb_ram_adr[ram_index], 3'b0}), 
		.WEA({3'b0, wb_ram_we[ram_index]}),
		.CLKA(sys_clk),
		
		.DIB(32'b0),
		.DOB(mpu_ram_dat_i[ram_index]),
		.ADDRB({1'b0, mpu_ram_adr[ram_index], 3'b0}), 
		.WEB(4'b0),
		.CLKB(mpu_clk)
  );
end
endgenerate
`endif

always @(*) begin
  // Endianess convertion
  wb_dat_o = {
    wb_dat[7:0],
    wb_dat[15:8],
    wb_dat[23:16],
    wb_dat[31:24]
  };
//  wb_dat_o = {
//    wb_dat[31:24],
//    wb_dat[23:16],
//    wb_dat[15:8],
//    wb_dat[7:0]
//  };
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
