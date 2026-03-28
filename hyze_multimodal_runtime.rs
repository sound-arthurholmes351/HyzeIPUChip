pub async fn multimodal_query(&mut self, query: MultiModalInput) -> Embedding {
    // Parallel dispatch (64 tiles = 120μs)
    let (text_emb, image_emb, audio_emb) = tokio::try_join!(
        self.tiles[0..16].text_pipeline(&query.text),
        self.tiles[16..32].vision_pipeline(&query.image),
        self.tiles[32..48].audio_pipeline(&query.audio)
    )?;
    
    self.tiles[48..64].fusion([text_emb, image_emb, audio_emb].into())
        .await  // CLIP-style unified embedding
}
