module hyze_ipu_sram_bank (
    input clk,
    input [19:0] addr,  // 1M weights
    input [15:0] wdata,
    input we,
    output reg [15:0] rdata
);
    reg [15:0] mem [0:1048575];  // 2MB SRAM
    // Dual-port for streaming...
endmodule
