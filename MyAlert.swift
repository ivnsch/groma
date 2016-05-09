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

// TODO better structure, alert and confirm should be 2 different classes, which share part of the view and code. Frame/constraints calculations are also messy.
// swipe to dismiss part inspired by https://github.com/chrene/swipe-to-dismiss
class MyAlert: UIView, UIGestureRecognizerDelegate {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var background: UIView!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var labelCenterConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var okButton: UIButton!
    
    
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    
    var dismissWithSwipe = false
    var dismissAnimation: MyAlertDismissAnimation = .Fade

    var minWidth: CGFloat = 250
    var minHeight: CGFloat = 160

    
    var title: String? {
        didSet {
            if let titleLabel = titleLabel {
                titleLabel.text = title
                updateContainerSize()
            } else {
                QL3("Outlets not initialised, can't set text")
            }
        }
    }
    
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
   
    var onOk: VoidFunction?
    var onDismiss: VoidFunction?
    var onTapAnywhere: VoidFunction?
    
    var confirmText: String = "Confirm" {
        didSet {
            if let confirmButton = confirmButton {
                confirmButton.setTitle(confirmText, forState: .Normal)
            } else {
                QL3("Outlets not initialised")
            }
        }
    }

    var cancelText: String = "Cancel" {
        didSet {
            if let cancelButton = cancelButton {
                cancelButton.setTitle(cancelText, forState: .Normal)
            } else {
                QL3("Outlets not initialised")
            }
        }
    }

    var isConfirm: Bool = true {
        didSet {
            if let confirmButton = confirmButton {
                confirmButton.hidden = !isConfirm
                cancelButton.hidden = !isConfirm
                okButton.hidden = isConfirm
            } else {
                QL3("Outlets not initialised")
            }
        }
    }
    
    var hasOkButton: Bool = true {
        didSet {
            if let okButton = okButton {
                okButton.hidden = !hasOkButton
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
        
        okButton.setTitle(buttonText, forState: .Normal)
        confirmButton.setTitle(confirmText, forState: .Normal)
        cancelButton.setTitle(cancelText, forState: .Normal)
        
        animateFade(true)
    }
    
    private func animateFade(opening: Bool) {
        alpha = opening ? 0 : 1
        UIView.animateWithDuration(0.3) {[weak self] in
            self?.alpha = opening ? 1 : 0
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        onTapAnywhere?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if dismissWithSwipe {
            let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(MyAlert.onPan(_:)))
            panRecognizer.delegate = self
            panRecognizer.cancelsTouchesInView = false
            addGestureRecognizer(panRecognizer)
        }
    }

    func animateScale(open: Bool, anchorPoint: CGPoint, parentView: UIView, frame: CGRect? = nil, onFinish: VoidFunction? = nil) {

        let frame = frame ?? parentView.frame
        
        if open {
            let fractionX = anchorPoint.x / frame.width
            let fractionY = anchorPoint.y / frame.height
            
            layer.anchorPoint = CGPointMake(fractionX, fractionY)
            
            self.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.width, frame.height)
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

        let paddingMaxSize: CGFloat = 40
        let labelPadding: CGFloat = 20
        let maxWidth: CGFloat = frame.width - (paddingMaxSize * 2)
        
        print("alert frame: \(frame)")
        
//        let maxWidth: CGFloat = 200
        let maxHeight: CGFloat = frame.height - (paddingMaxSize * 2)
        
//        let labelSize = label.bounds.size
        let labelSize = CGSizeMake(maxWidth - (labelPadding * 2), text.heightWithConstrainedWidth(maxWidth, font: label.font))
        
        let titleWithTopAndBottomSpaceHeight: CGFloat = title != nil ? 62 : 0
        let bottomButtonsWithTopAndButtonSpaceHeight: CGFloat = 62
        

        let containerWidth: CGFloat = labelSize.width + (labelPadding * 2)
        let containerHeight: CGFloat = (labelSize.height + (labelPadding * 2)) + titleWithTopAndBottomSpaceHeight + bottomButtonsWithTopAndButtonSpaceHeight
        
        widthConstraint.constant = min(max(minWidth, containerWidth), maxWidth)
        heightConstraint.constant = min(max(minHeight, containerHeight), maxHeight)
        
        labelCenterConstraint.constant = (title == nil && (hasOkButton || isConfirm)) ? -25 : 0
    }
    
    func dismiss() {
        
        func dismiss() {
            onDismiss?()
            removeFromSuperview()
        }
        
        switch dismissAnimation {
        case .Fade:
            UIView.animateWithDuration(0.2, animations: {[weak self] in
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
    
    @IBAction func onConfirmTap() {
        onOk?()
        dismiss()
    }
    
    @IBAction func onCancelTap() {
        dismiss()
    }
}
