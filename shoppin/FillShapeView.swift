//
//  FillShapeView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 27/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

protocol FillShapeViewDelegate {
    func onFillShapeValueUpdated(fraction: Fraction)
}

class FillShapeView: UIView {
    
    var shapeImage: UIImage = UIImage()
    var maskImage: UIImage = UIImage()
    
    var contentStart: CGFloat?
    var heightStart: CGFloat?
    
    var newcontentLayer: CAShapeLayer = CAShapeLayer()
    var mynewmask: CALayer = CALayer()
    
    var imageView: UIImageView = UIImageView()
    
    let snapInterval: CGFloat = 1 / 4
    let snapInterval2: CGFloat = 1 / 3
    
    let linesPadding: CGFloat = 20
    
    var delegate: FillShapeViewDelegate?
    
    init(frame: CGRect, shapeImageName: String, maskImageName: String) {
        super.init(frame: frame)
        
        config(shapeImageName: shapeImageName, maskImageName: maskImageName)
    }
    
    fileprivate func clear() {
        removeSubviews() // image view and lines
        newcontentLayer.removeFromSuperlayer()
        if let gestureRecognizers = gestureRecognizers {
            for recognizer in gestureRecognizers {
                removeGestureRecognizer(recognizer)
            }
        }
    }
    
