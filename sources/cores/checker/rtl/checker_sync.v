module checker_sync (
  input sys_clk,
  input mpu_clk,
  input trn_clk,

  input [7:0] trn__cfg_bus_number,
  output reg [7:0] sys__cfg_bus_number,

  input [4:0] trn__cfg_device_number,
  output reg [4:0] sys__cfg_device_number,

  input [2:0] trn__cfg_function_number,
  output reg [2:0] sys__cfg_function_number,

  input [15:0] trn__cfg_command,
  output reg [15:0] sys__cfg_command,

  input [15:0] trn__cfg_dstatus,
  output reg [15:0] sys__cfg_dstatus,

  input [15:0] trn__cfg_dcommand,
  output reg [15:0] sys__cfg_dcommand,

  input [15:0] trn__cfg_lstatus,
  output reg [15:0] sys__cfg_lstatus,

  input [15:0] trn__cfg_lcommand,
  output reg [15:0] sys__cfg_lcommand,

  input [15:0] trn__cfg_dcommand2,
  output reg [15:0] sys__cfg_dcommand2,

  input [11:0] trn__trn_fc_cpld,
  output reg [11:0] sys__trn_fc_cpld,

  input [7:0] trn__trn_fc_cplh,
  output reg [7:0] sys__trn_fc_cplh,

  input [11:0] trn__trn_fc_npd,
  output reg [11:0] sys__trn_fc_npd,

  input [7:0] trn__trn_fc_nph,
  output reg [7:0] sys__trn_fc_nph,

  input [11:0] trn__trn_fc_pd,
  output reg [11:0] sys__trn_fc_pd,

  input [7:0] trn__trn_fc_ph,
  output reg [7:0] sys__trn_fc_ph,

  input sys__mode_ack,
  output mpu__mode_ack,

  input sys__sys_rst,
  output mpu__sys_rst
);

reg [7:0] trn__trn_fc_ph_r;
always @(posedge sys_clk) begin 
	trn__trn_fc_ph_r <= trn__trn_fc_ph;
	sys__trn_fc_ph <= trn__trn_fc_ph_r;
end

reg [7:0] trn__trn_fc_pd_r;
always @(posedge sys_clk) begin 
	trn__trn_fc_pd_r <= trn__trn_fc_pd;
	sys__trn_fc_pd <= trn__trn_fc_pd_r;
end

reg [7:0] trn__trn_fc_nph_r;
always @(posedge sys_clk) begin 
	trn__trn_fc_nph_r <= trn__trn_fc_nph;
	sys__trn_fc_nph <= trn__trn_fc_nph_r;
end

reg [7:0] trn__trn_fc_npd_r;
always @(posedge sys_clk) begin 
	trn__trn_fc_npd_r <= trn__trn_fc_npd;
	sys__trn_fc_npd <= trn__trn_fc_npd_r;
end

reg [7:0] trn__trn_fc_cplh_r;
always @(posedge sys_clk) begin 
	trn__trn_fc_cplh_r <= trn__trn_fc_cplh;
	sys__trn_fc_cplh <= trn__trn_fc_cplh_r;
end

reg [7:0] trn__trn_fc_cpld_r;
always @(posedge sys_clk) begin 
	trn__trn_fc_cpld_r <= trn__trn_fc_cpld;
	sys__trn_fc_cpld <= trn__trn_fc_cpld_r;
end

reg [7:0] trn__cfg_bus_number_r;
always @(posedge sys_clk) begin 
	trn__cfg_bus_number_r <= trn__cfg_bus_number;
	sys__cfg_bus_number <= trn__cfg_bus_number_r;
end

reg [4:0] trn__cfg_device_number_r;
always @(posedge sys_clk) begin 
	trn__cfg_device_number_r <= trn__cfg_device_number;
	sys__cfg_device_number <= trn__cfg_device_number_r;
end

reg [2:0] trn__cfg_function_number_r;
always @(posedge sys_clk) begin 
	trn__cfg_function_number_r <= trn__cfg_function_number;
	sys__cfg_function_number <= trn__cfg_function_number_r;
end

reg [15:0] trn__cfg_command_r;
always @(posedge sys_clk) begin 
	trn__cfg_command_r <= trn__cfg_command;
	sys__cfg_command <= trn__cfg_command_r;
end

reg [15:0] trn__cfg_dstatus_r;
always @(posedge sys_clk) begin 
	trn__cfg_dstatus_r <= trn__cfg_dstatus;
	sys__cfg_dstatus <= trn__cfg_dstatus_r;
end

reg [15:0] trn__cfg_dcommand_r;
always @(posedge sys_clk) begin 
	trn__cfg_dcommand_r <= trn__cfg_dcommand;
	sys__cfg_dcommand <= trn__cfg_dcommand_r;
end

reg [15:0] trn__cfg_lstatus_r;
always @(posedge sys_clk) begin 
	trn__cfg_lstatus_r <= trn__cfg_lstatus;
	sys__cfg_lstatus <= trn__cfg_lstatus_r;
end

reg [15:0] trn__cfg_lcommand_r;
always @(posedge sys_clk) begin 
	trn__cfg_lcommand_r <= trn__cfg_lcommand;
	sys__cfg_lcommand <= trn__cfg_lcommand_r;
end

reg [15:0] trn__cfg_dcommand2_r;
always @(posedge sys_clk) begin 
	trn__cfg_dcommand2_r <= trn__cfg_dcommand2;
	sys__cfg_dcommand2 <= trn__cfg_dcommand2_r;
end

checker_psync ps_mode_ack (
  .clk1(sys_clk),
  .i(mode_ack),
  .clk2(mpu_clk),
  .o(mode_ack_2)
);

checker_psync ps_sys_rst (
  .clk1(sys_clk),
  .i(sys_rst),
  .clk2(mpu_clk),
  .o(sys_rst_2)
);

endmodule
