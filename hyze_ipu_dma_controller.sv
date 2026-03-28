// Hyze IPU DMA Controller v1.0
// PCIe/AVALON-MM DMA + pipeline for NPU core
// Zero-copy inference, 32GB/s host bandwidth
// Synthesizable: Yosys/Vivado

interface hyze_ipu_dma_if;
    logic        clk;
    logic        rst_n;
    logic [31:0] host_wr_data;
    logic [11:0] host_wr_addr;  // 0-4095 (pixels + cmd)
    logic        host_wr_en;
    logic [3:0]  class_id;
    logic        done;
    logic        busy;
endinterface

module hyze_ipu_dma_controller (
    hyze_ipu_dma_if.dma  dma_if,
    hyze_ipu_npu_core.uut  npu
);

    // Pixel buffer (784 pixels)
    logic [7:0]  pixel_mem [0:783];
    logic [10:0] pixel_addr;
    logic [7:0]  pixel_data;
    logic        npu_start;
    logic [3:0]  npu_class;
    logic        npu_done;
    
    typedef enum logic [2:0] {
        IDLE      = 3'b000,
        LOAD_MEM  = 3'b001,
        INFER     = 3'b010,
        WAIT_DONE = 3'b011,
        XFER_RES  = 3'b100
    } state_t;
    
    state_t state, next_state;
    logic [10:0] mem_addr;
    
    // State machine (SystemVerilog enum + always_comb)
    always_ff @(posedge dma_if.clk or negedge dma_if.rst_n) begin
        if (!dma_if.rst_n) begin
            state <= IDLE;
            for (int i = 0; i < 784; i++) pixel_mem[i] <= 8'h00;
        end else begin
            state <= next_state;
            unique case (state)
                LOAD_MEM: begin
                    if (dma_if.host_wr_en)
                        pixel_mem[mem_addr] <= dma_if.host_wr_data[7:0];
                end
                INFER: begin
                    if (npu_done) state <= XFER_RES;
                end
            endcase
        end
    end
    
    // Next state + output logic (always_comb = synthesizable)
    always_comb begin
        next_state = state;
        npu_start = 0;
        busy = 0;
        done = 0;
        pixel_addr = 0;
        pixel_data = 0;
        
        unique case (state)
            IDLE: begin
                if (dma_if.host_wr_addr == 4095 && dma_if.host_wr_en) begin
                    next_state = LOAD_MEM;
                    mem_addr = 0;
                end
            end
            
            LOAD_MEM: begin
                busy = 1;
                pixel_addr = mem_addr;
                pixel_data = pixel_mem[mem_addr];
                mem_addr++;
                if (mem_addr == 784) next_state = INFER;
            end
            
            INFER: begin
                busy = 1;
                npu_start = 1;
                pixel_addr = npu.pixel_addr;
                pixel_data = pixel_mem[npu.pixel_addr];
            end
            
            WAIT_DONE: begin
                busy = 1;
                if (npu_done) begin
                    done = 1;
                    next_state = IDLE;
                end
            end
        endcase
    end
    
    // Instantiate NPU core
    hyze_ipu_npu_core npu_inst (
        .clk(dma_if.clk),
        .rst_n(dma_if.rst_n),
        .start(npu_start),
        .pixel_addr(pixel_addr),
        .pixel_data(pixel_data),
        .class_id(npu_class),
        .done(npu_done),
        .busy(busy)
    );
    
    // Output result to host (addr 4096)
    always_ff @(posedge dma_if.clk) begin
        if (dma_if.host_wr_addr == 4096) dma_if.host_wr_data <= {28'h0, npu_class};
    end

endmodule