    func config(shapeImageName: String, maskImageName: String) {
        guard
            let shapeImage = UIImage(named: shapeImageName),
            let maskImage = UIImage(named: maskImageName) else {return}
        
        clear()
        
        self.shapeImage = shapeImage
        self.maskImage = maskImage
        
        newcontentLayer = CAShapeLayer()
        mynewmask = CALayer()
        
        imageView = UIImageView(image: shapeImage)
        
        // NOTE: y of imageView has to be 0 (center: imageView.height / 2) for the mask to work correctly, don't have time now to check why
        imageView.center = CGPoint(x: frame.width / 2, y: imageView.height / 2)
        
        addSubview(imageView)
        
        mynewmask.contents = maskImage.cgImage
        mynewmask.frame = imageView.frame
        
        let newcontentPath = UIBezierPath(rect: imageView.frame)
        
        newcontentLayer.path = newcontentPath.cgPath
        newcontentLayer.fillColor = UIColor.flatRed.cgColor
        
        layer.addSublayer(newcontentLayer)
        
        newcontentLayer.mask = mynewmask
        
        bringSubview(toFront: imageView)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan(sender:)))
        addGestureRecognizer(panRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(sender:)))
        addGestureRecognizer(tapRecognizer)
        
        showLines()
        
        invalidateIntrinsicContentSize()
    }
    
    func fillTo(pt: CGFloat) {
        let current = imageView.frame.height - newcontentLayer.frame.origin.y // invert y
        let delta = current - pt
        newcontentLayer.frame.origin.y += delta
        mynewmask.frame.origin.y -= delta

    }
    
    func fillTo(percentage: CGFloat) {
        let pt = imageView.frame.height * percentage
        
        fillTo(pt: pt)
    }
    
    fileprivate func showLines() {
        let imageStartY = imageView.frame.origin.y
        
        for i in 1..<Int((1 / snapInterval)) {
            let decimal = imageView.frame.height * (snapInterval * CGFloat(i))
            addLine(y: decimal + imageStartY, color: UIColor.flatBlue.withAlphaComponent(0.2))
        }
        
        
        for i in 1..<Int((1 / snapInterval2)) {
            let decimal = imageView.frame.height * (snapInterval2 * CGFloat(i))
            addLine(y: decimal + imageStartY, color: UIColor.flatBlue.withAlphaComponent(0.2))
        }
    }
    
    fileprivate func addLine(y: CGFloat, color: UIColor) {
        let lineView = UIView(frame: CGRect(x: linesPadding, y: y, width: frame.width - linesPadding * 2, height: 1))
        lineView.backgroundColor = color
        addSubview(lineView)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func onPan(sender: UIPanGestureRecognizer) {
        
        if sender.state == .began {
            contentStart = newcontentLayer.frame.origin.y
            heightStart = mynewmask.frame.origin.y
        }
        
        if sender.state == .changed {
            let delta = sender.translation(in: self).y
            
            let deltaTopLimit = max(-(contentStart ?? 0), delta) // top limit
            let actualDelta = min(frame.height - (contentStart ?? 0), deltaTopLimit) // bottom limit
   
            newcontentLayer.frame.origin.y = (contentStart ?? 0) + actualDelta
            mynewmask.frame.origin.y = (heightStart ?? 0) - actualDelta
         
            let (_, snapPosition) = calculateSnapPosition(currentValue: newcontentLayer.frame.origin.y)
            delegate?.onFillShapeValueUpdated(fraction: toFraction(snapPosition: snapPosition))
        }
        
        if sender.state == .ended {
            snap(currentValue: newcontentLayer.frame.origin.y)
        }
    }
    
    @objc func onTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            
            let tapY = sender.location(in: self).y
            
            // Move to tap position
            let contentLayerDelta = tapY - newcontentLayer.frame.origin.y
            newcontentLayer.frame.origin.y += contentLayerDelta
            mynewmask.frame.origin.y -= contentLayerDelta
            
            print("contentLayerDelta: \(contentLayerDelta), newcontentLayer.frame.origin.y: \(newcontentLayer.frame.origin.y), mynewmask.frame.origin.y: \(mynewmask.frame.origin.y)")
            
            // Snap
            snap(currentValue: newcontentLayer.frame.origin.y, snapToBottom: false)
//            delay(0.3) {
//                self.snap(currentValue: self.newcontentLayer.frame.origin.y)
//            }
        }
    }
    
    func calculateSnapPosition(currentValue: CGFloat, snapToBottom: Bool = true) -> (delta: CGFloat, snapPosition: CGFloat) {
        let interval = imageView.frame.height * snapInterval
        let interval2 = imageView.frame.height * snapInterval2
        let to = snapToBottom ? ceil(currentValue / interval) * interval : floor(currentValue / interval) * interval
        let to2 = snapToBottom ? ceil(currentValue / interval2) * interval2 : floor(currentValue / interval2) * interval2
        
        let delta1 = to - currentValue
        let delta2 = to2 - currentValue
        
        var nearestDelta: CGFloat
        if snapToBottom ? delta1 < delta2 : delta1 > delta2 {
            nearestDelta = delta1
        } else {
            nearestDelta = delta2
        }
        
        return (delta: nearestDelta, snapPosition: newcontentLayer.frame.origin.y + nearestDelta)
    }
    
    func snap(currentValue: CGFloat, snapToBottom: Bool = true) {
        let (delta, snapPosition) = calculateSnapPosition(currentValue: currentValue, snapToBottom: snapToBottom)

        newcontentLayer.frame.origin.y += delta
        mynewmask.frame.origin.y -= delta
        
        delegate?.onFillShapeValueUpdated(fraction: toFraction(snapPosition: snapPosition))
    }
    
    func toFraction(snapPosition: CGFloat) -> Fraction {
        let invertedSnapPosition = imageView.frame.height - snapPosition // invert y
        let decimal = invertedSnapPosition / imageView.frame.height // find % of image height
        return rationalApproximationOf(x0: Double(decimal)) // convert to fraction
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: imageView.width, height: imageView.height)
    }
}

func rationalApproximationOf(x0 : Double, withPrecision eps : Double = 1.0E-1) -> Fraction {
    var x = x0
    var a = floor(x)
    var (h1, k1, h, k) = (1, 0, Int(a), 1)
    
    while x - a > eps * Double(k) * Double(k) {
        x = 1.0/(x - a)
        a = floor(x)
        (h1, k1, h, k) = (h, k, h1 + Int(a) * h, k1 + Int(a) * k)
    }
    
    return Fraction(wholeNumber: 0, numerator: h, denominator: k)
}

