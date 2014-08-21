localparam APP_DATA_WIDTH = PAYLOAD_WIDTH * 4;
localparam APP_MASK_WIDTH = APP_DATA_WIDTH / 8;

// Clocks
reg ui_clk;
reg ui_rst;

// Inputs
reg app_rdy;
reg [APP_DATA_WIDTH-1:0] app_rd_data;
reg app_rd_data_end;
reg app_rd_data_valid;
reg app_wdf_rdy;

// Outputs
wire [ADDR_WIDTH-1:0] app_addr;
wire [2:0] app_cmd;
wire app_en;
wire [APP_DATA_WIDTH-1:0] app_wdf_data;
wire app_wdf_end;
wire [APP_MASK_WIDTH-1:0] app_wdf_mask;
wire app_wdf_wren;

always #1 ui_clk = !ui_clk;

/* Wishbone Helpers */
task waitddrclock;
begin
	@(posedge ui_clk);
	#1;
end
endtask

task waitnddrclock;
input [15:0] n;
integer i;
begin
	for(i=0;i<n;i=i+1)
		waitddrclock;
	end
endtask

/**
 * APP interface simulation
 */

// States
localparam IDLE = 3'b000;
localparam READ = 3'b001;
localparam WRITE = 3'b010;

// Commands
localparam CMD_READ = 3'b001;
localparam CMD_WRITE = 3'b000;
localparam CMD_NULL = 3'b000;

task init_ui;
begin
  app_rdy <= 1;
  app_rd_data <= {
    64'haaaaaaaaaaaaaaaa,
    64'hbbbbbbbbbbbbbbbb,
    64'hcccccccccccccccc,
    64'hdddddddddddddddd
  };
  app_rd_data_end <= 0;
  app_rd_data_valid <= 0;
  app_wdf_rdy <= 0;
  state <= IDLE;
end
endtask

initial begin
  ui_clk = 1'b0;
  ui_rst = 1'b0;
  init_ui;
end

reg [2:0] state;
always @(posedge ui_clk) begin
  if (ui_rst) begin
    init_ui;
  end else begin
    case (state)
      IDLE: begin
        if (app_en) begin
          if (app_cmd == CMD_READ) begin
            state <= READ;
            app_rdy <= 1'b0;
            app_rd_data_valid <= 1'b1;
            app_rd_data_end <= 1'b1;
          end
          if (app_cmd == CMD_WRITE) begin
            state <= WRITE;
            app_rdy <= 1'b0;
            app_wdf_rdy <= 1'b1;
          end
        end
      end
      READ: begin
        app_rd_data_valid <= 1'b0;
        app_rd_data_end <= 1'b0;
        state <= IDLE;
        app_rdy <= 1'b1;
      end
      WRITE: begin
        if (app_wdf_wren & app_wdf_end) begin
          app_rd_data <= app_wdf_data;
          state <= IDLE;
          app_rdy <= 1'b1;
          app_wdf_rdy <= 1'b0;
        end
      end
      default: state <= IDLE;
    endcase
  end
end
