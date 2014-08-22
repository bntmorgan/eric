module mpu_mpu_to_ram (
  output [47:0] i_data_o,
  input [14:0] i_addr_i,

  output [11:0] ram_adr_0_o,
  output [11:0] ram_adr_1_o,
  output [11:0] ram_adr_2_o,
  output [11:0] ram_adr_3_o,
  output [11:0] ram_adr_4_o,
  output [11:0] ram_adr_5_o,
  output [11:0] ram_adr_6_o,
  output [11:0] ram_adr_7_o,

  input [7:0] ram_dat_0_i,
  input [7:0] ram_dat_1_i,
  input [7:0] ram_dat_2_i,
  input [7:0] ram_dat_3_i,
  input [7:0] ram_dat_4_i,
  input [7:0] ram_dat_5_i,
  input [7:0] ram_dat_6_i,
  input [7:0] ram_dat_7_i
);

wire [2:0] i_addr_mod8 = i_addr_i[2:0];

wire [11:0] ram_adr [7:0];
assign ram_adr_0_o = ram_adr[0];
assign ram_adr_1_o = ram_adr[1];
assign ram_adr_2_o = ram_adr[2];
assign ram_adr_3_o = ram_adr[3];
assign ram_adr_4_o = ram_adr[4];
assign ram_adr_5_o = ram_adr[5];
assign ram_adr_6_o = ram_adr[6];
assign ram_adr_7_o = ram_adr[7];

assign i_data_o = 
  (i_addr_mod8 == 0) ? {ram_dat_5_i, ram_dat_4_i, ram_dat_3_i, ram_dat_2_i,
    ram_dat_1_i, ram_dat_0_i} :
  (i_addr_mod8 == 1) ? {ram_dat_6_i, ram_dat_5_i, ram_dat_4_i, ram_dat_3_i,
    ram_dat_2_i, ram_dat_1_i} :
  (i_addr_mod8 == 2) ? {ram_dat_7_i, ram_dat_6_i, ram_dat_5_i, ram_dat_4_i,
    ram_dat_3_i, ram_dat_2_i} :
  (i_addr_mod8 == 3) ? {ram_dat_0_i, ram_dat_7_i, ram_dat_6_i, ram_dat_5_i,
    ram_dat_4_i, ram_dat_3_i} :
  (i_addr_mod8 == 4) ? {ram_dat_1_i, ram_dat_0_i, ram_dat_7_i, ram_dat_6_i,
    ram_dat_5_i, ram_dat_4_i} :
  (i_addr_mod8 == 5) ? {ram_dat_2_i, ram_dat_1_i, ram_dat_0_i, ram_dat_7_i,
    ram_dat_6_i, ram_dat_5_i} :
  (i_addr_mod8 == 6) ? {ram_dat_3_i, ram_dat_2_i, ram_dat_1_i, ram_dat_0_i,
    ram_dat_7_i, ram_dat_6_i} :
                       {ram_dat_4_i, ram_dat_3_i, ram_dat_2_i, ram_dat_1_i,
    ram_dat_0_i, ram_dat_7_i};

genvar ram_index;
generate for (ram_index=0; ram_index < 8; ram_index=ram_index+1) 
begin: gen_conv
  assign ram_adr[ram_index] = (i_addr_i + (7 - ram_index)) >> 3;  
end
endgenerate

// assign ram_adr[0] = (i_addr_i + 7) >> 3;
// assign ram_adr[1] = (i_addr_i + 6) >> 3;
// assign ram_adr[2] = (i_addr_i + 5) >> 3;
// assign ram_adr[3] = (i_addr_i + 4) >> 3;
// assign ram_adr[4] = (i_addr_i + 3) >> 3;
// assign ram_adr[5] = (i_addr_i + 2) >> 3;
// assign ram_adr[6] = (i_addr_i + 1) >> 3;
// assign ram_adr[7] = (i_addr_i    ) >> 3;

endmodule
