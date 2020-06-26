//
//  PointerInteraction.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 6/26/20.
//

import UIKit
import BlueprintUI


public extension Element {
    
    func pointerInteraction(
        with style : @escaping (UIKeyModifierFlags) -> PointerInteraction.Style = { _ in .automatic }
    ) -> Element {
        PointerInteraction(self)
    }
}

public struct PointerInteraction : Element
{
    public var wrapping : Element
    
    public var style : (UIKeyModifierFlags) -> Style
    
    public init(
        _ wrapping : Element,
        with style : @escaping (UIKeyModifierFlags) -> Style = { _ in .automatic }
    ) {
        self.wrapping = wrapping
        self.style = style
    }
    
    public var content: ElementContent {
        .init(child: self.wrapping)
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        
        View.describe { config in
            config.builder = {
                View(frame: bounds, model: self)
            }
            
            config[\.model] = self
        }
    }
}


public extension PointerInteraction {
    
    enum Style {
        
        case effect(Effect, Shape? = nil)
        case shape(Shape, Axis)
        case hidden
        
        public static var automatic : Style {
            .effect(.automatic, nil)
        }
        
        @available(iOS 13.4, *)
        func toSystem(with view : UIView) -> UIPointerStyle {
            switch self {
            case .effect(let effect, let shape):
                return UIPointerStyle(effect: effect.toSystem(with: view), shape: shape?.toSystem)
            case .shape(let shape, let axis):
                return UIPointerStyle(shape: shape.toSystem, constrainedAxes: axis.toSystem)
            case .hidden:
                return .hidden()
            }
        }
    }
    
    
    enum Effect {
        
        public enum TintMode : Equatable {

            case none
            case overlay
            case underlay
            
            @available(iOS 13.4, *)
            var toSystem : UIPointerEffect.TintMode {
                switch self {
                case .none: return .none
                case .overlay: return .overlay
                case .underlay: return .underlay
                }
            }
        }

        case automatic

        case highlight

        case lift

        case hover(preferredTintMode: TintMode = .overlay, prefersShadow: Bool = false, prefersScaledContent: Bool = true)
        
        @available(iOS 13.4, *)
        func toSystem(with view : UIView) -> UIPointerEffect {
            switch self {
            case .automatic:
                return .automatic(UITargetedPreview(view: view))
                
            case .highlight:
                return .highlight(UITargetedPreview(view: view))
                
            case .lift:
                return .lift(UITargetedPreview(view: view))
                
            case .hover(let preferredTintMode, let prefersShadow, let prefersScaledContent):
                return .hover(
                    UITargetedPreview(view: view),
                    preferredTintMode: preferredTintMode.toSystem,
                    prefersShadow: prefersShadow,
                    prefersScaledContent: prefersScaledContent
                )
            }
        }
    }
    
    
    enum Shape {

        case path(UIBezierPath)

        case roundedRect(CGRect, radius: CGFloat = Shape.defaultCornerRadius)

        case verticalBeam(length: CGFloat)

        case horizontalBeam(length: CGFloat)

        public static var defaultCornerRadius: CGFloat {
            if #available(iOS 13.4, *) {
                return UIPointerShape.defaultCornerRadius
            } else {
                return 0.0
            }
        }
        
        @available(iOS 13.4, *)
        var toSystem : UIPointerShape {
            switch self {
            case .path(let path):
                return .path(path)
            case .roundedRect(let rect, let radius):
                return .roundedRect(rect, radius: radius)
            case .verticalBeam(let length):
                return .verticalBeam(length: length)
            case .horizontalBeam(let length):
                return .horizontalBeam(length: length)
            }
        }
    }
    
    
    struct Axis : OptionSet {
        
        public let rawValue: Int
        
        public init(rawValue : Int) {
            self.rawValue = rawValue
        }
        
        public static var horizontal: Axis {
            Axis(rawValue: 0 << 1)
        }

        public static var vertical: Axis {
            Axis(rawValue: 0 << 2)
        }

        public static var both: Axis {
            [.horizontal, .vertical]
        }
        
        @available(iOS 13.4, *)
        var toSystem : UIAxis {
            var axis = UIAxis()
            
            if self.contains(.horizontal) {
                axis.formUnion(.horizontal)
            }
            
            if self.contains(.vertical) {
                axis.formUnion(.vertical)
            }
            
            return axis
        }
    }
}


fileprivate extension PointerInteraction {
    
    private final class View : UIView, UIPointerInteractionDelegate {
        
        var model : PointerInteraction
        
        init(frame : CGRect, model : PointerInteraction) {
            self.model = model
            
            super.init(frame: frame)
            
            if #available(iOS 13.4, *) {
                self.addInteraction(UIPointerInteraction(delegate: self))
            }
        }
        
        @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
        
        // MARK: UIPointerInteractionDelegate
        
        private var keyModifiers : UIKeyModifierFlags = []
        
        @available(iOS 13.4, *)
        func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
            
            self.keyModifiers = request.modifiers
            
            return defaultRegion
        }

        @available(iOS 13.4, *)
        func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
            
            guard let view = interaction.view else {
                return nil
            }
            
            return self.model.style(self.keyModifiers).toSystem(with: view)
        }
    }
}
