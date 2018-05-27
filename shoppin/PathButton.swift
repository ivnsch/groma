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
            if oldValue != on {
                setPathsForState(on)
            }
        }
    }
    
    fileprivate var onPaths: [CGPath]?
    fileprivate var offPaths: [CGPath]?

    @IBInspectable
    var strokeColor: UIColor? {
        didSet {
            if let strokeColor = strokeColor, let sublayers = layer.sublayers  {
                for l in sublayers {
                    if let shapeLayer = l as? CAShapeLayer {
                        shapeLayer.strokeColor = strokeColor.cgColor
                    }
                }
            } else {
                print("Warn: PathButton.strokeColor: strokeColor: \(String(describing: strokeColor)) or sublayers: \(String(describing: layer.sublayers)) are nil")
            }
        }
    }
    
    func setup(offPaths: [CGPath], onPaths: [CGPath], lineWidth: CGFloat = 2.5) {
        guard offPaths.count == onPaths.count else {print("Error: PathButton.setup: Paths must have same count. offPaths: \(offPaths.count), onPaths: \(onPaths.count). Not setting anything."); return}

        self.offPaths = offPaths
        self.onPaths = onPaths
    
        // Add one sublayer for each path
        for _ in offPaths {
            let sublayer = CAShapeLayer()
            sublayer.fillColor     = UIColor.clear.cgColor
            sublayer.anchorPoint   = CGPoint(x: 0, y: 0)
            sublayer.lineJoin      = kCALineJoinRound
            sublayer.lineCap       = kCALineCapRound
            sublayer.contentsScale = layer.contentsScale
            sublayer.lineWidth     = lineWidth
            layer.addSublayer(sublayer)
        }
        
        setPathsForState(on)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(PathButton.onTapHandler(_:)))
        addGestureRecognizer(tapRecognizer)
    }
    
    // src: https://github.com/yannickl/DynamicButton/blob/master/DynamicButton/DynamicButton.swift
    fileprivate func animationWithKeyPath(_ keyPath: String, damping: CGFloat = 10, initialVelocity: CGFloat = 0, stiffness: CGFloat = 100) -> CABasicAnimation {
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
    
    @objc func onTapHandler(_ sender: UIButton) {
        onTap(on)
    }
    
    func onTap(_ on: Bool) {
        fatalError("Override")
    }
    
    func setPathsForState(_ on: Bool) {
        guard let onPaths = onPaths, let offPaths = offPaths else {print("Warn: PathButton.onTap: no paths, doing nothing"); return}

        let fromPaths = on ? offPaths : onPaths
        let toPaths = on ? onPaths : offPaths
        
        for (index, path) in toPaths.enumerated() {
            let anim = animationWithKeyPath("path", damping: 10)
            anim.fromValue = fromPaths[index]
            anim.toValue = path
            // TODO cleaner implementation, this index based access and casting is super unsafe
            (layer.sublayers![index] as! CAShapeLayer).add(anim, forKey: "path")
            (layer.sublayers![index] as! CAShapeLayer).path = path
        }
    }
}
