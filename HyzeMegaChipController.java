@RestController
public class HyzeMegaChipController {
    private final NativeIpuLoader ipuLoader = new NativeIpuLoader();
    private final CudaGpu gpu = new CudaGpu();
    
    @PostMapping("/train")
    public Map<String, Float> trainStep(@RequestBody Batch batch) {
        // Java orchestrates hybrid compute
        int[] ipuForward = ipuLoader.forward(batch.pixels);  // ASM IPU: 0.1μs
        float[] gpuGrads = gpu.backprop(ipuForward);         // CUDA heavy
        ipuLoader.loraUpdate(gpuGrads);                      // IPU fine-tune
        
        return Map.of("loss", computeLoss(gpuGrads));
    }
    
    static {
        System.loadLibrary("hyze_ipu");  // Links ASM + C++ driver
    }
}
