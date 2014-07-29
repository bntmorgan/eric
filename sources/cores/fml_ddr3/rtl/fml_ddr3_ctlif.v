/**
 * This module is built for 64 bit data with BC4 DDR2 & 3 configured Xilinx IP
 * core
 */
module fml_ddr3_ctlif #(
  // FML parameters
	parameter adr_width = 30,
  // MIG IP CORE parameters
  parameter DQ_WIDTH = 64,
  parameter ADDR_WIDTH = 27,
  parameter ECC_TEST = "OFF",
  parameter DATA_WIDTH = 64,
  parameter PAYLOAD_WIDTH = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH,
  parameter APP_DATA_WIDTH = PAYLOAD_WIDTH * 4,
  parameter APP_MASK_WIDTH = APP_DATA_WIDTH / 8
) (
  input sys_clk, // @80 MHz
  input sys_rst,

  input ui_clk, // @400 MHz
  input ui_clk_sync_rst,

  input [adr_width-1:0] fml_adr,
  input fml_stb,
  input fml_we,
  output reg fml_ack,
  input [7:0] fml_sel,
  input [63:0] fml_di,
  output reg [63:0] fml_do,

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

//-----------------------------------------------------------------
// Storage depth in 64 bit words
//-----------------------------------------------------------------
parameter qword_width = adr_width - 3;
parameter qword_depth = (1 << qword_width);

//-----------------------------------------------------------------
// Wire declaration
//-----------------------------------------------------------------
wire [qword_width-1:0] fml_base;

//-----------------------------------------------------------------
// Finite State Machine
//-----------------------------------------------------------------
reg [2:0] state;

reg [qword_width-1-2:0] base;
reg [1:0] offset;
wire [qword_width-1:0] addr = {base, offset};

reg read_start;
wire ddr3__read_end;
wire sys__read_end;
reg write_start;
wire ddr3__write_end;
wire sys__write_end;

reg [2:0] cpt;

reg [63:0] write_buf [3:0];
reg [63:0] read_buf [3:0];

assign fml_base = fml_adr[adr_width-1:3];

parameter IDLE = 3'd0;
parameter READ = 3'd1;
parameter READ_WAIT	= 3'd2;
parameter WRITE	= 3'd3;
parameter WRITE_WAIT = 3'd4;

parameter nburst = 3'd3;

task init;
begin
  state <= 0;
  read_start <= 0;
  write_start <= 0;
  fml_ack <= 0;
  base <= 0;
  offset <= 0;
  cpt <= nburst;
  write_buf[0] <= 0;
  write_buf[1] <= 0;
  write_buf[2] <= 0;
  write_buf[3] <= 0;
  fml_do <= 0;
end
endtask

task inc_fml_do;
begin
  offset <= offset + 2'b1;
  cpt <= cpt - 2'b1;
  fml_do <= read_buf[offset];
end
endtask

task inc_write_buf;
begin
  offset <= offset + 2'b1;
  cpt <= cpt - 2'b1;
  write_buf[offset] <= fml_di;
end
endtask

//
// FML controller
//
always @(posedge sys_clk) begin
  if (sys_rst) begin
    init();
  end else begin
    fml_ack <= 1'b0;
    read_start <= 1'b0;
    write_start <= 1'b0;
    case(state)
      IDLE: begin
        if(fml_stb) begin
          if(fml_we) begin
            state <= WRITE;
            fml_ack <= 1'b1;
          end else begin
            read_start <= 1'b1;
            state <= READ_WAIT;
          end
          base <= fml_base[qword_width-1:2];
          offset <= fml_base[1:0];
        end
      end
      READ_WAIT: begin
        if (sys__read_end) begin
          state <= READ;
          fml_ack <= 1'b1;
          // Read data is ready
          inc_fml_do;
        end
      end
      READ: begin
        inc_fml_do;
        if (cpt == 3'd0) begin
          state <= IDLE;
          cpt <= nburst;
        end
      end
      WRITE: begin
        inc_write_buf;
        if (cpt == 3'd0) begin
          state <= WRITE_WAIT;
          write_start <= 1'b1;
          cpt <= nburst;
        end
      end
      WRITE_WAIT: begin
        if (sys__write_end) begin
          state <= IDLE;
        end
      end
    endcase
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

task init_read;
begin
  read_state <= IDLE;
  read_end <= 0;
  read_buf[0] <= 64'haa;
  read_buf[1] <= 64'hbb;
  read_buf[2] <= 64'hcc;
  read_buf[3] <= 64'hdd;
  read_app_addr <= 0;
  read_app_cmd <= 0;
  read_app_en <= 0;
  read_app_wdf_data <= 0;
  read_app_wdf_end <= 0;
  read_app_wdf_mask <= 0;
  read_app_wdf_wren <= 0;
  read_start_safe <= 1;
end
endtask

always @(posedge ui_clk) begin
  if (ui_clk_sync_rst) begin
    init_read;
  end else begin
    read_end <= 1'b0;
    if (sys__read_end) begin
      read_start_safe <= 1'b1;
    end
    case (read_state)
      IDLE: begin
        if (read_start && read_start_safe) begin
          read_state <= READ;
          // Sart only once !
          read_start_safe <= 1'b0;
          // Send read command
          read_app_addr <= base;
          read_app_cmd <= CMD_READ;
          read_app_en <= 1'b1;
        end
      end
      READ: begin
        if (app_rdy) begin
          read_app_addr <= {ADDR_WIDTH{1'b0}};
          read_app_cmd <= CMD_NULL;
          read_app_en <= 1'b0;
          read_state <= READ_WAIT;
        end
      end
      READ_WAIT: begin
        if (app_rd_data_valid & app_rd_data_end) begin
          read_buf[0] = app_rd_data[255:192];
          read_buf[1] = app_rd_data[191:128];
          read_buf[2] = app_rd_data[127:64];
          read_buf[3] = app_rd_data[63:0];
          read_state <= IDLE;
          read_end <= 1'b1;
        end
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
end
endtask

always @(posedge ui_clk) begin
  if (ui_clk_sync_rst) begin
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
          // Send write command
          write_app_addr <= base;
          write_app_cmd <= CMD_WRITE;
          write_app_en <= 1'b1;
        end
      end
      WRITE: begin
        if (app_rdy) begin
          write_app_addr <= {ADDR_WIDTH{1'b0}};
          write_app_cmd <= CMD_NULL;
          write_app_en <= 1'b0;
          write_state <= WRITE_WAIT;
          // Write the data
          read_app_wdf_data <= {write_buf[3], write_buf[2], write_buf[1],
            write_buf[0]};
          read_app_wdf_wren <= 1'b1;
          read_app_wdf_end <= 1'b1;
        end
      end
      WRITE_WAIT: begin
        write_state <= IDLE;
        write_end <= 1'b1;
        read_app_wdf_data <= {DATA_WIDTH{1'b0}};
        read_app_wdf_wren <= 1'b0;
        read_app_wdf_end <= 1'b0;
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
assign app_wdf_data = read_app_wdf_data | write_app_wdf_data;
assign app_wdf_end = read_app_wdf_end | write_app_wdf_end;
assign app_wdf_mask = read_app_wdf_mask | write_app_wdf_mask;
assign app_wdf_wren = read_app_wdf_wren | write_app_wdf_wren;

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
fml_ddr3_psync psync_read_end (
	.clk1(ui_clk),
	.i(ddr3__read_end),
	.clk2(sys_clk),
	.o(sys__read_end)
);

fml_ddr3_psync psync_write_end (
	.clk1(ui_clk),
	.i(ddr3__write_end),
	.clk2(sys_clk),
	.o(sys__write_end)
);

endmodule
