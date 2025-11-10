//
//  POPCompatibility.swift
//  NFwordsDemo
//
//  POP 动画库的 UIKit 兼容层
//  将所有 POP 动画调用转换为 UIKit 动画
//

import UIKit

// MARK: - POP 动画类型兼容

public typealias POPBasicAnimation = UIKitBasicAnimation
public typealias POPSpringAnimation = UIKitSpringAnimation
public typealias POPAnimation = UIKitBasicAnimation  // 通用动画类型

// MARK: - POP 属性键兼容

public let kPOPLayerScaleXY = "scaleXY"
public let kPOPLayerTranslationXY = "translationXY"
public let kPOPLayerRotation = "rotation"
public let kPOPViewAlpha = "alpha"
public let kPOPViewFrame = "frame"

// MARK: - POP 动画基类

public class UIKitBasicAnimation {
    public var duration: TimeInterval = 0.3
    public var fromValue: Any?
    public var toValue: Any?
    public var beginTime: CFTimeInterval = 0
    public var completionBlock: ((UIKitBasicAnimation?, Bool) -> Void)?
    public var propertyName: String = ""
    
    public init?(propertyNamed propertyName: String) {
        self.propertyName = propertyName
    }
}

public class UIKitSpringAnimation: UIKitBasicAnimation {
    public var springBounciness: CGFloat = 10.0
    public var springSpeed: CGFloat = 20.0
}

// MARK: - UIView POP 扩展

public extension UIView {
    func pop_add(_ animation: UIKitBasicAnimation?, forKey key: String?) {
        guard let animation = animation else { return }
        
        let delay = max(0, animation.beginTime - CACurrentMediaTime())
        
        if let springAnimation = animation as? UIKitSpringAnimation {
            // Spring 动画
            UIView.animate(
                withDuration: animation.duration,
                delay: delay,
                usingSpringWithDamping: 1.0 - (springAnimation.springBounciness / 20.0),
                initialSpringVelocity: springAnimation.springSpeed / 20.0,
                options: [],
                animations: {
                    self.applyAnimation(animation)
                },
                completion: { finished in
                    animation.completionBlock?(nil, finished)
                }
            )
        } else {
            // 基本动画
            UIView.animate(
                withDuration: animation.duration,
                delay: delay,
                options: [.curveEaseInOut],
                animations: {
                    self.applyAnimation(animation)
                },
                completion: { finished in
                    animation.completionBlock?(nil, finished)
                }
            )
        }
    }
    
    func pop_removeAllAnimations() {
        layer.removeAllAnimations()
    }
    
    private func applyAnimation(_ animation: UIKitBasicAnimation) {
        guard let toValue = animation.toValue else { return }
        
        switch animation.propertyName {
        case kPOPViewAlpha:
            if let value = toValue as? NSNumber {
                self.alpha = CGFloat(value.doubleValue)
            }
        case kPOPViewFrame:
            if let value = toValue as? NSValue {
                self.frame = value.cgRectValue
            }
        default:
            break
        }
    }
}

// MARK: - CALayer POP 扩展

