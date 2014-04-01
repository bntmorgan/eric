module mpu_registers #(
  parameter nb_reg = 32
) (
  // System
  input sys_clk,
  input sys_rst,

  // read access
  input [nb_reg / 8:0] r_idx0,
  input [nb_reg / 8:0] r_idx1,
  input [nb_reg / 8:0] r_idx2,
  output [63:0] r_data0,
  output [63:0] r_data1,
  output [63:0] r_data2,

  // write access
  input [nb_reg/8:0] w_idx,
  input [63:0] w_data,
  input [2:0] w_sel,
  input [1:0] w_size,
  input we
);

// Registers
reg [63:0] regs [nb_reg - 1:0];

// Wiress
wire [6:0] bsize;
wire [127:0] _hm;
wire [63:0] hm;

initial begin
  init();
end

integer d;
task init;
  begin
    for (d = 0; d < nb_reg; d = d + 1) begin: toto2
      regs[d][63:0] = 64'b0;
    end
  end
endtask

/**
 * Read registers
 */
assign r_data0 = regs[r_idx0];
assign r_data1 = regs[r_idx1];
assign r_data2 = regs[r_idx2];

/**
 * Write registers
 */

// Compute the size of the fields in bit
assign bsize[6:0] = ((1 << w_size) << 3);
assign _hm = 128'h0000_0000_0000_0000_ffff_ffff_ffff_ffff << bsize;
assign hm = _hm[127:64] << (bsize * w_sel);

always @(posedge sys_clk) begin
  if (sys_rst == 1'b1) begin
    init(); 
  end else begin
    if (we == 1'b1) begin
      regs[w_idx] = (regs[w_idx] & ~(hm)) | (w_data & hm);
    end
  end
end

endmodule
