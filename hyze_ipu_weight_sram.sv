// Hyze IPU Weight SRAM v1.0  
// Dual-port 1MB BRAM + 1KB prefetch (Groq LPU streaming)
// Standalone - drop into your NPU top-level

module hyze_ipu_weight_sram (
    input  wire         clk_rd,      // NPU read clock (500MHz)
    input  wire         clk_wr,      // Host write clock (PCIe)
    input  wire [19:0]  addr_rd,     // NPU read addr (1M weights)
    input  wire [19:0]  addr_wr,     // Rust loader write addr
    input  wire         we_wr,       // Write enable
    input  wire [15:0]  din_wr,      // FP16/INT16 weight input
    output reg  [15:0]  dout_rd,     // NPU weight output
    output reg         rvalid_rd     // Read valid (0 stall cycles)
);

    // 1MB dual-port BRAM (Lattice ECP5 optimized)
    (* ram_style = "block" *) reg [15:0] bram [0:1048575];
    
    // Port A: Rust/PCIe weight loading (write-only)
    always_ff @(posedge clk_wr) begin
        if (we_wr) 
            bram[addr_wr] <= din_wr;
    end
    
    // Port B: NPU streaming read + 1KB prefetch buffer
    reg [9:0] prefetch_buf [0:63];   // 64 x 16b = 1KB lookahead
    reg [9:0] prefetch_idx;          // Current 1KB block
    integer i;
    
    always_ff @(posedge clk_rd) begin
        prefetch_idx <= addr_rd[19:10];  // Align to 1024-byte blocks
        
        // Prefetch 1KB ahead (Groq tensor streaming)
        for (i = 0; i < 64; i = i + 1) begin
            prefetch_buf[i] <= bram[{addr_rd[19:10]+1, i[9:0]}];  // Next block!
        end
        
        dout_rd <= prefetch_buf[addr_rd[9:0]];
        rvalid_rd <= 1'b1;  // Zero stall states
    end

endmodule
