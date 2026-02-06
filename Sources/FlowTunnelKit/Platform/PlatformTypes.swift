/// Platform-specific type aliases for cross-platform compatibility.
///
/// This file provides unified type aliases that map to the appropriate platform types
/// (UIKit or AppKit) depending on the compilation target.

#if canImport(UIKit)
import UIKit
import SwiftUI

/// Platform-specific view representable protocol.
public typealias PlatformViewRepresentable = UIViewRepresentable

/// Platform-specific Metal view type.
public typealias PlatformMetalView = UIView

#elseif canImport(AppKit)
import AppKit
import SwiftUI

/// Platform-specific view representable protocol.
public typealias PlatformViewRepresentable = NSViewRepresentable

/// Platform-specific Metal view type.
public typealias PlatformMetalView = NSView

#endif
