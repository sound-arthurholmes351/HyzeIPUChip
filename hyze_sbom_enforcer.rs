pub struct HyzeSupplyChain {
    sbom: cyclonedx::Bom,
}

impl HyzeSupplyChain {
    pub fn verify_pipeline(&self) -> Result<()> {
        // Reject ANY unsigned/tainted crate
        for component in &self.sbom.components {
            if !component.pgp_signature.verify() {
                return Err("Supply chain attack detected");
            }
        }
        Ok(())
    }
}
