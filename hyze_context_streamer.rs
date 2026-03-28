pub async fn stream_10m_context(&mut self, tokens: &[u32]) -> Vec<u32> {
    tokens.chunks(1024).par_iter().map(|chunk| {
        self.ipu_tile.forward_stream(chunk)  // 64 tiles parallel
    }).flatten().collect()
}
