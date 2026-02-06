# FlowTunnel Project Guidelines

## Project Overview
FlowTunnel is an iOS app featuring a procedural star tunnel effect with gravitational lensing around a black hole. All rendering is done via Metal fragment shader with real-time parameter control.

## Architecture

### Directory Structure
```
FlowTunnel/
├── FlowTunnel/
│   ├── FlowTunnelApp.swift          # App entry point
│   ├── Views/
│   │   ├── ContentView.swift        # Main UI with parameter controls
│   │   └── MetalStarTunnelView.swift # Metal renderer (GPU bridge)
│   └── Shaders/
│       └── StarTunnel.metal         # Fragment/vertex shaders
├── FlowTunnel.xcodeproj/
└── CLAUDE.md                        # This file
```

### Key Files
| File | Purpose | Language |
|------|---------|----------|
| `FlowTunnelApp.swift` | App initialization, dark mode, status bar hiding | Swift |
| `ContentView.swift` | SwiftUI view with parameter sliders (Speed, Stretch, Blur, Density, Size, Black Hole, BH Warp) | Swift |
| `MetalStarTunnelView.swift` | Metal renderer managing GPU pipeline, shader compilation, frame rendering | Swift |
| `StarTunnel.metal` | Fullscreen shader: star field generation, gravitational lensing, event horizon | Metal |

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

### Adding a New Parameter
1. Add to `StarUniforms` struct in both Metal and Swift (maintain order)
2. Add property to `MetalStarTunnelRenderer`
3. Add to `StarUniforms` init in `draw(in:)` method
4. Add to `StarTunnelView` parameter
5. Wire through `makeUIView()` and `updateUIView()`
6. Add `@State` to `ContentView`
7. Add slider in `controlsPanel`
8. Build and test

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
- **Deployment Target**: iOS 26.2
- **Swift Version**: 6.0
- **Swift Concurrency**: Strict (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor)
- **Metal Fast Math**: Enabled (MTL_FAST_MATH = YES)
- **Team ID**: H2WYXEJN79
- **Bundle ID**: com.alextrubacs.FlowTunnel

---

**Last Updated**: 2026-02-06
**Session**: Documentation pass + Xcode MCP guidelines added
