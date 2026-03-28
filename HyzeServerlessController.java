@Function("hyze-serverless")
public class HyzeServerlessController {
    
    @CloudEvent("ai.inference")
    public ApigwProxyResponse instantInfer(ApigwProxyRequestEvent input) {
        // Cloudflare Workers call (0ms)
        var result = cloudflareClient.invokeWasm("hyze_ipu_wasm", input);
        return new ApigwProxyResponse(200, result);
    }
}
