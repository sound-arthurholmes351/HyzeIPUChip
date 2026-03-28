@PostMapping("/zk_inference")
public ZKProofResponse inferSecure(@RequestBody EncryptedInput input) {
    // Prove computation without revealing data
    ZKProof proof = ipu.generateProof(input.ciphertext);
    return new ZKProofResponse(proof.verify(), ipu.class_id());
}
