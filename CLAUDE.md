# FlowTunnel Project Guidelines

## Project Overview
FlowTunnel is now a **multi-platform Swift Package** (FlowTunnelKit) featuring a procedural star tunnel effect with gravitational lensing. The package provides a clean SwiftUI API for iOS 26+, macOS 13+, and visionOS 1+. All rendering is done via Metal fragment shader with real-time parameter control.

## Architecture

### Swift Package Structure
```
FlowTunnel/
├── Package.swift                    # Swift Package manifest
├── Sources/FlowTunnelKit/
│   ├── Core/                        # Platform-independent types
│   │   ├── StarTunnelConfiguration.swift  # User configuration API
│   │   ├── StarUniforms.swift            # GPU uniform struct
│   │   └── StarTunnelError.swift         # Error types
│   ├── Metal/                       # Metal rendering engine
│   │   ├── MetalStarTunnelRenderer.swift # GPU pipeline & rendering
│   │   └── ShaderLibrary.swift           # Shader loading from bundle
│   ├── Platform/                    # Cross-platform bridges
│   │   ├── PlatformTypes.swift           # UIKit/AppKit type aliases
│   │   ├── StarTunnelViewBridge.swift    # Base bridge
│   │   ├── iOS/StarTunnelViewBridge+iOS.swift
│   │   └── macOS/StarTunnelViewBridge+macOS.swift
│   ├── Resources/
│   │   └── StarTunnel.metal         # Fragment/vertex shaders
│   └── StarTunnelView.swift         # Public SwiftUI view
├── Tests/FlowTunnelKitTests/        # Unit tests
│   ├── ConfigurationTests.swift
│   ├── UniformTests.swift
│   ├── RendererTests.swift
│   ├── ShaderLibraryTests.swift
│   └── ErrorTests.swift
├── Examples/FlowTunnelApp/          # Example iOS app
│   ├── FlowTunnelApp.xcodeproj/
│   └── FlowTunnelApp/
│       ├── FlowTunnelApp.swift
│       └── Views/ContentView.swift
├── FlowTunnel/                      # Legacy app (kept for reference)
└── README.md                        # Package documentation
```

### Key Files
| File | Purpose | Language |
|------|---------|----------|
| **Package API** | | |
| `StarTunnelView.swift` | Public SwiftUI view component | Swift |
| `StarTunnelConfiguration.swift` | User-facing parameter struct | Swift |
| `StarTunnelError.swift` | Error cases for initialization | Swift |
| **Rendering** | | |
| `MetalStarTunnelRenderer.swift` | Metal renderer managing GPU pipeline | Swift |
| `ShaderLibrary.swift` | Loads shaders from Bundle.module | Swift |
| `StarTunnel.metal` | Fragment shader (star field + lensing) | Metal |
| `StarUniforms.swift` | GPU uniform struct (mirrors Metal) | Swift |
| **Platform** | | |
| `StarTunnelViewBridge+iOS.swift` | UIViewRepresentable bridge | Swift |
| `StarTunnelViewBridge+macOS.swift` | NSViewRepresentable bridge | Swift |
| **Example** | | |
| `Examples/.../ContentView.swift` | Demo app with warp controls | Swift |

### Parameters
All parameters are Float values with ranges:
- **Speed** (0-3): Star animation speed
- **Stretch** (0-3): Radial star elongation
- **Blur** (0-1): Star glow softness
- **Density** (0.1-2): Star field density (10-40 depth layers)
- **Size** (0.1-3): Base star size
- **Black Hole** (0-0.5): Event horizon radius
- **BH Warp** (0-3): Gravitational lensing strength

## Using Xcode MCP Tools

### When to Use Each Tool

#### `XcodeRead` - Reading files
```
Use for: Examining existing code, checking implementations
Example: Before making changes, read the target file to understand structure
```

#### `XcodeGrep` - Searching code
```
Use for: Finding function definitions, parameter usages, patterns
Example: grep for "hash21" to find all hash function calls
Pattern: Use regex, supports multiline with multiline: true
```

#### `XcodeWrite` - Creating files
```
Use for: Adding new files to the project
Path format: 'ProjectName/path/to/File.swift'
Auto-adds to project structure
```

#### `XcodeUpdate` - Editing files
```
Use for: Modifying existing code
Replace entire sections with context for accuracy
old_string must be unique; add surrounding context if needed
```

#### `XcodeGlob` - File discovery
```
Use for: Finding files by pattern (*.metal, **/*.swift)
Example: Find all shader files with pattern '**/*.metal'
```

#### `XcodeLS` - Directory browsing
```
Use for: Exploring project structure, listing files
Example: Check what's in Shaders/ directory
```

#### `XcodeRefreshCodeIssuesInFile` - Compiler diagnostics
```
Use for: Getting errors/warnings for a specific file
Returns line-by-line compiler diagnostics
```

#### `BuildProject` - Compile project
```
Use for: After major changes, verify build succeeds
Wait for completion before proceeding
```

