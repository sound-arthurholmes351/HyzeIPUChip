pub struct HyzeConfidentialEnclave {
    sealed_memory: SealedBox,
}

impl HyzeConfidentialEnclave {
    pub fn secure_forward_v2(&mut self, encrypted_pixels: &[u8]) -> Result<u8> {
        let decrypted = self unsealed.decrypt(encrypted_pixels)?;
        let result = self.ipu.forward_sealed(&decrypted)?;
        self.sealed_memory.zeroize_all();
        Ok(result)
    }
}
