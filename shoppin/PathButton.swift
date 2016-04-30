//
//  PathButton.swift
//  shoppin
//
//  Created by ischuetz on 25/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

// A path button that can be in 2 possible states "on" or "off"
@IBDesignable
class PathButton: UIButton {
    
    var on: Bool = false {
        didSet {
            setPathsForState(on)
        }
    }
    
    private var onPaths: [CGPath]?
    private var offPaths: [CGPath]?

    @IBInspectable
    var strokeColor: UIColor? {
        didSet {
            if let strokeColor = strokeColor, sublayers = layer.sublayers  {
                for l in sublayers {
                    if let shapeLayer = l as? CAShapeLayer {
                        shapeLayer.strokeColor = strokeColor.CGColor
                    }
                }
            } else {
                print("Warn: PathButton.strokeColor: strokeColor: \(strokeColor) or sublayers: \(layer.sublayers) are nil")
            }
        }
    }
    
    func setup(offPaths offPaths: [CGPath], onPaths: [CGPath]) {
        guard offPaths.count == onPaths.count else {print("Error: PathButton.setup: Paths must have same count. offPaths: \(offPaths.count), onPaths: \(onPaths.count). Not setting anything."); return}

        self.offPaths = offPaths
        self.onPaths = onPaths
    
        // Add one sublayer for each path
        for _ in offPaths {
            let sublayer = CAShapeLayer()
            sublayer.fillColor     = UIColor.clearColor().CGColor
            sublayer.anchorPoint   = CGPointMake(0, 0)
            sublayer.lineJoin      = kCALineJoinRound
            sublayer.lineCap       = kCALineCapRound
            sublayer.contentsScale = layer.contentsScale
            sublayer.lineWidth     = 2.5
            layer.addSublayer(sublayer)
        }
        
        setPathsForState(on)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("onTapHandler:"))
        addGestureRecognizer(tapRecognizer)
    }
    
    // src: https://github.com/yannickl/DynamicButton/blob/master/DynamicButton/DynamicButton.swift
    private func animationWithKeyPath(keyPath: String, damping: CGFloat = 10, initialVelocity: CGFloat = 0, stiffness: CGFloat = 100) -> CABasicAnimation {
        guard #available(iOS 9, *) else {
            let basic = CABasicAnimation(keyPath: keyPath)
            basic.duration = 0.3
            basic.fillMode = kCAFillModeForwards
            basic.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
            return basic
        }
        
        let spring = CASpringAnimation(keyPath: keyPath)
        spring.duration = spring.settlingDuration
        spring.damping = damping
        spring.initialVelocity = initialVelocity
        spring.stiffness = stiffness
        spring.fillMode = kCAFillModeForwards
        spring.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        
        return spring
    }
    
    func onTapHandler(sender: UIButton) {
        onTap(on)
    }
    
    func onTap(on: Bool) {
        fatalError("Override")
    }
    
    func setPathsForState(on: Bool) {
        guard let onPaths = onPaths, offPaths = offPaths else {print("Warn: PathButton.onTap: no paths, doing nothing"); return}

        let fromPaths = on ? offPaths : onPaths
        let toPaths = on ? onPaths : offPaths
        
        for (index, path) in toPaths.enumerate() {
            let anim = animationWithKeyPath("path", damping: 10)
            anim.fromValue = fromPaths[index]
            anim.toValue = path
            // TODO cleaner implementation, this index based access and casting is super unsafe
            (layer.sublayers![index] as! CAShapeLayer).addAnimation(anim, forKey: "path")
            (layer.sublayers![index] as! CAShapeLayer).path = path
        }
    }
}
