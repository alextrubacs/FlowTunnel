# Swift Architect Executor - FlowTunnel Project Memory

## Project Architecture

**FlowTunnelKit** is a multi-platform Swift Package providing real-time GPU-rendered star tunnel effects with gravitational lensing.

### Key Architecture Decisions

1. **Cross-Platform Strategy**: Use protocol-based platform abstraction
   - `PlatformTypes.swift` provides type aliases for UIKit/AppKit
   - Platform-specific extensions in `Platform/iOS/` and `Platform/macOS/`
   - Keeps platform code isolated, core logic platform-independent

2. **Resource Loading Pattern**: Use `Bundle.module` for SPM resources
   - Metal shaders loaded as package resources via `.process("Resources")`
   - `ShaderLibrary` loads shader source from bundle URL
   - Compiles shader at runtime using `device.makeLibrary(source:)`

3. **Configuration API Design**: Binding-based reactive updates
   - `StarTunnelConfiguration` is the user-facing API (Sendable struct)
   - `StarUniforms` is internal GPU data layout (mirrors Metal struct)
   - Configuration changes propagate via `updateUIView()` / `updateNSView()`

4. **Error Handling**: Throwing initializers with descriptive errors
   - `MetalStarTunnelRenderer.init()` throws `StarTunnelError`
   - Clear error messages for shader loading, pipeline creation failures
   - Tests verify all error cases have meaningful descriptions

### Platform Version Requirements

- **iOS**: 26.0 minimum (use string syntax in Package.swift: `.iOS("26.0")`)
- **macOS**: 13.0 (use enum syntax: `.macOS(.v13)`)
- **visionOS**: 1.0 (use enum syntax: `.visionOS(.v1)`)

**Important**: iOS 26 requires PackageDescription 6.2, but we use swift-tools-version 6.0. The string syntax `.iOS("26.0")` works around this limitation.

### Metal Shader Integration

- Shader must be **exactly copied** (no modifications during migration)
- Uniform struct field order must match between Swift and Metal exactly
- Memory layout: 11 floats = 44 bytes (verified by test)
- Shader functions: `starTunnelVertex` and `starTunnelFragment`

### Test Coverage

17 tests across 5 suites:
- ConfigurationTests: Default values, custom init, mutability, Sendable conformance
- UniformTests: Init from config, EDR flag conversion, memory size
- RendererTests: Init, config updates, EDR state changes
- ShaderLibraryTests: Loading, function retrieval, error cases
- ErrorTests: Error descriptions, function names in errors

All tests pass on macOS (arm64). iOS testing via Xcode project.

## Common Patterns

### Creating Platform-Specific View Bridges

```swift
// Base bridge (StarTunnelViewBridge.swift)
public struct MyViewBridge: PlatformViewRepresentable {
    // Shared coordinator and state
}

// iOS extension (Platform/iOS/MyViewBridge+iOS.swift)
#if canImport(UIKit)
extension MyViewBridge {
    public func makeUIView(context: Context) -> UIView { }
    public func updateUIView(_ view: UIView, context: Context) { }
}
#endif

// macOS extension (Platform/macOS/MyViewBridge+macOS.swift)
#if canImport(AppKit)
extension MyViewBridge {
    public func makeNSView(context: Context) -> NSView { }
    public func updateNSView(_ view: NSView, context: Context) { }
}
#endif
```

### Loading Resources from Swift Package

```swift
guard let resourceURL = Bundle.module.url(forResource: "File", withExtension: "ext") else {
    throw MyError.resourceNotFound
}
```

### Swift 6 Concurrency with MTKViewDelegate

`MetalStarTunnelRenderer` uses `@unchecked Sendable`:
- MTKViewDelegate requires NSObject conformance
- Renderer state is accessed only from render thread (thread-safe by Metal design)
- `currentFPS` is read-only, updated atomically during rendering

Coordinator uses `@unchecked Sendable` to pass renderer reference to async FPS polling task.

## Build Commands

```bash
# Build package for current platform
swift build

# Run all tests
swift test

# Clean rebuild
rm -rf .build && swift build

# Run example app
cd Examples/FlowTunnelApp && open FlowTunnelApp.xcodeproj
```

## Project Structure Convention

- `Core/`: Platform-independent types (Configuration, Uniforms, Errors)
- `Metal/`: Rendering engine and shader loading
- `Platform/`: Cross-platform abstractions (only #if os() code here)
- `Resources/`: Shader files and other resources
- `Tests/`: Unit tests organized by component

## Lessons Learned

1. **iOS 26 version syntax**: Use `.iOS("26.0")` string syntax to avoid PackageDescription version mismatch
2. **Test assertions**: Use `Bool(true)` instead of `true` to silence testing framework warnings
3. **Foundation import**: Required for `NSError` in test files
4. **Shader library loading**: Load shader source as string, compile at runtime (not precompiled library)
5. **Package.swift resources**: Use `.process("Resources")` to copy non-code resources

## Files Modified (4+ files)

Updated CLAUDE.md with:
- New Swift Package structure documentation
- Updated key files table
- Package usage instructions
- Development workflow commands
- Session notes on migration

Created README.md with comprehensive package documentation including ELI5 Metal explanation.
