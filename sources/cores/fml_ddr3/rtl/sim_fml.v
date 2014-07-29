reg [adr_width-1:0] fml_adr;
reg fml_stb;
reg fml_we;
reg [7:0] fml_sel;
reg [63:0] fml_di;

wire fml_ack;
wire [63:0] fml_do;

initial begin
  fml_adr <= {adr_width{1'b0}};
  fml_stb <= 0;
  fml_we <= 0;
  fml_sel <= 0;
  fml_di <= 0;
end

task waitfmlack;
begin
  @(posedge fml_ack);
  #10;
end
endtask

task fml_single_read;
begin
  // Start the cycle
  fml_stb <= 1'b1;
  fml_adr <= 'h1000;

  // Wait for the ack
  waitfmlack;

  // End the cycle
  fml_stb <= 1'b0;
  fml_adr <= 'hxxxx;

  waitnclock(3);
end
endtask

task fml_single_write;
begin
  // Start the cycle
  fml_stb <= 1'b1;
  fml_adr <= 'h1000;
  fml_di <= 'haa;
  fml_we <= 1'b1;

  // Wait for the ack
  waitfmlack;

  // End the cycle
  fml_we <= 1'b0;
  fml_stb <= 1'b0;
  fml_adr <= 'hxxxx;
  fml_di <= 'hbb;
  waitclock;
  fml_di <= 'hcc;
  waitclock;
  fml_di <= 'hdd;
  waitclock;
end
endtask
