#if os(macOS)
  import AppKit
  import Cocoa
  import QuartzCore

  extension Snapshotting where Value == CALayer, Format == NSImage {
    /// A snapshot strategy for comparing layers based on pixel equality.
    ///
    /// ``` swift
    /// // Match reference perfectly.
    /// assertSnapshot(of: layer, as: .image)
    ///
    /// // Allow for a 1% pixel difference.
    /// assertSnapshot(of: layer, as: .image(precision: 0.99))
    /// ```
    public static var image: Snapshotting {
      return .image(precision: 1)
    }

    /// A snapshot strategy for comparing layers based on pixel equality.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - renderingDelay: The amount of time to wait before rendering the layer, giving async
    ///     content (images, animations, etc.) time to finish loading.
    public static func image(
      precision: Float, perceptualPrecision: Float = 1, renderingDelay: TimeInterval = 0
    ) -> Snapshotting {
      return SimplySnapshotting.image(
        precision: precision, perceptualPrecision: perceptualPrecision
      ).asyncPullback { layer in
        Async { callback in
          DispatchQueue.main.asyncAfter(deadline: .now() + renderingDelay) {
            let image = NSImage(size: layer.bounds.size)
            image.lockFocus()
            let context = NSGraphicsContext.current!.cgContext
            layer.setNeedsLayout()
            layer.layoutIfNeeded()
            layer.render(in: context)
            image.unlockFocus()
            callback(image)
          }
        }
      }
    }
  }
#elseif os(iOS) || os(tvOS)
  import UIKit

  extension Snapshotting where Value == CALayer, Format == UIImage {
    /// A snapshot strategy for comparing layers based on pixel equality.
    public static var image: Snapshotting {
      return .image()
    }

    /// A snapshot strategy for comparing layers based on pixel equality.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - traits: A trait collection override.
    ///   - renderingDelay: The amount of time to wait before rendering the layer, giving async
    ///     content (images, animations, etc.) time to finish loading.
    public static func image(
      precision: Float = 1,
      perceptualPrecision: Float = 1,
      traits: UITraitCollection = .init(),
      renderingDelay: TimeInterval = 0
    )
      -> Snapshotting
    {
      return SimplySnapshotting.image(
        precision: precision, perceptualPrecision: perceptualPrecision, scale: traits.displayScale
      ).asyncPullback { layer in
        Async { callback in
          DispatchQueue.main.asyncAfter(deadline: .now() + renderingDelay) {
            let image = renderer(bounds: layer.bounds, for: traits).image { ctx in
              layer.setNeedsLayout()
              layer.layoutIfNeeded()
              layer.render(in: ctx.cgContext)
            }
            callback(image)
          }
        }
      }
    }
  }
#endif
