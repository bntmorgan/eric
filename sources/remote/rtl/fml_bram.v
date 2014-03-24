/*
 * Milkymist VJ SoC
 *
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

module fml_bram #(
	/* 
	 * In bytes. See Xilinx Library Guide for authorized values. By default, 
	 * RAM is composed of 8 x 8-bits BRAM with 12-bits addressing. Thus, the 
	 * whole RAM can be accessed with 2^(12+3) = 2^15 addresses.
	 */
	parameter adr_width = 15,
	parameter nburst = 3'd3,
	parameter delay_write = 3'd2,
	parameter delay_read = 3'd5,
	parameter fpga_family = "VIRTEX5"
) (
	input sys_clk, 
	input sys_rst,
	
	input [adr_width-1:0] fml_adr,
	input fml_stb,
	input fml_we,
	output reg fml_eack,
	input [7:0] fml_sel,
	input [63:0] fml_di,
	output [63:0] fml_do
);

//-----------------------------------------------------------------
// Storage depth in 64 bit words
//-----------------------------------------------------------------
parameter qword_width = adr_width - 3;
parameter qword_depth = (1 << qword_width);

//-----------------------------------------------------------------
// Wire declaration
//-----------------------------------------------------------------
wire [7:0] ram0di;
wire ram0we;
wire [7:0] ram1di;
wire ram1we;
wire [7:0] ram2di;
wire ram2we;
wire [7:0] ram3di;
wire ram3we;
wire [7:0] ram4di;
wire ram4we;
wire [7:0] ram5di;
wire ram5we;
wire [7:0] ram6di;
wire ram6we;
wire [7:0] ram7di;
wire ram7we;

wire [7:0] ram0do;
wire [7:0] ram1do;
wire [7:0] ram2do;
wire [7:0] ram3do;
wire [7:0] ram4do;
wire [7:0] ram5do;
wire [7:0] ram6do;
wire [7:0] ram7do;

wire [qword_width-1:0] fml_base;

//-----------------------------------------------------------------
// Finite State Machine
//-----------------------------------------------------------------
reg [1:0] state;
reg [1:0] next_state;

parameter IDLE		= 2'd0;
parameter READ_WAIT	= 2'd1;
parameter READ		= 2'd2;
parameter WRITE		= 2'd3;


always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

reg read;
reg read_safe;
reg write;
reg write_safe;
always @(*) begin
	next_state = state;
	fml_eack = 1'b0;

	read = 1'b0;
	write = 1'b0;
	case(state)
		IDLE: begin
			if(fml_stb) begin
				if(fml_we) begin
					if(write_safe) begin
						write = 1'b1;
						next_state = WRITE;
					end
				end else begin
					if(read_safe) begin
						read = 1'b1;
						next_state = READ_WAIT;
					end
				end
			end
		end
		READ_WAIT: next_state = READ;
		READ: begin
			next_state = IDLE;
			fml_eack = 1'b1;
		end
		WRITE: begin
			next_state = IDLE;
			fml_eack = 1'b1;
		end
	endcase
end

//-----------------------------------------------------------------
// Controller
//-----------------------------------------------------------------

/* read_delay: use this to handle early ack on some modules */
reg [2:0] read_delay_cnt;
wire read_delay;

assign read_delay = (read_delay_cnt != delay_read);
always @(posedge sys_clk) begin
	if (sys_rst)
		read_delay_cnt <= delay_read;
	else
		if(read)
			read_delay_cnt <= 3'd0;
		else if (read_delay)
			read_delay_cnt <= read_delay_cnt + 3'd1;
end

/* write_delay: use this to handle early ack on some modules */
reg [2:0] write_delay_cnt;
wire write_delay;

assign write_delay = (write_delay_cnt != delay_write);
always @(posedge sys_clk) begin
	if (sys_rst)
		write_delay_cnt <= delay_write;
	else
		if(write)
			write_delay_cnt <= 3'd0;
		else if (write_delay)
			write_delay_cnt <= write_delay_cnt + 3'd1;
