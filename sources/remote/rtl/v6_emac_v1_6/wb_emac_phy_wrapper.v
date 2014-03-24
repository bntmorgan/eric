/*
 * Milkymist SoC
 * Copyright (C) 2013 Fernand Lone-Sang
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module wb_emac_phy_wrapper #(
	parameter phy_adr = 5'b00001
) (
	input sys_rst,

	/* PHY */
	input phy_mgtclk_n,
	input phy_mgtclk_p,
	input phy_rx_p,
	input phy_rx_n,
	output phy_tx_p,
	output phy_tx_n,

	/* TX Interface */
	output phy_tx_clk,
	input [7:0] phy_tx_data,
	input phy_tx_en,
	output phy_tx_ack,

	/* RX Interface */
	output phy_rx_clk,
	output [7:0] phy_rx_data,
	output phy_dv,

	/* MDIO Interface */
	input phy_mii_clk,
	output phy_mii_data_do,
	input phy_mii_data_di,
	output phy_mii_data_oe_n
);

//-----------------------------------------------------------------------------
// Wire and Reg Declarations 
//-----------------------------------------------------------------------------

/* Reset signal from the transceiver */
wire resetdone;

/* Generate the clock input to the GTP */
wire phy_clk;
// IBUFDS clkingen (
// 	.I(phy_mgtclk_p),
// 	.IB(phy_mgtclk_n),
// 	.O(phy_clk)
// );
IBUFDS_GTXE1 clkingen (
  .I(phy_mgtclk_p),
  .IB(phy_mgtclk_n),
  .CEB(1'b0),
  .O(phy_clk),
  .ODIV2()
);                     

/* MAC wrappers clock - 125MHz from transceiver */
wire clk125;
wire clk125_o;
BUFG clk125_bufg(
	.I(clk125_o),
	.O(clk125)
);

/* Client clock - 1.25/12.5/125MHz clock from the MAC */
wire client_clk;
wire client_clk_o;
BUFG client_clk_bufg(
	.I(client_clk_o),
	.O(client_clk)
);

/* RocketIO PMA reset circuitry */
// wire gtp_reset;
// reg [3:0] reset_r;
// always @(posedge sys_rst, posedge clk125) begin
// 	if (sys_rst) begin
// 		reset_r <= 4'b1111;
// 	end else begin
// 		reset_r <= {reset_r[2:0], sys_rst};
// 	end
// end
// 
// assign gtp_reset = reset_r[3];

//------------------------------------------------------------------------
// Instantiate the EMAC Wrapper (v6_emac_v1_6_block.v) 
//------------------------------------------------------------------------
v6_emac_v1_6_block v6_emac_block_inst (
	.CLK125_OUT(clk125_o),
	.CLK125(clk125),
	.CLIENT_CLK_OUT(client_clk_o),
	.CLIENT_CLK(client_clk),

	.EMACCLIENTRXD(phy_rx_data),
	.EMACCLIENTRXDVLD(phy_dv),
	.EMACCLIENTRXGOODFRAME(),
	.EMACCLIENTRXBADFRAME(),

	.EMACCLIENTRXFRAMEDROP(),
	.EMACCLIENTRXSTATS(),
	.EMACCLIENTRXSTATSVLD(),
	.EMACCLIENTRXSTATSBYTEVLD(),
	
	.CLIENTEMACTXD(phy_tx_data),
	.CLIENTEMACTXDVLD(phy_tx_en),
	.EMACCLIENTTXACK(phy_tx_ack),
	.CLIENTEMACTXFIRSTBYTE(1'b0),
	.CLIENTEMACTXUNDERRUN(1'b0),
	.EMACCLIENTTXCOLLISION(),
	.EMACCLIENTTXRETRANSMIT(),

	.CLIENTEMACTXIFGDELAY(8'b0),
	.EMACCLIENTTXSTATS(),
	.EMACCLIENTTXSTATSVLD(),
	.EMACCLIENTTXSTATSBYTEVLD(),
	
	.CLIENTEMACPAUSEREQ(32'h00000000),
	.CLIENTEMACPAUSEVAL(16'h0000),
	
	.EMACCLIENTSYNCACQSTATUS(),
	.EMACANINTERRUPT(),
	
	.TXP(phy_tx_p),
	.TXN(phy_tx_n),
	.RXP(phy_rx_p),
	.RXN(phy_rx_n),
	.PHYAD(phy_adr),
	.RESETDONE(resetdone),

	.MDC_IN(phy_mii_clk),
	.MDIO_I(phy_mii_data_di),
	.MDIO_O(phy_mii_data_do),
	.MDIO_T(phy_mii_data_oe_n),

	.CLK_DS(phy_clk), 
// .GTRESET(gtp_reset),

	.RESET(sys_rst)
);

assign phy_rx_clk = client_clk;
assign phy_tx_clk = client_clk;

endmodule
