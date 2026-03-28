# Save as test_hyze_ipu.v
`include "hyze_ipu_npu_core.v"
module tb;
    reg clk = 0, rst_n = 0, start = 0;
    reg [10:0] addr; reg [7:0] data;
    wire [3:0] class_id; wire done, busy;
    
    hyze_ipu_npu_core uut (.*);
    
    always #1 clk = ~clk;
    
    initial begin
        #10 rst_n = 1;
        #10 start = 1; #2 start = 0;
        // Feed test image (addr/data from Rust)
        @(posedge done) $display("Predicted digit: %d", class_id);
        $finish;
    end
endmodule

# Run: iverilog -o test.vvp test_hyze_ipu.v && vvp test.vvp
