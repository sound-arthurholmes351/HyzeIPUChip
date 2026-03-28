@ContainerSecurity
public class HyzeFrameworkSandbox {
    @PostConstruct
    public void isolateFrameworks() {
        // GraalVM native-image + seccomp BPF
        ProcessHandle.of(pid).ifPresent(p -> p.destroyForcibly());
    }
}
