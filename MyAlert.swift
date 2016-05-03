//
//  MyAlert.swift
//  shoppin
//
//  Created by ischuetz on 02/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

enum MyAlertDismissAnimation {
    case Fade, None
}

// Inspired by https://github.com/chrene/swipe-to-dismiss
class MyAlert: UIView, UIGestureRecognizerDelegate {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var background: UIView!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var labelCenterConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var okButton: UIButton!
    
    var dismissWithSwipe = false
    var dismissAnimation: MyAlertDismissAnimation = .Fade

    var minWidth: CGFloat = 250
    var minHeight: CGFloat = 160
    
    var text: String = "" {
        didSet {
            if let label = label {
                label.text = text
                updateContainerSize()
            } else {
                QL3("Outlets not initialised, can't set text")
            }
        }
    }
    
    var buttonText: String = "" {
        didSet {
            if let okButton = okButton {
                okButton.setTitle(buttonText, forState: .Normal)
            } else {
                QL3("Outlets not initialised, can't set text")
            }
        }
    }
    
    var onDismiss: VoidFunction?
    var onTapAnywhere: VoidFunction?

    var hasOkButton: Bool = true {
        didSet {
            if let okButton = okButton {
                okButton.hidden = !hasOkButton
                labelCenterConstraint.constant = hasOkButton ? -25 : 0
            } else {
                QL3("No button")
            }
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        onTapAnywhere?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if dismissWithSwipe {
            let panRecognizer = UIPanGestureRecognizer(target: self, action: "onPan:")
            panRecognizer.delegate = self
            panRecognizer.cancelsTouchesInView = false
            addGestureRecognizer(panRecognizer)
        }
    }

    func animateScale(open: Bool, anchorPoint: CGPoint, parentView: UIView, onFinish: VoidFunction? = nil) {

        if open {
            let fractionX = anchorPoint.x / parentView.frame.width
            let fractionY = anchorPoint.y / parentView.frame.height
            
            layer.anchorPoint = CGPointMake(fractionX, fractionY)
            
            frame = CGRectMake(0, 0, parentView.frame.width, parentView.frame.height)
        }
        
        transform = open ? CGAffineTransformMakeScale(0.001, 0.001) : CGAffineTransformMakeScale(1, 1)

        UIView.animateWithDuration(0.3, animations: {[weak self] in
            self?.transform = open ? CGAffineTransformMakeScale(1, 1) : CGAffineTransformMakeScale(0.001, 0.001)
        }, completion: {finished in
            onFinish?()
        })
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        onTapAnywhere?()
    }

    private func updateContainerSize() {
        label.sizeToFit()
        
        let labelSize = label.bounds.size
        
        let padding: CGFloat = 20
        let containerWidth: CGFloat = labelSize.width + padding * 2
        let containerHeight: CGFloat = labelSize.height + padding * 2
       
        let paddingMaxSize: CGFloat = 30
        
        let maxWidth: CGFloat = frame.width - (paddingMaxSize * 2)
        let maxHeight: CGFloat = frame.height - (paddingMaxSize * 2)
        
        widthConstraint.constant = min(max(minWidth, containerWidth), maxWidth)
        heightConstraint.constant = min(max(minHeight, containerHeight), maxHeight)
    }
    
    func dismiss() {
        
        func dismiss() {
            onDismiss?()
            removeFromSuperview()
        }
        
        switch dismissAnimation {
        case .Fade:
            UIView.animateWithDuration(0.3, animations: {[weak self] in
                self?.background.alpha = 0
                }, completion: {finished in
                    dismiss()
            })
        case .None:
            dismiss()
        }
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
                    self.dismiss()
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
    
    @IBAction func onOkTap() {
        dismiss()
    }
}
