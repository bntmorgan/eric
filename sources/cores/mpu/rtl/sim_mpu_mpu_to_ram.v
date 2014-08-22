`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs
reg [14:0] i_addr_i;
reg [7:0] ram_dat_0_i;
reg [7:0] ram_dat_1_i;
reg [7:0] ram_dat_2_i;
reg [7:0] ram_dat_3_i;
reg [7:0] ram_dat_4_i;
reg [7:0] ram_dat_5_i;
reg [7:0] ram_dat_6_i;
reg [7:0] ram_dat_7_i;

// Outputs

wire [47:0] i_data_o;
wire [11:0] ram_adr_0_o;
wire [11:0] ram_adr_1_o;
wire [11:0] ram_adr_2_o;
wire [11:0] ram_adr_3_o;
wire [11:0] ram_adr_4_o;
wire [11:0] ram_adr_5_o;
wire [11:0] ram_adr_6_o;
wire [11:0] ram_adr_7_o;

`include "sim.v"

/**
 * Tested components
 */
mpu_mpu_to_ram conv(
  .i_data_o(i_data_o),
  .i_addr_i(i_addr_i),
  .ram_adr_0_o(ram_adr_0_o),
  .ram_adr_1_o(ram_adr_1_o),
  .ram_adr_2_o(ram_adr_2_o),
  .ram_adr_3_o(ram_adr_3_o),
  .ram_adr_4_o(ram_adr_4_o),
  .ram_adr_5_o(ram_adr_5_o),
  .ram_adr_6_o(ram_adr_6_o),
  .ram_adr_7_o(ram_adr_7_o),
  .ram_dat_0_i(ram_dat_0_i),
  .ram_dat_1_i(ram_dat_1_i),
  .ram_dat_2_i(ram_dat_2_i),
  .ram_dat_3_i(ram_dat_3_i),
  .ram_dat_4_i(ram_dat_4_i),
  .ram_dat_5_i(ram_dat_5_i),
  .ram_dat_6_i(ram_dat_6_i),
  .ram_dat_7_i(ram_dat_7_i)
);


always @(*)
begin
  $display("-");
end

initial begin
  i_addr_i <= 15'b0;
  ram_dat_0_i <= 8'h00;
  ram_dat_1_i <= 8'h11;
  ram_dat_2_i <= 8'h22;
  ram_dat_3_i <= 8'h33;
  ram_dat_4_i <= 8'h44;
  ram_dat_5_i <= 8'h55;
  ram_dat_6_i <= 8'h66;
  ram_dat_7_i <= 8'h77;
end

/**
 * Simulation
 */
initial
begin
  i_addr_i <= 15'h00;
  waitnclock(4);
  i_addr_i <= 15'h01;
  waitnclock(4);
  i_addr_i <= 15'h02;
  waitnclock(4);
  i_addr_i <= 15'h03;
  waitnclock(4);
  i_addr_i <= 15'h04;
  waitnclock(4);
  i_addr_i <= 15'h05;
  waitnclock(4);
  i_addr_i <= 15'h06;
  waitnclock(4);
  i_addr_i <= 15'h07;
  waitnclock(4);
  $finish;
end

endmodule
