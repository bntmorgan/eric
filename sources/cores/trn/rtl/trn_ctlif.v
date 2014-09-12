`include "trn.vh"

module trn_ctlif #(
	parameter csr_addr = 4'h0
) (
  // System
	input sys_clk,
	input sys_rst,

  // CSR
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

  input trn_clk,

  // status trn inputs
  input trn_lnk_up_n,

  // cfg ip core interface
  input [7:0] cfg_bus_number,
  input [4:0] cfg_device_number,
  input [2:0] cfg_function_number,
  input [15:0] cfg_command,
  input [15:0] cfg_dstatus,
  input [15:0] cfg_dcommand,
  input [15:0] cfg_lstatus,
  input [15:0] cfg_lcommand,
  input [15:0] cfg_dcommand2,

  // flow control ip core interface
  input [11:0] trn_fc_cpld,
  input [7:0] trn_fc_cplh,
  input [11:0] trn_fc_npd,
  input [7:0] trn_fc_nph,
  input [11:0] trn_fc_pd,
  input [7:0] trn_fc_ph,
  output [2:0] trn_fc_sel
);

// Synced wires

reg [2:0] sys__trn_fc_sel;
wire [2:0] trn__trn_fc_sel;
assign trn_fc_sel = trn__trn_fc_sel;

wire [31:0] sys__stat_trn;
wire [31:0] trn__stat_trn;

// trn stat
assign trn__stat_trn[31:0] = {
  31'b0,
  trn_lnk_up_n
};

/* CSR interface */
wire csr_selected = csr_a[13:10] == csr_addr;

task init;
begin
  sys__trn_fc_sel <= 3'b0;
end
endtask

initial begin 
  init;
end

/**
 * CSR logic
 */
always @(posedge sys_clk) begin
	if (sys_rst) begin
    init;
	end else begin
		csr_do <= 32'd0;
		if (csr_selected) begin
			case (csr_a[9:0])
        `TRN_CSR_STAT_TRN: csr_do <= sys__stat_trn;
        `TRN_CSR_CFG_PCI_ADDR: csr_do <= {16'b0, cfg_bus_number,
          cfg_device_number, cfg_function_number};
        `TRN_CSR_CFG_COMMAND: csr_do <= {16'b0, cfg_command};
        `TRN_CSR_CFG_DSTATUS: csr_do <= {16'b0, cfg_dstatus};
        `TRN_CSR_CFG_DCOMMAND: csr_do <= {16'b0, cfg_dcommand};
        `TRN_CSR_CFG_DCOMMAND2: csr_do <= {16'b0, cfg_dcommand2};
        `TRN_CSR_CFG_LSTATUS: csr_do <= {16'b0, cfg_lstatus};
        `TRN_CSR_CFG_LCOMMAND: csr_do <= {16'b0, cfg_lcommand};
        `TRN_CSR_TRN_FC_CPLD: csr_do <= {20'b0, trn_fc_cpld};
        `TRN_CSR_TRN_FC_CPLH: csr_do <= {24'b0, trn_fc_cplh};
        `TRN_CSR_TRN_FC_NPD: csr_do <= {20'b0, trn_fc_npd};
        `TRN_CSR_TRN_FC_NPH: csr_do <= {24'b0, trn_fc_nph};
        `TRN_CSR_TRN_FC_PD: csr_do <= {20'b0, trn_fc_pd};
        `TRN_CSR_TRN_FC_PH: csr_do <= {24'b0, trn_fc_ph};
        `TRN_CSR_TRN_FC_SEL: csr_do <= {29'b0, sys__trn_fc_sel};
			endcase
			if (csr_we) begin
				case (csr_a[9:0])
          `TRN_CSR_TRN_FC_SEL: begin
            sys__trn_fc_sel <= csr_di[2:0];
          end
        endcase
      end
    end
  end
end

/**
 * Sync
 */
trn_sync sync (
  .sys_clk(sys_clk),
  .trn_clk(trn_clk),
  .sys__trn_fc_sel(sys__trn_fc_sel),
  .trn__trn_fc_sel(trn__trn_fc_sel),
  .sys__stat_trn(sys__stat_trn),
  .trn__stat_trn(trn__stat_trn)
);

endmodule
