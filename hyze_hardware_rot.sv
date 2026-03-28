module hyze_hardware_rot (
    input clk, rst_n,
    input [255:0] fw_hash,     // Firmware hash
    output reg  trusted_fw     // FAIL = no execution
);
    // Burned at fab - 256-bit golden hash
    parameter GOLDEN_FW_HASH = 256'hDEADBEEF...;
    
    always_comb begin
        trusted_fw = (fw_hash == GOLDEN_FW_HASH);
    end
endmodule
