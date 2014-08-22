module mpu_wb_to_ram (
  input [14:0] wb_adr_i,
  input [31:0] wb_dat_i,
  input [3:0] wb_sel_i, // !!! Here wb_sel_i <= wb_en & wb_we_i & wb_sel_i
  output [31:0] wb_dat_o,
  
  output [11:0] ram_adr_0_o,
  output [11:0] ram_adr_1_o,
  output [11:0] ram_adr_2_o,
  output [11:0] ram_adr_3_o,
  output [11:0] ram_adr_4_o,
  output [11:0] ram_adr_5_o,
  output [11:0] ram_adr_6_o,
  output [11:0] ram_adr_7_o,

  output [7:0] ram_dat_0_o,
  output [7:0] ram_dat_1_o,
  output [7:0] ram_dat_2_o,
  output [7:0] ram_dat_3_o,
  output [7:0] ram_dat_4_o,
  output [7:0] ram_dat_5_o,
  output [7:0] ram_dat_6_o,
  output [7:0] ram_dat_7_o,

  input [7:0] ram_dat_0_i,
  input [7:0] ram_dat_1_i,
  input [7:0] ram_dat_2_i,
  input [7:0] ram_dat_3_i,
  input [7:0] ram_dat_4_i,
  input [7:0] ram_dat_5_i,
  input [7:0] ram_dat_6_i,
  input [7:0] ram_dat_7_i,

  output ram_we_0_o,
  output ram_we_1_o,
  output ram_we_2_o,
  output ram_we_3_o,
  output ram_we_4_o,
  output ram_we_5_o,
  output ram_we_6_o,
  output ram_we_7_o
);

wire [11:0] wb_adr_i_4 = wb_adr_i[14:2];
wire adr_mod_2 = ((wb_adr_i_4) % 2);
wire adr_4_mod_2 = ((wb_adr_i_4 + 1) % 2);

// Addresses

assign ram_adr_0_o = (wb_adr_i_4 + 1) >> 1;
assign ram_adr_1_o = (wb_adr_i_4 + 1) >> 1;
assign ram_adr_2_o = (wb_adr_i_4 + 1) >> 1;
assign ram_adr_3_o = (wb_adr_i_4 + 1) >> 1;

assign ram_adr_4_o = (wb_adr_i_4    ) >> 1;
assign ram_adr_5_o = (wb_adr_i_4    ) >> 1;
assign ram_adr_6_o = (wb_adr_i_4    ) >> 1;
assign ram_adr_7_o = (wb_adr_i_4    ) >> 1;

// Write enable

assign ram_we_0_o = adr_4_mod_2 & wb_sel_i[0];
assign ram_we_1_o = adr_4_mod_2 & wb_sel_i[1];
assign ram_we_2_o = adr_4_mod_2 & wb_sel_i[2];
assign ram_we_3_o = adr_4_mod_2 & wb_sel_i[3];

assign ram_we_4_o = adr_mod_2 & wb_sel_i[0];
assign ram_we_5_o = adr_mod_2 & wb_sel_i[1];
assign ram_we_6_o = adr_mod_2 & wb_sel_i[2];
assign ram_we_7_o = adr_mod_2 & wb_sel_i[3];

// Wb to ram

assign ram_dat_0_o = wb_dat_i[ 7: 0];
assign ram_dat_1_o = wb_dat_i[15: 8];
assign ram_dat_2_o = wb_dat_i[23:16];
assign ram_dat_3_o = wb_dat_i[31:24];

assign ram_dat_4_o = wb_dat_i[ 7: 0];
assign ram_dat_5_o = wb_dat_i[15: 8];
assign ram_dat_6_o = wb_dat_i[23:16];
assign ram_dat_7_o = wb_dat_i[31:24];

// Ram to wb

assign wb_dat_o[ 7: 0] = (~adr_mod_2) ? ram_dat_0_i : ram_dat_4_i;
assign wb_dat_o[15: 8] = (~adr_mod_2) ? ram_dat_1_i : ram_dat_5_i;
assign wb_dat_o[23:16] = (~adr_mod_2) ? ram_dat_2_i : ram_dat_6_i;
assign wb_dat_o[31:24] = (~adr_mod_2) ? ram_dat_3_i : ram_dat_7_i;

endmodule
