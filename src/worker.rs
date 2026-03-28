use worker::*;

#[event(fetch)]
pub async fn main(req: Request, env: Env, _ctx: worker::Context) -> Result<Response> {
    let mut ipu = HyzeServerlessIpu::new();
    
    let body: serde_json::Value = json_from_req(&req)?;
    let model = body["model"].as_str().unwrap_or("mnist");
    let input: Vec<u8> = base64::decode(body["input"].as_str().unwrap()).unwrap();
    
    // 0ms cold-start!
    let result = ipu.instant_inference(model, input).await;
    
    Response::from_json(&result)?
}
