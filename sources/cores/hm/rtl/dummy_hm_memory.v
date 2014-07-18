module hm_memory_32 (
		input [31:0] DIA,
		output reg [31:0] DOA,
		input [15:0] ADDRA,
		input [3:0] WEA,
		input CLKA,

		input [31:0] DIB,
		output reg [31:0] DOB,
		input [15:0] ADDRB,
		input [3:0] WEB,
		input CLKB
);

// Memory
reg [7:0] mem [4095:0];

integer d;
task init;
  begin
    DOA <= 32'b0;
    DOB <= 32'b0;
    for (d = 0; d < 4096; d = d + 1) begin
      // mem[d][7:0] = 8'b0;
      mem[d][7:0] = d;
    end
  end
endtask

initial begin
  init();
end

wire [11:0] ADDRA_ = ADDRA[14:3];
wire [11:0] ADDRB_ = ADDRB[14:3];

always @(posedge CLKA) begin
  begin
    if (WEA & 4'b0001) begin
      mem[ADDRA_ + 0] <= DIA[7 : 0];
    end
    if (WEA & 4'b0010) begin
      mem[ADDRA_ + 1] <= DIA[15: 8];
    end
    if (WEA & 4'b0100) begin
      mem[ADDRA_ + 2] <= DIA[23:16];
    end
    if (WEA & 4'b1000) begin
      mem[ADDRA_ + 3] <= DIA[31:24];
    end
  end
  DOA <= {mem[ADDRA_ + 3], mem[ADDRA_ + 2], mem[ADDRA_ + 1], mem[ADDRA_ + 0]};
end

always @(posedge CLKB) begin
  begin
    if (WEB & 4'b0001) begin
      mem[ADDRB_ + 0] <= DIB[7 : 0];
    end
    if (WEB & 4'b0010) begin
      mem[ADDRB_ + 1] <= DIB[15: 8];
    end
    if (WEB & 4'b0100) begin
      mem[ADDRB_ + 2] <= DIB[23:16];
    end
    if (WEB & 4'b1000) begin
      mem[ADDRB_ + 3] <= DIB[31:24];
    end
  end
  DOB <= {mem[ADDRB_ + 3], mem[ADDRB_ + 2], mem[ADDRB_ + 1], mem[ADDRB_ + 0]};
end

endmodule
