//
//  TutorialMask.swift
//  groma
//
//  Created by Ivan Schuetz on 08.08.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class TutorialView: UIView, UIGestureRecognizerDelegate {

    fileprivate var hole: CGRect?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func addTo(view: UIView) {
        frame = view.frame
        isUserInteractionEnabled = false

        alpha = 0
        view.addSubview(self)
        UIView.animate(withDuration: 0.2, delay: 0.3, options: [], animations: {
            self.alpha = 1
        }, completion: nil)
    }

    func remove() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }

    func hole(frame: CGRect) {
        self.hole = frame

        // Path with "small hole" (animation start)
        let originalPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height), cornerRadius: 0)
        let originalCirclePath = UIBezierPath(roundedRect: frame.insetBy(dx: 50, dy: 20, dw: 50, dh: 20), byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: 10, height: 10))
        originalPath.append(originalCirclePath)
        originalPath.usesEvenOddFillRule = true

        // Target path (animation end)
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height), cornerRadius: 0)
        let circlePath = UIBezierPath(roundedRect: frame, byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: 20, height: 20))
        path.append(circlePath)
        path.usesEvenOddFillRule = true

        let fillLayer = CAShapeLayer()
        fillLayer.path = originalPath.cgPath
        fillLayer.fillRule = kCAFillRuleEvenOdd
        fillLayer.fillColor = UIColor.black.cgColor
        fillLayer.opacity = 0.6
        layer.addSublayer(fillLayer)
        fillLayer.path = path.cgPath

        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = originalPath.cgPath
        animation.toValue = path.cgPath
        animation.duration = 0.2
        animation.beginTime = CACurrentMediaTime() + 0.3
        fillLayer.add(animation, forKey: "pathAnimation")

        // Add label with explanation - for now here since we use tutorial only for this
        let label = UILabel()
        label.text = trans("tutorial_tap_to_go_back")
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.sizeToFit()
        label.center = CGPoint(x: center.x, y: DimensionsManager.tapToGoBackLabelY)
        addSubview(label)
    }
}
