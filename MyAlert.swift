//
//  MyAlert.swift
//  shoppin
//
//  Created by ischuetz on 02/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

// Inspired by https://github.com/chrene/swipe-to-dismiss
class MyAlert: UIView, UIGestureRecognizerDelegate {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var background: UIView!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    private var panRecognizer: UIPanGestureRecognizer!
    
    
    
    var text: String = "" {
        didSet {
            if let label = label {
                label.text = text
                updateContainerSize()
            } else {
                QL3("Outlets not initialised, can't show text")
            }
        }
    }
    
    var onDismiss: VoidFunction?
    
    init() {
        super.init(frame: CGRectZero)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        panRecognizer = UIPanGestureRecognizer(target: self, action: "onPan:")
        panRecognizer.delegate = self
        addGestureRecognizer(panRecognizer)
    }
    
    func setVisible(visible: Bool, startPoint: CGPoint) {
        hidden = !visible
    }

    private func updateContainerSize() {
        label.sizeToFit()
        
        let labelSize = label.bounds.size
        
        let padding: CGFloat = 20
        let containerWidth: CGFloat = labelSize.width + padding * 2
        let containerHeight: CGFloat = labelSize.height + padding * 2
       
        let paddingMaxSize: CGFloat = 30
        
        let minWidth: CGFloat = 200
        let minHeight: CGFloat = 150
        
        let maxWidth: CGFloat = frame.width - (paddingMaxSize * 2)
        let maxHeight: CGFloat = frame.height - (paddingMaxSize * 2)
        
        widthConstraint.constant = min(max(minWidth, containerWidth), maxWidth)
        heightConstraint.constant = min(max(minHeight, containerHeight), maxHeight)
    }
    
    func resetPopupViewAndHide() {
        UIView.animateWithDuration(0.3, animations: {[weak self] in
            self?.background.alpha = 0
        }, completion: {[weak self] finished in
            self?.onDismiss?()
            self?.removeFromSuperview()
        })
    }
    
    // down 0 up 1
    private func pointsToMove(view: UIView, direction: Int, angle: CGFloat) -> CGFloat {
        let center = view.center
        let halfHeight = CGRectGetHeight(frame) / 2
        let newY = direction > 0 ? halfHeight + frame.maxY : -halfHeight
        return center.y - newY * (1 + abs(angle))
    }
    
    func onPan(recognizer: UIPanGestureRecognizer) {
        
        switch recognizer.state {

        case .Changed:
            let translation = recognizer.translationInView(self)
            container.center = CGPointMake(container.center.x, container.center.y + (translation.y / 10))
            
        case .Failed:
            fallthrough
        case .Cancelled:
            fallthrough
        case .Ended:

            let kTranslationThreshold: CGFloat = 100
            let kVelocityThreshold: CGFloat = 500
            let offset = self.center.y - container.center.y
            
            let vel = recognizer.velocityInView(self).y
            if (abs(offset) > kTranslationThreshold || abs(vel) > kVelocityThreshold) {
                var center = container.center;
                let halfPopupHeight = CGRectGetHeight(container.frame) / 2;
                let newY = vel > 0 ? halfPopupHeight + CGRectGetMaxY(self.frame) : -halfPopupHeight;
                let pointsToMove = self.pointsToMove(container, direction: (vel > 0 ? 0 : 1), angle: 0)
                let duration: NSTimeInterval = NSTimeInterval(pointsToMove / vel)
                
                center.y = newY
            
                UIView.animateWithDuration(min(0.3, duration), animations: {
                    self.container.center = center
                }, completion: {finished in
                    self.resetPopupViewAndHide()
                })
            } else {
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 2, options: [], animations: {
                    self.container.center = self.center
                }, completion: nil)
            }

        default:
            QL3("Not handled: \(recognizer.state)")
        }
    }
}
