//-----------------------------------------------------------------------------
// Title      : SGMII Receiver Elastic Buffer
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : rx_elastic_buffer.v
// Version    : 1.6
//-----------------------------------------------------------------------------
//
// (c) Copyright 2009-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//----------------------------------------------------------------------
// Description: This is the Receiver Elastic Buffer for the design
//              example of the Virtex-6 Embedded Tri-Mode Ethernet MAC.
//
//              The FIFO is created from distributed memory, is of data
//              width 32 (2 characters wide plus status) and is of depth
//              64 words.  This is twice the size of the elastic buffer
//              in the GTX which has been bypassed,
//
//              When the write clock is a few parts per million faster
//              than the read clock, the occupancy of the FIFO will
//              increase and Idles should be removed.
//
//              When the read clock is a few parts per million faster
//              than the write clock, the occupancy of the FIFO will
//              decrease and Idles should be inserted.  The logic in
//              this example design will always insert as many idles as
//              necessary in every Inter-frame Gap period to restore the
//              FIFO occupancy.
//
//              Note: the Idle /I2/ sequence is used as the clock
//              correction character.  This is made up from a /K28.5/
//              followed by a /D16.2/ character.
//----------------------------------------------------------------------

`timescale 1 ns/1 ps

module rx_elastic_buffer (

    // Signals received from the GTX on RXRECCLK.
    rxrecclk,
    rxrecreset,
    rxchariscomma_rec,
    rxcharisk_rec,
    rxdisperr_rec,
    rxnotintable_rec,
    rxrundisp_rec,
    rxdata_rec,

    // Signals reclocked onto RXUSRCLK2.
    rxusrclk2,
    rxreset,
    rxchariscomma_usr,
    rxcharisk_usr,
    rxdisperr_usr,
    rxnotintable_usr,
    rxrundisp_usr,
    rxclkcorcnt_usr,
    rxbuferr,
    rxdata_usr
);

  // port declarations
  input         rxrecclk;
  input         rxrecreset;
  input  [1:0]  rxchariscomma_rec;
  input  [1:0]  rxcharisk_rec;
  input  [1:0]  rxdisperr_rec;
  input  [1:0]  rxnotintable_rec;
  input  [1:0]  rxrundisp_rec;
  input  [15:0] rxdata_rec;

  input         rxusrclk2;
  input         rxreset;
  output        rxchariscomma_usr;
  output        rxcharisk_usr;
  output        rxdisperr_usr;
  output        rxnotintable_usr;
  output        rxrundisp_usr;
  output [2:0]  rxclkcorcnt_usr;
  output        rxbuferr;
  output [7:0]  rxdata_usr;

  reg           rxchariscomma_usr;
  reg           rxcharisk_usr;
  reg           rxdisperr_usr;
  reg           rxnotintable_usr;
  reg           rxrundisp_usr;
  reg           rxbuferr;
  reg    [7:0]  rxdata_usr;


  //--------------------------------------------------------------------
  // Constants to set FIFO thresholds
  //--------------------------------------------------------------------

  // FIFO occupancy over this level: clock correct to remove Idles
  wire   [5:0]  upper_threshold;
  assign upper_threshold     = 6'b100001;

  // FIFO occupancy less than this level: clock correct to insert Idles
  wire   [5:0]  lower_threshold;
  assign lower_threshold     = 6'b011111;

  // FIFO occupancy less than this, we consider it to be an underflow
  wire   [5:0]  underflow_threshold;
  assign underflow_threshold = 6'b000011;

  // FIFO occupancy greater than this, we consider it to be an overflow
  wire   [5:0]  overflow_threshold;
  assign overflow_threshold  = 6'b111100;


  //--------------------------------------------------------------------
  // Signal Declarations
  //--------------------------------------------------------------------

  // Write domain logic (RXRECCLK)
  reg    [35:0] wr_data;               // Formatted the data word from GTX signals.
  reg    [35:0] wr_data_reg;           // wr_data registered and formatting completed: to be written to the RAM.
  reg    [5:0]  wr_addr_plus2;         // Always ahead of the FIFO write address by 2.
  reg    [5:0]  wr_addr_plus1;         // Always ahead of the FIFO write address by 1.
  reg    [5:0]  wr_addr;               // FIFO write address.
  reg           wr_enable;             // write enable for FIFO.
  reg    [5:0]  wr_addr_gray;          // wr_addr is converted to a gray code.


  // ASYNC_REG attribute added to simulate actual behavior under
  // asynchronous operating conditions.
  (* ASYNC_REG = "TRUE" *)
  reg    [5:0]  wr_rd_addr_gray;       // read address pointer (gray coded) reclocked onto the write clock domain).

  reg    [5:0]  wr_rd_addr_gray_reg;   // read address pointer (gray coded) registered on write clock for the 2nd time.
  wire   [5:0]  wr_rd_addr;            // wr_rd_addr_gray converted back to binary (on the write clock domain).
  reg    [5:0]  wr_occupancy;          // The occupancy of the FIFO in write clock domain.
  wire          filling;               // FIFO is filling up: Idles should be removed.

  wire          k28p5_wr;              // /K28.5/ character is detected on data prior to FIFO.
  wire          d16p2_wr;              // /D16.2/ character is detected on data prior to FIFO.
  reg           k28p5_wr_reg;          // k28p5_wr registered.
  reg           d16p2_wr_reg;          // d16p2_wr registered.
  reg           remove_idle;           // An Idle is removed before writing it into the FIFO.

  // Read domain logic (RXUSRCLK2)
  wire   [35:0] rd_data_ram;           // Date read out of the RAM (before registering).
  reg    [35:0] rd_data;               // Date read out of the RAM.
  reg    [35:0] rd_data_reg;           // rd_data is registered for logic pipeline.
  reg    [5:0]  rd_addr_plus2;         // Always ahead of the FIFO read address by 2.
  reg    [5:0]  rd_addr_plus1;         // Always ahead of the FIFO read address by 1.
  reg    [5:0]  rd_addr;               // FIFO read address.
  reg           rd_enable;             // read enable for FIFO.
  reg    [5:0]  rd_addr_gray;          // rd_addr is converted to a gray code.


  // ASYNC_REG attribute added to simulate actual behavior under
  // asynchronous operating conditions.
  (* ASYNC_REG = "TRUE" *)
  reg    [5:0]  rd_wr_addr_gray;       // write address pointer (gray coded) reclocked onto the read clock domain).

  reg    [5:0]  rd_wr_addr_gray_reg;   // write address pointer (gray coded) registered on read clock for the 2nd time.
  wire   [5:0]  rd_wr_addr;            // rd_wr_addr_gray converted back to binary (on the read clock domain).
  reg    [5:0]  rd_occupancy;          // The occupancy of the FIFO in read clock domain.
  wire          emptying;              // FIFO is emptying: Idles should be inserted.
  wire          overflow;              // FIFO has filled up to overflow.
  wire          underflow;             // FIFO has emptied to underflow

  reg           even;                  // To control reading of data from upper or lower half of FIFO word.
  wire          k28p5_rd;              // /K28.5/ character is detected on data post FIFO.
  wire          d16p2_rd;              // /D16.2/ character is detected on data post FIFO.
  reg           insert_idle;           // An Idle is inserted whilst reading it out of the FIFO.
  reg           insert_idle_reg;       // insert_idle is registered.
  reg   [2:0]   rxclkcorcnt;           // derive RXCLKCORCNT to mimic GTX behaviour.


  //--------------------------------------------------------------------
  // FIFO write logic (Idles are removed as necessary).
  //--------------------------------------------------------------------

  // Reclock the GTX data and format for storing in the RAM.
  always @(posedge rxrecclk)
  begin : gen_wr_data
    if (rxrecreset == 1'b1)
    begin
      wr_data            <= 36'b0;
      wr_data_reg        <= 36'b0;
    end
    else
    begin
      wr_data_reg[35:14] <= wr_data[35:14];
      wr_data_reg[13]    <= remove_idle;
      wr_data_reg[12:0]  <= wr_data[12:0];

      // unused parity bits
      wr_data[35:32]     <= 4'b0;

      // format the upper word
      wr_data[31:29]     <= 3'b0;   // unused
      wr_data[28]        <= rxchariscomma_rec[0];
      wr_data[27]        <= rxcharisk_rec[0];
      wr_data[26]        <= rxdisperr_rec[0];
      wr_data[25]        <= rxnotintable_rec[0];
      wr_data[24]        <= rxrundisp_rec[0];
      wr_data[23:16]     <= rxdata_rec[7:0];

      // format the lower word
      wr_data[15:13]     <= 3'b0;   // unused
      wr_data[12]        <= rxchariscomma_rec[1];
      wr_data[11]        <= rxcharisk_rec[1];
      wr_data[10]        <= rxdisperr_rec[1];
      wr_data[9]         <= rxnotintable_rec[1];
      wr_data[8]         <= rxrundisp_rec[1];
      wr_data[7:0]       <= rxdata_rec[15:8];

    end
  end // gen_wr_data

  // Detect /K28.5/ character in upper half of the word from GTX 
  assign k28p5_wr = (wr_data[23:16] == 8'b10111100 &&
                     wr_data[27] == 1'b1) ? 1'b1 : 1'b0;

  // Detect /D16.2/ character in upper half of the word from GTX 
  assign d16p2_wr = (wr_data[7:0] == 8'b01010000 &&
                     wr_data[11] == 1'b0) ? 1'b1 : 1'b0;

  // Create the FIFO write enable: Idles are removed by deasserting the
  // FIFO write_enable whilst an Idle is present on the data.
  always @(posedge rxrecclk)
  begin : gen_wr_enable
    if (rxrecreset == 1'b1)
    begin
      wr_enable     <= 1'b0;
      remove_idle   <= 1'b0;
      k28p5_wr_reg  <= 1'b0;
      d16p2_wr_reg  <= 1'b0;
    end
    else
    begin

      k28p5_wr_reg  <= k28p5_wr;
      d16p2_wr_reg  <= d16p2_wr;

      // Idle removal (always leave the first /I2/ Idle, then every
      // alternate Idle can be removed.
      if (k28p5_wr == 1'b1 && d16p2_wr == 1'b1 &&
          k28p5_wr_reg == 1'b1 && d16p2_wr_reg == 1'b1 &&
        filling == 1'b1 && remove_idle == 1'b0)

      begin
        wr_enable   <= 1'b0;
        remove_idle <= 1'b1;
      end

      // Else write new word on every clock edge.
      else
      begin
        wr_enable   <= 1'b1;
        remove_idle <= 1'b0;
      end
    end
  end // gen_wr_enable

  // Create the FIFO write address pointer.  Note that wr_addr_plus2
  // will be converted to gray code and passed across the async clock
  // boundary.
  always @(posedge rxrecclk)
  begin : gen_wr_addr
    if (rxrecreset == 1'b1)
    begin
      wr_addr_plus2 <= 6'b100010;
      wr_addr_plus1 <= 6'b100001;
      wr_addr       <= 6'b100000;
    end
    else if (wr_enable == 1'b1)
    begin
      wr_addr_plus2 <= wr_addr_plus2 + 6'b1;
      wr_addr_plus1 <= wr_addr_plus2;
      wr_addr       <= wr_addr_plus1;
    end
  end // gen_wr_addr

  // Convert look-ahead write address pointer into a gray code
  always @(posedge rxrecclk)
  begin : wr_addrgray_bits
    if (rxrecreset == 1'b1)
      wr_addr_gray <= 6'b110001;
    else
    begin
      wr_addr_gray[5] <= wr_addr_plus2[5];
      wr_addr_gray[4] <= wr_addr_plus2[5] ^ wr_addr_plus2[4];
      wr_addr_gray[3] <= wr_addr_plus2[4] ^ wr_addr_plus2[3];
      wr_addr_gray[2] <= wr_addr_plus2[3] ^ wr_addr_plus2[2];
      wr_addr_gray[1] <= wr_addr_plus2[2] ^ wr_addr_plus2[1];
      wr_addr_gray[0] <= wr_addr_plus2[1] ^ wr_addr_plus2[0];
    end
  end // wr_addrgray_bits;


  //--------------------------------------------------------------------
  // Instantiate a dual port RAM
  //--------------------------------------------------------------------

  // Starting in core version 1.4, the SGMII Fabric Elastic Buffer is now
  // constructed by default using distributed RAM instead of BRAM.  This uses
  // extra LUT resources.

  // If a BRAM implementation is prefered, please remove the following code
  // and re-instate the commented out BRAM "RAMB36E1" instantiation which
  // immediately follows.

  genvar I;
  generate for (I=0; I<36; I=I+1)
  begin : GEN_FIFO
     RAM64X1D DIST_RAM 
     (
        .D          (wr_data_reg[I]),
        .WE         (wr_enable),
        .WCLK       (rxrecclk),
        .A0         (wr_addr[0]),
        .A1         (wr_addr[1]),
        .A2         (wr_addr[2]),
        .A3         (wr_addr[3]),
        .A4         (wr_addr[4]),
        .A5         (wr_addr[5]),
        .DPRA0      (rd_addr[0]),
        .DPRA1      (rd_addr[1]),
        .DPRA2      (rd_addr[2]),
        .DPRA3      (rd_addr[3]),
        .DPRA4      (rd_addr[4]),
        .DPRA5      (rd_addr[5]),

        .SPO        (),
        .DPO        (rd_data_ram[I])
     );

     // Register the distributed RAM read data.
     always @(posedge rxusrclk2)
     begin: reg_rd_data_ram
        if (rxreset == 1'b1)
           rd_data[I] <= 1'b0;
        else
           rd_data[I] <= rd_data_ram[I];
     end // reg_rd_data_ram

    end
  endgenerate


  //RAMB36E1 # (
  //  .DOA_REG               (0),
  //  .DOB_REG               (0),
  //  .EN_ECC_READ           ("FALSE"),
  //  .EN_ECC_WRITE          ("FALSE"),
  //  .INIT_A                (36'h000000000),
  //  .INIT_B                (36'h000000000),
  //  .INIT_FILE             ("NONE"),
  //  .RAM_EXTENSION_A       ("NONE"),
  //  .RAM_EXTENSION_B       ("NONE"),
  //  .RAM_MODE              ("TDP"),
  //  .READ_WIDTH_A          (36),
  //  .READ_WIDTH_B          (0),
  //  .RSTREG_PRIORITY_A     ("RSTREG"),
  //  .RSTREG_PRIORITY_B     ("RSTREG"),
  //  .SIM_COLLISION_CHECK   ("ALL"),
  //  .SRVAL_A               (36'h000000000),
  //  .SRVAL_B               (36'h000000000),
  //  .WRITE_WIDTH_A         (0),
  //  .WRITE_WIDTH_B         (36),
  //  .WRITE_MODE_A          ("WRITE_FIRST"),
  //  .WRITE_MODE_B          ("WRITE_FIRST")
  //
  //) dual_port_block_ram (
  //  .CASCADEOUTA           (),
  //  .CASCADEOUTB           (),
  //  .DBITERR               (),
  //  .DOADO                 (rd_data[31:0]),
  //  .DOBDO                 (),
  //  .DOPADOP               (rd_data[35:32]),
  //  .DOPBDOP               (),
  //  .ECCPARITY             (),
  //  .RDADDRECC             (),
  //  .SBITERR               (),
  //  .ADDRARDADDR           ({5'b0, rd_addr, 5'b0}),
  //  .ADDRBWRADDR           ({5'b0, wr_addr, 5'b0}),
  //  .CASCADEINA            (1'b0),
  //  .CASCADEINB            (1'b0),
  //  .CLKARDCLK             (rxusrclk2),
  //  .CLKBWRCLK             (rxrecclk),
  //  .DIADI                 (0),
  //  .DIBDI                 (wr_data_reg[31:0]),
  //  .DIPADIP               (0),
  //  .DIPBDIP               (wr_data_reg[35:32]),
  //  .ENARDEN               (1'b1),
  //  .ENBWREN               (1'b1),
  //  .INJECTDBITERR         (1'b0),
  //  .INJECTSBITERR         (1'b0),
  //  .REGCEAREGCE           (1'b0),
  //  .REGCEB                (1'b0),
  //  .RSTRAMARSTRAM         (1'b0),
  //  .RSTRAMB               (1'b0),
  //  .RSTREGARSTREG         (1'b0),
  //  .RSTREGB               (1'b0),
  //  .WEA                   (4'b0000),
  //  .WEBWE                 ({4'b0000, wr_enable, wr_enable, wr_enable, wr_enable})
  //);


  //--------------------------------------------------------------------
  // FIFO read logic (Idles are insterted as necessary).
  //--------------------------------------------------------------------

  // Register the RAM data.
  always @(posedge rxusrclk2)
  begin : reg_rd_data
    if (rxreset == 1'b1)
      rd_data_reg   <= 36'b0;

    else if (rd_enable == 1'b1)
      rd_data_reg   <= rd_data;

  end // reg_rd_data

  // Detect /K28.5/ character in upper half of the word read from FIFO
  assign k28p5_rd = (rd_data[23:16] == 8'b10111100 &&
                     rd_data[27] == 1'b1) ? 1'b1 : 1'b0;

  // Detect /D16.2/ character in lower half of the word read from FIFO
  assign d16p2_rd = (rd_data[7:0] == 8'b01010000 &&
                     rd_data[11] == 1'b0) ? 1'b1 : 1'b0;

  // Create the FIFO read enable: Idles are inserted by pausing the
  // FIFO read_enable whilst an Idle is present on the data.
  always @(posedge rxusrclk2)
  begin : gen_rd_enable
    if (rxreset == 1'b1)
    begin
      even            <= 1'b1;
      rd_enable       <= 1'b0;
      insert_idle     <= 1'b0;
      insert_idle_reg <= 1'b0;
    end
    else
    begin

      even            <= ~even;
      insert_idle_reg <= insert_idle;

      // Repeat as many /I2/ code groups as required if nearly
      // empty by pausing rd_enable.
      if (k28p5_rd == 1'b1 && d16p2_rd == 1'b1 && emptying == 1'b1)
      begin
        rd_enable     <= 1'b0;
        insert_idle   <= even;
      end

      // Else read out a new word on every alternative clock edge.
      else
      begin
         rd_enable    <= even;
         insert_idle  <= 1'b0;
      end
    end
  end // gen_rd_enable

  // Create the FIFO read address pointer.  Note that rd_addr_plus2
  // will be converted to gray code and passed across the async clock
  // boundary.
  always @(posedge rxusrclk2)
  begin : gen_rd_addr
    if (rxreset == 1'b1)
    begin
      rd_addr_plus2 <= 6'b000010;
      rd_addr_plus1 <= 6'b000001;
      rd_addr       <= 6'b000000;
    end
    else if (rd_enable == 1'b1)
    begin
      rd_addr_plus2 <= rd_addr_plus2 + 6'b1;
      rd_addr_plus1 <= rd_addr_plus2;
      rd_addr       <= rd_addr_plus1;
    end
  end // gen_rd_addr

  // Convert look-ahead read address pointer into a gray code
  always @(posedge rxusrclk2)
  begin : rd_addrgray_bits
    if (rxreset == 1'b1)
      rd_addr_gray <= 6'b0;
    else if (rd_enable == 1'b1)
    begin
      rd_addr_gray[5] <= rd_addr_plus2[5];
      rd_addr_gray[4] <= rd_addr_plus2[5] ^ rd_addr_plus2[4];
      rd_addr_gray[3] <= rd_addr_plus2[4] ^ rd_addr_plus2[3];
      rd_addr_gray[2] <= rd_addr_plus2[3] ^ rd_addr_plus2[2];
      rd_addr_gray[1] <= rd_addr_plus2[2] ^ rd_addr_plus2[1];
      rd_addr_gray[0] <= rd_addr_plus2[1] ^ rd_addr_plus2[0];
    end
  end // rd_addrgray_bits

  // Multiplex the double width FIFO words to single words.
  always @(posedge rxusrclk2)
  begin : gen_mux
    if (rxreset == 1'b1)
    begin
      rxchariscomma_usr   <= 1'b0;
      rxcharisk_usr       <= 1'b0;
      rxdisperr_usr       <= 1'b0;
      rxnotintable_usr    <= 1'b0;
      rxrundisp_usr       <= 1'b0;
      rxdata_usr          <= 8'b0;
    end
    else
    begin
      if (even == 1'b1)
      begin
        rxchariscomma_usr <= rd_data_reg[28];
        rxcharisk_usr     <= rd_data_reg[27];
        rxdisperr_usr     <= rd_data_reg[26];
        rxnotintable_usr  <= rd_data_reg[25];
        rxrundisp_usr     <= rd_data_reg[24];
        rxdata_usr        <= rd_data_reg[23:16];
      end
      else
      begin
        rxchariscomma_usr <= rd_data_reg[12];
        rxcharisk_usr     <= rd_data_reg[11];
        rxdisperr_usr     <= rd_data_reg[10];
        rxnotintable_usr  <= rd_data_reg[9];
        rxrundisp_usr     <= rd_data_reg[8];
        rxdata_usr        <= rd_data_reg[7:0];
      end
    end
  end // gen_mux

  // Create GTX style clock correction status when inserting /
  // removing Idles.
  always @(posedge rxusrclk2)
  begin : gen_rxclkcorcnt
    if (rxreset == 1'b1)
      rxclkcorcnt   <= 3'b0;
    else
    begin
      if (rd_data_reg[13] == 1'b1 && rxclkcorcnt[0] == 1'b0)
         rxclkcorcnt   <= 3'b001;
      else if (insert_idle_reg == 1'b1)
         rxclkcorcnt   <= 3'b111;
      else
         rxclkcorcnt   <= 3'b000;
    end
  end // gen_rxclkcorcnt

  assign rxclkcorcnt_usr = rxclkcorcnt;


  //--------------------------------------------------------------------
  // Create emptying/full thresholds in read clock domain.
  //--------------------------------------------------------------------

  // Reclock the write address pointer (gray code) onto the read domain.
  // By reclocking the gray code, the worst case senario is that
  // the reclocked value is only in error by -1, since only 1 bit at a
  // time changes between gray code increments.
  always @(posedge rxusrclk2)
  begin : reclock_wr_addrgray
    if (rxreset == 1'b1)
    begin
      rd_wr_addr_gray     <= 6'b110001;
      rd_wr_addr_gray_reg <= 6'b110000;
    end
    else
    begin
      rd_wr_addr_gray     <= wr_addr_gray;
      rd_wr_addr_gray_reg <= rd_wr_addr_gray;
    end
  end // reclock_wr_addrgray

  // Convert the resync'd Write Address Pointer grey code back to binary
  assign rd_wr_addr[5] = rd_wr_addr_gray_reg[5];

  assign rd_wr_addr[4] = rd_wr_addr_gray_reg[5] ^ rd_wr_addr_gray_reg[4];

  assign rd_wr_addr[3] = rd_wr_addr_gray_reg[5] ^ rd_wr_addr_gray_reg[4]
                         ^ rd_wr_addr_gray_reg[3];

  assign rd_wr_addr[2] = rd_wr_addr_gray_reg[5] ^ rd_wr_addr_gray_reg[4]
                         ^ rd_wr_addr_gray_reg[3] ^ rd_wr_addr_gray_reg[2];

  assign rd_wr_addr[1] = rd_wr_addr_gray_reg[5] ^ rd_wr_addr_gray_reg[4]
                         ^ rd_wr_addr_gray_reg[3] ^ rd_wr_addr_gray_reg[2]
                         ^ rd_wr_addr_gray_reg[1];

  assign rd_wr_addr[0] = rd_wr_addr_gray_reg[5] ^ rd_wr_addr_gray_reg[4]
                         ^ rd_wr_addr_gray_reg[3] ^ rd_wr_addr_gray_reg[2]
                         ^ rd_wr_addr_gray_reg[1] ^ rd_wr_addr_gray_reg[0];

  // Determine the occupancy of the FIFO as observed in the read domain.
  always @(posedge rxusrclk2)
  begin : gen_rd_occupancy
    if (rxreset == 1'b1)
      rd_occupancy <= 6'b100000;
    else
      rd_occupancy <= rd_wr_addr - rd_addr[5:0];
  end // gen_rd_occupancy

  // Set emptying flag if FIFO occupancy is less than LOWER_THRESHOLD.
  assign emptying = (rd_occupancy < lower_threshold) ? 1'b1 : 1'b0;

  // Set underflow if FIFO occupancy is less than UNDERFLOW_THRESHOLD.
  assign underflow = (rd_occupancy < underflow_threshold) ? 1'b1 : 1'b0;

  // Set overflow if FIFO occupancy is less than OVERFLOW_THRESHOLD.
  assign overflow = (rd_occupancy > overflow_threshold) ? 1'b1 : 1'b0;

  // If either an underflow or overflow, assert the buffer error signal.
  // Like the GTX, this will persist until a reset is issued.
  always @(posedge rxusrclk2)
  begin : gen_buffer_error
    if (rxreset == 1'b1)
      rxbuferr <= 1'b0;
    else if (overflow == 1'b1 || underflow == 1'b1)
      rxbuferr <= 1'b1;
  end // gen_buffer_error


  //--------------------------------------------------------------------
  // Create emptying/full thresholds in write clock domain.
  //--------------------------------------------------------------------

  // Reclock the read address pointer (gray code) onto the write domain.
  // By reclocking the gray code, the worst case senario is that
  // the reclocked value is only in error by -1, since only 1 bit at a
  // time changes between gray code increments.
  always @(posedge rxrecclk)
  begin : reclock_rd_addrgray
    if (rxrecreset == 1'b1)
    begin
      wr_rd_addr_gray     <= 6'b0;
      wr_rd_addr_gray_reg <= 6'b0;
    end
    else
    begin
      wr_rd_addr_gray     <= rd_addr_gray;
      wr_rd_addr_gray_reg <= wr_rd_addr_gray;
    end
  end // reclock_rd_addrgray

  // Convert the resync'd Read Address Pointer grey code back to binary
  assign wr_rd_addr[5] = wr_rd_addr_gray_reg[5];

  assign wr_rd_addr[4] = wr_rd_addr_gray_reg[5] ^ wr_rd_addr_gray_reg[4];

  assign wr_rd_addr[3] = wr_rd_addr_gray_reg[5] ^ wr_rd_addr_gray_reg[4]
                         ^ wr_rd_addr_gray_reg[3];

  assign wr_rd_addr[2] = wr_rd_addr_gray_reg[5] ^ wr_rd_addr_gray_reg[4]
                         ^ wr_rd_addr_gray_reg[3] ^ wr_rd_addr_gray_reg[2];

  assign wr_rd_addr[1] = wr_rd_addr_gray_reg[5] ^ wr_rd_addr_gray_reg[4]
                         ^ wr_rd_addr_gray_reg[3] ^ wr_rd_addr_gray_reg[2]
                         ^ wr_rd_addr_gray_reg[1];

  assign wr_rd_addr[0] = wr_rd_addr_gray_reg[5] ^ wr_rd_addr_gray_reg[4]
                         ^ wr_rd_addr_gray_reg[3] ^ wr_rd_addr_gray_reg[2]
                         ^ wr_rd_addr_gray_reg[1] ^ wr_rd_addr_gray_reg[0];

  // Determine the occupancy of the FIFO as observed in the write domain.
  always @(posedge rxrecclk)
  begin : gen_wr_occupancy
    if (rxrecreset == 1'b1)
      wr_occupancy <= 6'b100000;
    else
      wr_occupancy <= wr_addr[5:0] - wr_rd_addr;
  end // gen_wr_occupancy

  // Set filling flag if FIFO occupancy is greated than UPPER_THRESHOLD.
  assign filling = (wr_occupancy > upper_threshold) ? 1'b1 : 1'b0;

endmodule