#### `RenderPreview` - SwiftUI previews
```
Use for: Testing UI changes in preview canvas
Use after ContentView modifications
```

### Workflow Pattern

When making changes to the project:

1. **Read** the target file to understand current implementation
2. **Grep** to find related code if not immediately obvious
3. **Update** the file with changes
4. **Build** to verify no compilation errors
5. **Refresh Issues** if build fails to get detailed diagnostics
6. **Update CLAUDE.md** with any structural changes

## Metal Shader Architecture

### Fragment Shader Execution (per pixel)
```
1. UV Mapping
   - Convert pixel coords to centered space (-1 to 1)
   - Save original UV for event horizon

2. Gravitational Lensing (if blackHoleRadius > 0)
   - Apply Schwarzschild-inspired deflection
   - Distort UV coordinates radially outward

3. Volumetric Star Rendering (layer loop)
   for each depth layer (10-40 depending on density):
     - Compute grid scale and fade based on depth
     - Hash grid cells to place stars
     - Calculate distance with optional radial stretch
     - Accumulate Gaussian glow brightness

4. Tone Mapping
   - Exponential compression to displayable range

5. Event Horizon Compositing
   - Multiply by smoothstep mask (creates black disk)
```

### Key Shader Parameters
- **time**: Elapsed seconds, drives animation
- **speed**: Multiplier on time
- **density**: Controls numLayers (10-40) and star threshold
- **blur**: Glow width for Gaussian falloff
- **stretch**: Radial elongation factor for stars
- **size**: Base radius for star brightness calculation
- **blackHoleRadius**: Event horizon radius (0 = disabled)
- **blackHoleWarp**: Lensing strength multiplier

## Documentation Standards

### Swift Files
- SwiftUI views: Self-documenting (code is clear) - minimal docs
- Complex functions: Document parameters, return values, algorithm
- Classes: Document high-level purpose and behavior

### Metal Files
- Include detailed comments explaining math
- Section headers for major algorithm blocks
- Inline explanations for non-obvious calculations

## Common Tasks

### Using the Package in a New Project
1. Add FlowTunnelKit as a Swift Package dependency
2. Import `FlowTunnelKit` in your SwiftUI view
3. Create a `@State var config = StarTunnelConfiguration()`
4. Add `StarTunnelView(configuration: $config)` to your view
5. Adjust parameters via `config.speed`, `config.blur`, etc.

### Adding a New Parameter
1. Add to `StarTunnelConfiguration` struct in `Core/`
2. Add to `StarUniforms` struct (both Swift and Metal, maintain order)
3. Update `StarUniforms.init(config:time:resolution:enableEDR:)`
4. Update shader code in `StarTunnel.metal` to use new parameter
5. Run `swift test` to verify
6. Update README.md parameter documentation

### Modifying Shader Algorithm
1. Read `StarTunnel.metal` to understand current flow
2. Make shader changes
3. Update relevant uniform if needed
4. Build and test
5. Update CLAUDE.md with algorithm changes if significant

### Fixing Compilation Errors
1. Run `BuildProject`
2. Use `XcodeRefreshCodeIssuesInFile` for specific diagnostics
3. Use `XcodeGrep` to find related code
4. Fix and rebuild

## Performance Considerations

- Shader is ~150 lines, fully GPU-accelerated
- Per-frame cost: Time update, uniform buffer creation, single fullscreen render call
- No additional texture samples or loops beyond the intentional depth layer loop
- 60 FPS target on device maintained

## Build Settings

### Package
- **Platforms**: iOS 26.0+, macOS 13.0+, visionOS 1.0+
- **Swift Version**: 6.0
- **Swift Concurrency**: Strict concurrency enabled
- **Resources**: StarTunnel.metal processed via Bundle.module

### Example App
- **Deployment Target**: iOS 26.2
- **Swift Version**: 6.0
- **Swift Concurrency**: Strict (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor)
- **Metal Fast Math**: Enabled (MTL_FAST_MATH = YES)
- **Team ID**: H2WYXEJN79
- **Bundle ID**: com.alextrubacs.FlowTunnel

## Development Workflow

### Building the Package
```bash
swift build          # Build for current platform
swift test           # Run all tests (17 tests across 5 suites)
```

### Running the Example App
```bash
cd Examples/FlowTunnelApp
open FlowTunnelApp.xcodeproj
# Build and run on simulator or device
```

### Testing on Different Platforms
- **iOS**: Run example app on iPhone/iPad simulator or device
- **macOS**: Package builds natively, create macOS target app as needed
- **visionOS**: Package supports visionOS 1.0+, untested (requires visionOS SDK)

---

**Last Updated**: 2026-02-06
**Session**: Multi-platform Swift Package migration completed
- Created FlowTunnelKit Swift Package with iOS 26+, macOS 13+, visionOS 1+ support
- Extracted platform-independent types (Configuration, Uniforms, Errors)
- Implemented cross-platform view bridges (iOS/macOS)
- Added comprehensive test suite (17 tests, all passing)
- Created example app demonstrating package usage
- Documented package structure and API in README.md