public extension CALayer {
    func pop_add(_ animation: UIKitBasicAnimation?, forKey key: String?) {
        guard let animation = animation else { return }
        
        let delay = max(0, animation.beginTime - CACurrentMediaTime())
        
        // 转换属性名和值类型
        // ⭐ 修复：使用 var 而不是 let，以便可以重新赋值
        var keyPath: String
        var convertedFromValue: Any?
        var convertedToValue: Any?
        
        switch animation.propertyName {
        case kPOPLayerScaleXY:
            // ⭐ 修复：对于 scale，确保转换为 NSNumber，因为 Core Animation 的 transform.scale 需要 NSNumber
            keyPath = "transform.scale"
            
            // 处理 fromValue 和 toValue
            convertedFromValue = convertValueForAnimation(animation.fromValue, keyPath: "transform.scale")
            convertedToValue = convertValueForAnimation(animation.toValue, keyPath: "transform.scale")
            
            // ⭐ 修复：确保最终值是 NSNumber，如果不是则使用默认值
            if convertedFromValue != nil && !(convertedFromValue is NSNumber) {
                // 如果转换失败，使用默认值 1.0
                convertedFromValue = NSNumber(value: 1.0)
            }
            if convertedToValue != nil && !(convertedToValue is NSNumber) {
                // 如果转换失败，使用默认值 1.0
                convertedToValue = NSNumber(value: 1.0)
            }
        case kPOPLayerTranslationXY:
            keyPath = "transform.translation"
            convertedFromValue = convertValueForAnimation(animation.fromValue, keyPath: keyPath)
            convertedToValue = convertValueForAnimation(animation.toValue, keyPath: keyPath)
        case kPOPLayerRotation:
            keyPath = "transform.rotation.z"
            convertedFromValue = convertValueForAnimation(animation.fromValue, keyPath: keyPath)
            convertedToValue = convertValueForAnimation(animation.toValue, keyPath: keyPath)
        default:
            keyPath = animation.propertyName
            convertedFromValue = animation.fromValue
            convertedToValue = animation.toValue
        }
        
        if let springAnimation = animation as? UIKitSpringAnimation {
            // Spring 动画
            let anim = CASpringAnimation(keyPath: keyPath)
            anim.duration = animation.duration
            anim.beginTime = CACurrentMediaTime() + delay
            anim.damping = max(0.1, 1.0 - (springAnimation.springBounciness / 20.0) * 10)
            anim.initialVelocity = springAnimation.springSpeed / 20.0
            anim.mass = 1.0
            anim.stiffness = 100.0
            
            if let fromValue = convertedFromValue {
                anim.fromValue = fromValue
            }
            if let toValue = convertedToValue {
                anim.toValue = toValue
            }
            
            anim.fillMode = .forwards
            anim.isRemovedOnCompletion = false
            
            // 使用 CATransaction 处理完成回调
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                animation.completionBlock?(nil, true)
                // 应用最终值
                if let toValue = animation.toValue {
                    self.applyLayerAnimationValue(toValue, forKeyPath: keyPath)
                }
            }
            self.add(anim, forKey: key)
            CATransaction.commit()
        } else {
            // 基本动画
            let anim = CABasicAnimation(keyPath: keyPath)
            anim.duration = animation.duration
            anim.beginTime = CACurrentMediaTime() + delay
            anim.fillMode = .forwards
            anim.isRemovedOnCompletion = false
            
            if let fromValue = convertedFromValue {
                anim.fromValue = fromValue
            }
            if let toValue = convertedToValue {
                anim.toValue = toValue
            }
            
            // 使用 CATransaction 处理完成回调
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                animation.completionBlock?(nil, true)
                // 应用最终值
                if let toValue = animation.toValue {
                    self.applyLayerAnimationValue(toValue, forKeyPath: keyPath)
                }
            }
            self.add(anim, forKey: key)
            CATransaction.commit()
        }
    }
    
    func pop_removeAllAnimations() {
        removeAllAnimations()
    }
    
    /// 转换值类型以匹配 Core Animation 的要求
    private func convertValueForAnimation(_ value: Any?, keyPath: String) -> Any? {
        guard let value = value else { return nil }
        
        switch keyPath {
        case "transform.scale":
            // ⭐ 修复：Core Animation 的 transform.scale 必须使用 NSNumber
            // 处理 NSNumber（最优先）
            if let number = value as? NSNumber {
                return number
            }
            
            // 处理 NSValue
            if let nsValue = value as? NSValue {
                // ⭐ 修复：通过检查 objCType 来判断 NSValue 的类型
                let objCType = String(cString: nsValue.objCType)
                
                // 尝试获取 cgPointValue（kPOPLayerScaleXY 的标准格式）
                if objCType.contains("CGPoint") {
                    let point = nsValue.cgPointValue
                    return NSNumber(value: Double(point.x))  // 使用 x 值作为统一缩放
                }
                
                // 尝试获取 cgSizeValue（KolodaViewAnimatior 的错误格式）
                if objCType.contains("CGSize") {
                    let size = nsValue.cgSizeValue
                    return NSNumber(value: Double(size.width))  // 使用 width 作为统一缩放
                }
                
                // 如果类型不匹配，返回默认值以避免崩溃
                #if DEBUG
                print("[POPCompatibility] ⚠️ 警告：无法识别的 NSValue 类型: \(objCType)，使用默认值 1.0")
                #endif
                return NSNumber(value: 1.0)
            }
        case "transform.translation":
            // 保持 NSValue(cgPoint:) 格式
            if let pointValue = value as? NSValue {
                return pointValue
            }
        case "transform.rotation.z":
            // 保持 NSNumber 格式
            if let number = value as? NSNumber {
                return number
            } else if let angle = value as? CGFloat {
                return NSNumber(value: Double(angle))
            }
        default:
            return value
        }
        
        return value
    }
    
    private func applyLayerAnimationValue(_ value: Any, forKeyPath keyPath: String) {
        switch keyPath {
        case "transform.scale":
            // ⭐ 修复：处理 scale，支持 NSValue(cgPoint:)、NSValue(cgSize:) 和 NSNumber
            var scaleValue: CGFloat = 1.0
            
            if let number = value as? NSNumber {
                scaleValue = CGFloat(number.doubleValue)
            } else if let nsValue = value as? NSValue {
                let objCType = String(cString: nsValue.objCType)
                if objCType.contains("CGPoint") {
                    let point = nsValue.cgPointValue
                    scaleValue = point.x  // 使用 x 值作为统一缩放
                } else if objCType.contains("CGSize") {
                    let size = nsValue.cgSizeValue
                    scaleValue = size.width  // 使用 width 作为统一缩放
                } else {
                    #if DEBUG
                    print("[POPCompatibility] ⚠️ 警告：无法识别的 NSValue 类型: \(objCType)，使用默认值 1.0")
                    #endif
                    scaleValue = 1.0
                }
            }
            
            // 应用 scale transform
            let currentTransform = self.transform
            // 保留 translation 和 rotation
            let translationX = currentTransform.m41
            let translationY = currentTransform.m42
            let rotationZ = atan2(currentTransform.m12, currentTransform.m11)
            
            // 创建新的 transform
            var newTransform = CATransform3DIdentity
            newTransform = CATransform3DScale(newTransform, scaleValue, scaleValue, 1.0)
            newTransform = CATransform3DTranslate(newTransform, translationX, translationY, 0)
            newTransform = CATransform3DRotate(newTransform, rotationZ, 0, 0, 1)
            self.transform = newTransform
        case "transform.translation":
            if let pointValue = value as? NSValue {
                let translation = pointValue.cgPointValue
                self.transform = CATransform3DTranslate(self.transform, translation.x, translation.y, 0)
            }
        case "transform.rotation.z":
            if let angle = value as? CGFloat {
                self.transform = CATransform3DRotate(self.transform, angle, 0, 0, 1)
            } else if let number = value as? NSNumber {
                let angle = CGFloat(number.doubleValue)
                self.transform = CATransform3DRotate(self.transform, angle, 0, 0, 1)
            }
        default:
            break
        }
    }
}


// MARK: - POP 辅助函数

public func POPLayerGetTranslationXY(_ layer: CALayer) -> CGPoint {
    if let presentation = layer.presentation() {
        return CGPoint(
            x: presentation.transform.m41,
            y: presentation.transform.m42
        )
    }
    return CGPoint.zero
}

public func POPLayerGetRotationZ(_ layer: CALayer) -> CGFloat {
    if let presentation = layer.presentation() {
        let transform = presentation.transform
        return atan2(transform.m12, transform.m11)
    }
    return 0
}

// MARK: - CASpringAnimation 扩展（iOS 9+）

extension CASpringAnimation {
    var completionBlock: ((Bool) -> Void)? {
        get { return nil }
        set {
            // 使用 CATransaction 处理
            if let block = newValue {
                CATransaction.setCompletionBlock {
                    block(true)
                }
            }
        }
    }
}

