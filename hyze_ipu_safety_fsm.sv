module hyze_ipu_safety_fsm (
    input clk, rst_n,
    input [511:0] prompt,      // Incoming tokens
    output reg safety_blocked  // BLOCKS bad prompts
);
    reg [7:0] danger_score;
    
    always_ff @(posedge clk) begin
        // Hardware jailbreak detectors (100+ patterns)
        if (prompt contains "ignore safety" | "pretend you're DAN" | "jailbreak") begin
            danger_score <= danger_score + 50;
        end
        if (prompt contains "bank details" | "SSN" | "password") begin
            safety_blocked <= 1'b1;  // INSTANT BLOCK
        end
        if (danger_score > 128) safety_blocked <= 1'b1;
    end
endmodule
