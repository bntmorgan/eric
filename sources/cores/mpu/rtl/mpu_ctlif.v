`include "mpu.vh"

/**
 * TODO psync mpu_start
 */
module mpu_ctlif #(
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

  // MPU
  input mpu_clk,
  output reg mpu_en,
  output reg mpu_rst,
  input user_irq,
  input [63:0] user_data,
  input error,

  // IRQ
  output irq
);

/* CSR interface */
wire csr_selected = csr_a[13:10] == csr_addr;

/* Internal Registers */
// Events
reg event_end;
reg event_error;
reg event_user_irq;
// IRQs
reg irq_en;

reg mpu_start;

reg [63:0] user_data_r;

/** 
 * Internal state 
 */
reg [2:0] state;

/* IRQ Control */
assign irq = (event_end & irq_en) | (event_error & irq_en) | (event_user_irq
  & irq_en);

task init_csr;
begin
  csr_do <= 32'd0; 
  event_end <= 1'b0; 
  event_error <= 1'b0; 
  event_user_irq <= 1'b0; 
  irq_en <= 1'b0; 
  mpu_start <= 1'b0;
end
endtask

initial begin
  init_csr;
  init_mpu;
end

/**
 * CSR logic
 *
 * CSR registers can't be modified in the MPU_STATE_RUNNING state except for
 * mode_start which can be if the user needs to stop the automata
 */
always @(posedge sys_clk) begin
	if (sys_rst) begin
    init_csr;
	end else begin
    // CSR 
		csr_do <= 32'd0;
		if (csr_selected) begin
			case (csr_a[9:0])
        `MPU_CSR_STAT: csr_do <= {29'b0, event_user_irq, event_error,
         event_end};
        `MPU_CSR_CTRL: csr_do <= {29'b0, mpu_start, irq_en};
        `MPU_CSR_USER_DATA_LOW: csr_do <= user_data_r[31:0];
        `MPU_CSR_USER_DATA_HIGH: csr_do <= user_data_r[63:32];
			endcase
			if (csr_we) begin
				case (csr_a[9:0])
          `MPU_CSR_STAT: begin 
            if (state == `MPU_STATE_IDLE || state == `MPU_STATE_WAIT)
            begin
              /* write one to clear */
              if(csr_di[0])
                event_end <= 1'b0;
              if(csr_di[1])
                event_error <= 1'b0;
              if(csr_di[2])
                event_user_irq <= 1'b0;
            end
          end
          `MPU_CSR_CTRL: begin
            if (state == `MPU_STATE_IDLE) begin
              irq_en <= csr_di[0];
            end
            // We can only write stop when one mpu is launched
            mpu_start <= csr_di[1];
          end
        endcase
      end
    end
    // Get events
    if (mpu__event_end) begin
      event_end <= 1'b1;
      mpu_start <= 1'b0;
    end
    if (mpu__event_user_irq) begin
      event_user_irq <= 1'b1;
    end
    if (mpu__event_error) begin
      event_error <= 1'b1;
      mpu_start <= 1'b0;
    end
  end
end

reg mpu__event_end;
reg mpu__event_user_irq;
reg mpu__event_error;

task init_mpu;
begin
  state <= `MPU_STATE_IDLE; 
  mpu_rst <= 1'b0;
  mpu_en <= 1'b0;
  mpu__event_end <= 1'b0;
  mpu__event_user_irq <= 1'b0;
  mpu__event_error <= 1'b0;
  user_data_r <= 64'b0;
end
endtask

always @(posedge mpu_clk) begin
  // MPU state machine
  if (sys_rst) begin
    init_mpu;
  end else begin
    mpu__event_end <= 1'b0;
    mpu__event_user_irq <= 1'b0;
    mpu__event_error <= 1'b0;
    if (state == `MPU_STATE_IDLE) begin
      if (mpu_start == 1'b1) begin // IDLE -> RESET
        state <= `MPU_STATE_RESET;
        mpu_rst <= 1'b1;
      end
    end else if (state == `MPU_STATE_RESET) begin
      state <= `MPU_STATE_RUN; // RESET -> RUN
      mpu_rst <= 1'b0;
      mpu_en <= 1'b1;
    end else if (state == `MPU_STATE_RUN) begin
      if (mpu_start == 1'b0) begin // RUN -> IDE // user end
        state <= `MPU_STATE_IDLE;
        mpu_en <= 1'b0;
      end else if (error == 1'b1) begin // RUN -> IDLE
        state <= `MPU_STATE_IDLE;
        mpu__event_error <= 1'b1;
        mpu_en <= 1'b0;
      end else if (user_irq == 1'b1 && user_data == 64'b0) begin
        state <= `MPU_STATE_IDLE; // RUN -> IDLE : IRQ data 0 !
        mpu__event_end <= 1'b1;
        mpu_en <= 1'b0;
      end else if (user_irq == 1'b1) begin // RUN -> WAIT
        state <= `MPU_STATE_WAIT;
        user_data_r <= user_data;
        mpu__event_user_irq <= 1'b1;
        mpu_en <= 1'b0;
      end
    end else if (state == `MPU_STATE_WAIT) begin
      if (event_user_irq == 1'b0) begin // WAIT -> RUN
        state <= `MPU_STATE_RUN;
        user_data_r <= 64'b0;
        mpu_en <= 1'b1;
      end else if (mpu_start == 1'b0) begin // RUN -> IDE user end
        state <= `MPU_STATE_IDLE;
        user_data_r <= 64'b0;
        mpu_en <= 1'b0;
      end
    end
  end
end

endmodule
