`include "csr_ddr3.vh"

/**
 * This module is built for 64 bit data with BC4 DDR2 & 3 configured Xilinx IP
 * core
 */
module csr_ddr3_ctlif #(
	parameter csr_addr = 4'h0,
  // MIG IP CORE parameters
  parameter DQ_WIDTH = 64,
  parameter ADDR_WIDTH = 28,
  parameter ECC_TEST = "OFF",
  parameter DATA_WIDTH = 64,
  parameter PAYLOAD_WIDTH = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH,
  parameter APP_DATA_WIDTH = PAYLOAD_WIDTH * 4,
  parameter APP_MASK_WIDTH = APP_DATA_WIDTH / 8
) (
  input sys_clk, // @80 MHz
  input sys_rst,

  input ui_clk, // @200 MHz
  input ui_rst,

  // CSR
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

  // DRAM IP core dram

  // Input
  input app_rdy,
  input [APP_DATA_WIDTH-1:0] app_rd_data,
  input app_rd_data_end,
  input app_rd_data_valid,
  input app_wdf_rdy,
  
  // Output
  output [ADDR_WIDTH-1:0] app_addr,
  output [2:0] app_cmd,
  output app_en,
  output [APP_DATA_WIDTH-1:0] app_wdf_data,
  output app_wdf_end,
  output [APP_MASK_WIDTH-1:0] app_wdf_mask,
  output app_wdf_wren
);

reg read_start;
wire ddr3__read_end;
wire sys__read_end;
reg write_start;
wire ddr3__write_end;
wire sys__write_end;
reg event_write_end;
reg event_read_end;

reg [3:0] cpt;
reg [3:0] cptdr;
reg [3:0] cptdw;

reg [31:0] write_buf [7:0];
reg [31:0] read_buf [7:0];

reg [ADDR_WIDTH-1:0] addr;

reg [2:0] state;

/* CSR interface */
wire csr_selected = csr_a[13:10] == csr_addr;

parameter IDLE = 3'd0;
parameter READ = 3'd1;
parameter READ_WAIT	= 3'd2;
parameter WRITE	= 3'd3;
parameter WRITE_WAIT = 3'd4;

task init;
begin
  state <= 0;
  read_start <= 0;
  write_start <= 0;
  event_read_end <= 0;
  event_write_end <= 0;
  write_buf[0] <= 0;
  write_buf[1] <= 0;
  write_buf[2] <= 0;
  write_buf[3] <= 0;
  write_buf[4] <= 0;
  write_buf[5] <= 0;
  write_buf[6] <= 0;
  write_buf[7] <= 0;
  addr <= {ADDR_WIDTH{1'b0}};
end
endtask

//
// CSR controller
//
always @(posedge sys_clk) begin
	if (sys_rst) begin
    init;
	end else begin
    // State machine 
    if (sys__read_end) begin
      event_read_end <= 1'b1;
    end
    if (sys__write_end) begin
      event_write_end <= 1'b1;
    end
    read_start <= 1'b0;
    write_start <= 1'b0;
    // CSR 
		csr_do <= 32'd0;
		if (csr_selected) begin
			case (csr_a[9:0])
        `CSR_DDR3_CSR_CTRL: csr_do <= {30'b0, read_start, write_start};
        `CSR_DDR3_CSR_STAT: csr_do <= {28'b0, app_wdf_rdy, app_rdy,
          event_read_end, event_write_end};
        `CSR_DDR3_CSR_ADDR: csr_do <= {{32-ADDR_WIDTH{1'b0}}, addr};
        `CSR_DDR3_CSR_W0: csr_do <= {write_buf[0]};
        `CSR_DDR3_CSR_W1: csr_do <= {write_buf[1]};
        `CSR_DDR3_CSR_W2: csr_do <= {write_buf[2]};
        `CSR_DDR3_CSR_W3: csr_do <= {write_buf[3]};
        `CSR_DDR3_CSR_W4: csr_do <= {write_buf[4]};
        `CSR_DDR3_CSR_W5: csr_do <= {write_buf[5]};
        `CSR_DDR3_CSR_W6: csr_do <= {write_buf[6]};
        `CSR_DDR3_CSR_W7: csr_do <= {write_buf[7]};
        `CSR_DDR3_CSR_R0: csr_do <= {read_buf[0]};
        `CSR_DDR3_CSR_R1: csr_do <= {read_buf[1]};
        `CSR_DDR3_CSR_R2: csr_do <= {read_buf[2]};
        `CSR_DDR3_CSR_R3: csr_do <= {read_buf[3]};
        `CSR_DDR3_CSR_R4: csr_do <= {read_buf[4]};
        `CSR_DDR3_CSR_R5: csr_do <= {read_buf[5]};
        `CSR_DDR3_CSR_R6: csr_do <= {read_buf[6]};
        `CSR_DDR3_CSR_R7: csr_do <= {read_buf[7]};
        `CSR_DDR3_CSR_GWTC: csr_do <= {gwtc};
        `CSR_DDR3_CSR_GRTC: csr_do <= {grtc};
			endcase
			if (csr_we) begin
				case (csr_a[9:0])
          `CSR_DDR3_CSR_STAT: begin 
            if (csr_di[0]) event_write_end <= 1'b0;
            if (csr_di[1]) event_read_end <= 1'b0;
          end
          `CSR_DDR3_CSR_CTRL: begin
            if (csr_di[0]) 
              write_start <= 1'b1;
            else if (csr_di[1]) 
              read_start <= 1'b1;
          end
          `CSR_DDR3_CSR_ADDR: addr <= csr_di;
          `CSR_DDR3_CSR_W0: write_buf[0] <= csr_di;
          `CSR_DDR3_CSR_W1: write_buf[1] <= csr_di;
          `CSR_DDR3_CSR_W2: write_buf[2] <= csr_di;
          `CSR_DDR3_CSR_W3: write_buf[3] <= csr_di;
          `CSR_DDR3_CSR_W4: write_buf[4] <= csr_di;
          `CSR_DDR3_CSR_W5: write_buf[5] <= csr_di;
          `CSR_DDR3_CSR_W6: write_buf[6] <= csr_di;
          `CSR_DDR3_CSR_W7: write_buf[7] <= csr_di;
        endcase
      end
    end
  end
end

//
// Commands
//
parameter CMD_READ = 3'b001;
parameter CMD_WRITE = 3'b000;
parameter CMD_NULL = 3'b000;

//
// Read controller
//
reg [2:0] read_state;
reg read_end;
reg read_start_safe;
assign ddr3__read_end = read_end;

reg [ADDR_WIDTH-1:0] read_app_addr;
reg [2:0] read_app_cmd;
reg read_app_en;
reg [APP_DATA_WIDTH-1:0] read_app_wdf_data;
reg read_app_wdf_end;
reg [APP_MASK_WIDTH-1:0] read_app_wdf_mask;
reg read_app_wdf_wren;

reg [3:0] rtc;
reg [31:0] grtc;

task init_read;
begin
  read_state <= IDLE;
  read_end <= 0;
  read_buf[0] <= 32'haaaaaaaa;
  read_buf[1] <= 32'hbbbbbbbb;
  read_buf[2] <= 32'hcccccccc;
  read_buf[3] <= 32'hdddddddd;
  read_buf[4] <= 32'haaaaaaaa;
  read_buf[5] <= 32'hbbbbbbbb;
  read_buf[6] <= 32'hcccccccc;
  read_buf[7] <= 32'hdddddddd;
  read_app_addr <= 0;
  read_app_cmd <= 0;
  read_app_en <= 0;
  read_start_safe <= 1;
  rtc <= 4'b0;
  grtc <= 32'b0;
end
endtask

task app_read;
begin
  read_app_addr <= addr;
  read_app_cmd <= CMD_READ;
  read_app_en <= 1'b1;
end
endtask

task app_read_null;
begin
  read_app_addr <= {ADDR_WIDTH{1'b0}};
  read_app_cmd <= CMD_NULL;
  read_app_en <= 1'b0;
end
endtask

always @(posedge ui_clk) begin
  if (ui_rst) begin
    init_read;
  end else begin
    read_end <= 1'b0;
    if (sys__read_end) begin
      read_start_safe <= 1'b1;
    end
    case (read_state)
      IDLE: begin
        if (read_start && read_start_safe) begin
          // Sart only once !
          read_start_safe <= 1'b0;
          read_state <= READ;
          app_read;
        end
      end
      READ: begin
        rtc <= 4'b0;
        if (app_rdy) begin
          read_state <= READ_WAIT;
          app_read_null;
        end
      end
      READ_WAIT: begin
        if (app_rd_data_valid & app_rd_data_end) begin
          read_buf[0] <= app_rd_data[255:224];
          read_buf[1] <= app_rd_data[223:192];
          read_buf[2] <= app_rd_data[191:160];
          read_buf[3] <= app_rd_data[159:128];
          read_buf[4] <= app_rd_data[127: 96];
          read_buf[5] <= app_rd_data[ 95: 64];
          read_buf[6] <= app_rd_data[ 63: 32];
          read_buf[7] <= app_rd_data[ 31:  0];
          read_state <= IDLE;
          read_end <= 1'b1;
        end
        // XXX timeout 
        if (rtc == 4'hf) begin
          read_state <= READ;
          app_read;
          grtc <= grtc + 2'b1;
        end
        rtc <= rtc + 2'b1;
      end
    endcase
  end
end

//
// Write controller
//
reg [2:0] write_state;
reg write_end;
reg write_start_safe;
assign ddr3__write_end = write_end;

reg [ADDR_WIDTH-1:0] write_app_addr;
reg [2:0] write_app_cmd;
reg write_app_en;
reg [APP_DATA_WIDTH-1:0] write_app_wdf_data;
reg write_app_wdf_end;
reg [APP_MASK_WIDTH-1:0] write_app_wdf_mask;
reg write_app_wdf_wren;

reg [3:0] wtc;
reg [31:0] gwtc;

task init_write;
begin
  write_state <= IDLE;
  write_end <= 0;
  write_app_addr <= 0;
  write_app_cmd <= 0;
  write_app_en <= 0;
  write_app_wdf_data <= 0;
  write_app_wdf_end <= 0;
  write_app_wdf_mask <= 0;
  write_app_wdf_wren <= 0;
  write_start_safe <= 1;
  wtc <= 4'b0;
  gwtc <= 32'b0;
end
endtask

task app_write;
begin
  write_app_addr <= addr;
  write_app_cmd <= CMD_WRITE;
  write_app_en <= 1'b1;
end
endtask

task app_write_null;
begin
  write_app_addr <= {ADDR_WIDTH{1'b0}};
  write_app_cmd <= CMD_NULL;
  write_app_en <= 1'b0;
end
endtask

task app_write_data_null;
begin
  write_app_wdf_data <= {DATA_WIDTH{1'b0}};
  write_app_wdf_wren <= 1'b0;
  write_app_wdf_end <= 1'b0;
end
endtask

always @(posedge ui_clk) begin
  if (ui_rst) begin
    init_write;
  end else begin
    write_end <= 1'b0;
    if (sys__write_end) begin
      write_start_safe <= 1'b1;
    end
    case (write_state)
      IDLE: begin
        if (write_start & write_start_safe) begin
          // Sart only once !
          write_start_safe <= 1'b0;
          write_state <= WRITE;
          app_write;
        end
      end
      WRITE: begin
        wtc <= 4'b0;
        if (app_rdy) begin
          // Write the data
          write_app_wdf_data <= {write_buf[7], write_buf[6], write_buf[5],
            write_buf[4], write_buf[3], write_buf[2], write_buf[1],
            write_buf[0]};
          write_app_wdf_wren <= 1'b1;
          write_app_wdf_end <= 1'b1;
            write_state <= WRITE_WAIT;
          app_write_null;
        end
      end
      WRITE_WAIT: begin
        if (app_wdf_rdy) begin
          write_state <= IDLE;
          write_end <= 1'b1;
          app_write_data_null;
        end
        // XXX timeout 
        if (wtc == 4'hf) begin
          write_state <= WRITE;
          app_write;
          app_write_data_null;
          gwtc <= gwtc + 2'b1;
        end
        wtc <= wtc + 2'b1;
      end
    endcase
  end
end

//
// Read / Write Mux
//
assign app_addr = read_app_addr | write_app_addr;
assign app_cmd = read_app_cmd | write_app_cmd;
assign app_en = read_app_en | write_app_en;
assign app_wdf_data = write_app_wdf_data;
assign app_wdf_end = write_app_wdf_end;
assign app_wdf_mask = write_app_wdf_mask;
assign app_wdf_wren = write_app_wdf_wren;

//
// Initialization
//
initial begin
  init;
  init_read;
  init_write;
end

//
// Synchronization
//
csr_ddr3_psync psync_read_end (
	.clk1(ui_clk),
	.i(ddr3__read_end),
	.clk2(sys_clk),
	.o(sys__read_end)
);

csr_ddr3_psync psync_write_end (
	.clk1(ui_clk),
	.i(ddr3__write_end),
	.clk2(sys_clk),
	.o(sys__write_end)
);

endmodule
