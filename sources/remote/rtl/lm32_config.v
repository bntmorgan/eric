`ifdef LM32_CONFIG_V
`else
`define LM32_CONFIG_V

`ifdef RESCUE
`define CFG_EBA_RESET 32'h00220000
`define CFG_DEBA_RESET 32'h10000000
`else
`define CFG_EBA_RESET 32'h00860000
`define CFG_DEBA_RESET 32'h10000000
`endif

`define CFG_PL_MULTIPLY_ENABLED
`define CFG_PL_BARREL_SHIFT_ENABLED
`define CFG_SIGN_EXTEND_ENABLED
`define CFG_MC_DIVIDE_ENABLED
`define CFG_EBR_POSEDGE_REGISTER_FILE

/*
 * NOTE: when new parser is not activated, do not activate intruction or
 * data cache. The code will not execute correctly.
 */

// `define CFG_ICACHE_ENABLED
// `define CFG_ICACHE_ASSOCIATIVITY   1
// `define CFG_ICACHE_SETS            256
// `define CFG_ICACHE_BYTES_PER_LINE  16
// `define CFG_ICACHE_BASE_ADDRESS    32'h0
// `define CFG_ICACHE_LIMIT           32'h7fffffff

// `define CFG_DCACHE_ENABLED
// `define CFG_DCACHE_ASSOCIATIVITY   1
// `define CFG_DCACHE_SETS            256
// `define CFG_DCACHE_BYTES_PER_LINE  16
// `define CFG_DCACHE_BASE_ADDRESS    32'h0
// `define CFG_DCACHE_LIMIT           32'h7fffffff

// Enable Debugging
//`define CFG_JTAG_ENABLED
//`define CFG_JTAG_UART_ENABLED
//`define CFG_DEBUG_ENABLED
//`define CFG_HW_DEBUG_ENABLED
//`define CFG_ROM_DEBUG_ENABLED
//`define CFG_BREAKPOINTS 32'h4
//`define CFG_WATCHPOINTS 32'h4
//`define CFG_EXTERNAL_BREAK_ENABLED
//`define CFG_GDBSTUB_ENABLED

// Define CFG_CLOG2_EXT to export CLOG2 to an external file
// Avoid synthesis failure as functions have to be defined inside modules
`define CFG_CLOG2_EXT
`ifndef CFG_CLOG2_EXT
function integer clog2;
  input integer value;
  begin
    value = value - 1;
    for (clog2 = 0; value > 0; clog2 = clog2 + 1)
      value = value >> 1;
  end
endfunction
`define CLOG2 clog2
`endif

`endif
