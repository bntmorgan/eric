reg mpu_clk;

wire mpu_en;
wire mpu_rst;

reg user_irq;
reg [63:0] user_data;
reg error;

always #12.5 mpu_clk = !mpu_clk; // @40 MHz

initial begin
  mpu_clk = 1'b0;
  error = 1'b0;
  user_data = 64'b0;
  user_irq = 1'b0;
end

task waitmpu_clk;
begin
	@(posedge mpu_clk);
	#1;
end
endtask