end

/*
 * read_safe: whether it is safe to register a Read command
 * into the SDRAM at the next cycle.
 */
reg [2:0] read_safe_counter;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		read_safe_counter <= 3'd0;
		read_safe <= 1'b1;
	end else begin
		if(read) begin
			read_safe_counter <= nburst;
			read_safe <= 1'b0;
		end else if (write) begin
			read_safe_counter <= nburst;
			read_safe <= 1'b0;
		end else begin
			if(read_safe_counter == 3'd1)
				read_safe <= 1'b1;
			if(~read_safe & ~read_delay & ~write_delay)
				read_safe_counter <= read_safe_counter - 3'd1;
		end
	end
end

/*
 * write_safe: whether it is safe to register a Write command
 * into the SDRAM at the next cycle.
 */
reg [2:0] write_safe_counter;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		write_safe_counter <= 3'd0;
		write_safe <= 1'b1;
	end else begin
		if(read) begin
			write_safe_counter <= nburst + 3'd1;
			write_safe <= 1'b0;
		end else if(write) begin
			write_safe_counter <= nburst;
			write_safe <= 1'b0;
		end else begin
			if(write_safe_counter == 3'd1)
				write_safe <= 1'b1;
			if(~write_safe & ~write_delay & ~read_delay)
				write_safe_counter <= write_safe_counter - 3'd1;
		end
	end
end

/* READ burst counter */
reg [2:0] read_counter;
reg read_pending;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		read_counter <= 3'd0;
		read_pending <= 1'b0;
	end else begin
		if(read) begin
			read_counter <= 3'd0;
			read_pending <= 1'b1;
		end else if(read_pending) begin
			if (read_counter == nburst) begin
				read_counter <= 3'd0;
				read_pending <= 1'b0;
			end else begin
				read_counter <= read_counter + 3'd1;
				read_pending <= 1'b1;
			end
		end
	end
end

/* READ address generator */
reg [qword_width-1-2:0] read_base;
reg [1:0] read_offset;
wire [qword_width-1:0] read_addr = {read_base, read_offset};
always @(posedge sys_clk) begin
	if(sys_rst) begin
		read_base <= {qword_width-2{1'b0}};
		read_offset <= 2'd0;
	end else begin
		if(read) begin
			read_base <= fml_base[qword_width-1:2];
			read_offset <= fml_base[1:0];
		end
		if (~read_safe & ~read_delay)
			read_offset <= read_offset + 2'd1;
	end
end

/* WRITE burst counter */
reg [2:0] write_counter;
reg write_pending;
wire write_burst_pending = (write_counter != 3'd0);
always @(posedge sys_clk) begin
	if(sys_rst) begin
		write_counter <= 3'd0;
		write_pending <= 1'b0;
	end else begin
		if(write || write_delay) begin
			write_counter <= 3'd0;
			write_pending <= 1'b1;
		end else if(write_pending) begin
			if (write_counter == nburst) begin
				write_counter <= 3'd0;
				write_pending <= 1'b0;
			end else begin
				write_counter <= write_counter + 3'd1;
				write_pending <= 1'b1;
			end
		end
	end
end

/* WRITE address generator */
reg [qword_width-1-2:0] write_base;
reg [1:0] write_offset;
wire  [qword_width-1:0] write_addr = {write_base, write_offset};
always @(posedge sys_clk) begin
	if(sys_rst) begin
		write_base <= {qword_width-2{1'b0}};
		write_offset <= 2'd0;
	end else begin
		if(write) begin
			write_base <= fml_base[qword_width-1:2];
			write_offset <= fml_base[1:0];
		end
		if (~write_safe & write_pending & ~write_delay)
			write_offset <= write_offset + 2'd1;
	end
end

assign ram0we = (write_burst_pending ? 1'b1 : (fml_sel[0])) & (~write_delay & write_pending);
assign ram1we = (write_burst_pending ? 1'b1 : (fml_sel[1])) & (~write_delay & write_pending);
assign ram2we = (write_burst_pending ? 1'b1 : (fml_sel[2])) & (~write_delay & write_pending);
assign ram3we = (write_burst_pending ? 1'b1 : (fml_sel[3])) & (~write_delay & write_pending);
assign ram4we = (write_burst_pending ? 1'b1 : (fml_sel[4])) & (~write_delay & write_pending);
assign ram5we = (write_burst_pending ? 1'b1 : (fml_sel[5])) & (~write_delay & write_pending);
assign ram6we = (write_burst_pending ? 1'b1 : (fml_sel[6])) & (~write_delay & write_pending);
assign ram7we = (write_burst_pending ? 1'b1 : (fml_sel[7])) & (~write_delay & write_pending);

assign ram0di = fml_di[7:0];
assign ram1di = fml_di[15:8];
assign ram2di = fml_di[23:16];
assign ram3di = fml_di[31:24];
assign ram4di = fml_di[39:32];
assign ram5di = fml_di[47:40];
assign ram6di = fml_di[55:48];
assign ram7di = fml_di[63:56];

assign fml_base = fml_adr[adr_width-1:3];
assign fml_do = {ram7do, ram6do, ram5do, ram4do, ram3do, ram2do, ram1do, ram0do};


//-----------------------------------------------------------------
// Actual RAM (based on Xilinx Macro)
//-----------------------------------------------------------------

BRAM_SDP_MACRO #(
	.BRAM_SIZE("36Kb"),
	.DEVICE(fpga_family),
	.WRITE_WIDTH(8),
	.READ_WIDTH(8),
	.DO_REG(0),
	.INIT_FILE ("NONE"),
	.SIM_COLLISION_CHECK ("ALL"),
	.SIM_MODE("SAFE"),
	.SRVAL(8'h00),
	.INIT(8'h00)
) ram0 (
	.DO(ram0do),
	.DI(ram0di),
	.RDADDR(read_addr),
	.RDCLK(sys_clk),
	.RDEN(1'b1),
	.REGCE(1'b1),
	.RST(sys_rst),
	.WE(ram0we),
	.WRADDR(write_addr),
	.WRCLK(sys_clk),
	.WREN(1'b1)
);

BRAM_SDP_MACRO #(
	.BRAM_SIZE("36Kb"),
	.DEVICE(fpga_family),
	.WRITE_WIDTH(8),
	.READ_WIDTH(8),
	.DO_REG(0),
	.INIT_FILE ("NONE"),
	.SIM_COLLISION_CHECK ("ALL"),
	.SIM_MODE("SAFE"),
	.SRVAL(8'h00),
	.INIT(8'h00)
) ram1 (
	.DO(ram1do),
	.DI(ram1di),
	.RDADDR(read_addr),
	.RDCLK(sys_clk),
	.RDEN(1'b1),
	.REGCE(1'b1),
	.RST(sys_rst),
	.WE(ram1we),
	.WRADDR(write_addr),
	.WRCLK(sys_clk),
	.WREN(1'b1)
);

BRAM_SDP_MACRO #(
	.BRAM_SIZE("36Kb"),
	.DEVICE(fpga_family),
	.WRITE_WIDTH(8),
	.READ_WIDTH(8),
	.DO_REG(0),
	.INIT_FILE ("NONE"),
	.SIM_COLLISION_CHECK ("ALL"),
	.SIM_MODE("SAFE"),
	.SRVAL(8'h00),
	.INIT(8'h00)
) ram2 (
	.DO(ram2do),
	.DI(ram2di),
	.RDADDR(read_addr),
	.RDCLK(sys_clk),
	.RDEN(1'b1),
	.REGCE(1'b1),
	.RST(sys_rst),
	.WE(ram2we),
	.WRADDR(write_addr),
	.WRCLK(sys_clk),
	.WREN(1'b1)
);

BRAM_SDP_MACRO #(
	.BRAM_SIZE("36Kb"),
	.DEVICE(fpga_family),
	.WRITE_WIDTH(8),
	.READ_WIDTH(8),
	.DO_REG(0),
	.INIT_FILE ("NONE"),
	.SIM_COLLISION_CHECK ("ALL"),
	.SIM_MODE("SAFE"),
	.SRVAL(8'h00),
	.INIT(8'h00)
) ram3 (
	.DO(ram3do),
	.DI(ram3di),
	.RDADDR(read_addr),
	.RDCLK(sys_clk),
	.RDEN(1'b1),
	.REGCE(1'b1),
	.RST(sys_rst),
	.WE(ram3we),
	.WRADDR(write_addr),
	.WRCLK(sys_clk),
	.WREN(1'b1)
);

BRAM_SDP_MACRO #(
	.BRAM_SIZE("36Kb"),
	.DEVICE(fpga_family),
	.WRITE_WIDTH(8),
	.READ_WIDTH(8),
	.DO_REG(0),
	.INIT_FILE ("NONE"),
	.SIM_COLLISION_CHECK ("ALL"),
	.SIM_MODE("SAFE"),
	.SRVAL(8'h00),
	.INIT(8'h00)
) ram4 (
	.DO(ram4do),
	.DI(ram4di),
	.RDADDR(read_addr),
	.RDCLK(sys_clk),
	.RDEN(1'b1),
	.REGCE(1'b1),
	.RST(sys_rst),
	.WE(ram4we),
	.WRADDR(write_addr),
	.WRCLK(sys_clk),
	.WREN(1'b1)
);

BRAM_SDP_MACRO #(
	.BRAM_SIZE("36Kb"),
	.DEVICE(fpga_family),
	.WRITE_WIDTH(8),
	.READ_WIDTH(8),
	.DO_REG(0),
	.INIT_FILE ("NONE"),
	.SIM_COLLISION_CHECK ("ALL"),
	.SIM_MODE("SAFE"),
	.SRVAL(8'h00),
	.INIT(8'h00)
) ram5 (
	.DO(ram5do),
	.DI(ram5di),
	.RDADDR(read_addr),
	.RDCLK(sys_clk),
	.RDEN(1'b1),
	.REGCE(1'b1),
	.RST(sys_rst),
	.WE(ram5we),
	.WRADDR(write_addr),
	.WRCLK(sys_clk),
	.WREN(1'b1)
);

BRAM_SDP_MACRO #(
	.BRAM_SIZE("36Kb"),
	.DEVICE(fpga_family),
	.WRITE_WIDTH(8),
	.READ_WIDTH(8),
	.DO_REG(0),
	.INIT_FILE ("NONE"),
	.SIM_COLLISION_CHECK ("ALL"),
	.SIM_MODE("SAFE"),
	.SRVAL(8'h00),
	.INIT(8'h00)
) ram6 (
	.DO(ram6do),
	.DI(ram6di),
	.RDADDR(read_addr),
	.RDCLK(sys_clk),
	.RDEN(1'b1),
	.REGCE(1'b1),
	.RST(sys_rst),
	.WE(ram6we),
	.WRADDR(write_addr),
	.WRCLK(sys_clk),
	.WREN(1'b1)
);

BRAM_SDP_MACRO #(
	.BRAM_SIZE("36Kb"),
	.DEVICE(fpga_family),
	.WRITE_WIDTH(8),
	.READ_WIDTH(8),
	.DO_REG(0),
	.INIT_FILE ("NONE"),
	.SIM_COLLISION_CHECK ("ALL"),
	.SIM_MODE("SAFE"),
	.SRVAL(8'h00),
	.INIT(8'h00)
) ram7 (
	.DO(ram7do),
	.DI(ram7di),
	.RDADDR(read_addr),
	.RDCLK(sys_clk),
	.RDEN(1'b1),
	.REGCE(1'b1),
	.RST(sys_rst),
	.WE(ram7we),
	.WRADDR(write_addr),
	.WRCLK(sys_clk),
	.WREN(1'b1)
);

endmodule
