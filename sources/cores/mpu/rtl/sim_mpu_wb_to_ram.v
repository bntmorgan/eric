`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs

reg [7:0] ram_dat_0_i;
reg [7:0] ram_dat_1_i;
reg [7:0] ram_dat_2_i;
reg [7:0] ram_dat_3_i;
reg [7:0] ram_dat_4_i;
reg [7:0] ram_dat_5_i;
reg [7:0] ram_dat_6_i;
reg [7:0] ram_dat_7_i;

// Outputs

wire [11:0] ram_adr_0_o;
wire [11:0] ram_adr_1_o;
wire [11:0] ram_adr_2_o;
wire [11:0] ram_adr_3_o;
wire [11:0] ram_adr_4_o;
wire [11:0] ram_adr_5_o;
wire [11:0] ram_adr_6_o;
wire [11:0] ram_adr_7_o;
wire [7:0] ram_dat_0_o;
wire [7:0] ram_dat_1_o;
wire [7:0] ram_dat_2_o;
wire [7:0] ram_dat_3_o;
wire [7:0] ram_dat_4_o;
wire [7:0] ram_dat_5_o;
wire [7:0] ram_dat_6_o;
wire [7:0] ram_dat_7_o;
wire ram_we_0_o;
wire ram_we_1_o;
wire ram_we_2_o;
wire ram_we_3_o;
wire ram_we_4_o;
wire ram_we_5_o;
wire ram_we_6_o;
wire ram_we_7_o;

`include "sim.v"
`include "sim_wb.v"

/**
 * Tested components
 */
mpu_wb_to_ram conv(
  .wb_adr_i(wb_adr_i[14:0]),
  .wb_dat_i(wb_dat_i),
  .wb_sel_i(wb_sel_i),
  .wb_dat_o(wb_dat_o),
  .ram_adr_0_o(ram_adr_0_o),
  .ram_adr_1_o(ram_adr_1_o),
  .ram_adr_2_o(ram_adr_2_o),
  .ram_adr_3_o(ram_adr_3_o),
  .ram_adr_4_o(ram_adr_4_o),
  .ram_adr_5_o(ram_adr_5_o),
  .ram_adr_6_o(ram_adr_6_o),
  .ram_adr_7_o(ram_adr_7_o),
  .ram_dat_0_o(ram_dat_0_o),
  .ram_dat_1_o(ram_dat_1_o),
  .ram_dat_2_o(ram_dat_2_o),
  .ram_dat_3_o(ram_dat_3_o),
  .ram_dat_4_o(ram_dat_4_o),
  .ram_dat_5_o(ram_dat_5_o),
  .ram_dat_6_o(ram_dat_6_o),
  .ram_dat_7_o(ram_dat_7_o),
  .ram_dat_0_i(ram_dat_0_i),
  .ram_dat_1_i(ram_dat_1_i),
  .ram_dat_2_i(ram_dat_2_i),
  .ram_dat_3_i(ram_dat_3_i),
  .ram_dat_4_i(ram_dat_4_i),
  .ram_dat_5_i(ram_dat_5_i),
  .ram_dat_6_i(ram_dat_6_i),
  .ram_dat_7_i(ram_dat_7_i),
  .ram_we_0_o(ram_we_0_o),
  .ram_we_1_o(ram_we_1_o),
  .ram_we_2_o(ram_we_2_o),
  .ram_we_3_o(ram_we_3_o),
  .ram_we_4_o(ram_we_4_o),
  .ram_we_5_o(ram_we_5_o),
  .ram_we_6_o(ram_we_6_o),
  .ram_we_7_o(ram_we_7_o)
);


always @(*)
begin
  $display("-");
end

initial begin
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
  waitnclock(4);
  wb_dat_i <= 32'h11223344;
  wb_sel_i <= 4'b1111;
  waitnclock(4);
  wb_adr_i <= 32'h00000004;
  waitnclock(4);
  wb_adr_i <= 32'h00000008;
  waitnclock(4);
  wb_adr_i <= 32'h0000000c;
  waitnclock(4);
  wb_adr_i <= 32'h00000010;
  $finish;
end

endmodule
