//
//  MyAlert.swift
//  shoppin
//
//  Created by ischuetz on 02/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers

enum MyAlertDismissAnimation {
    case fade, none
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
    var dismissAnimation: MyAlertDismissAnimation = .fade

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
                okButton.setTitle(buttonText, for: UIControlState())
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
                confirmButton.setTitle(confirmText, for: UIControlState())
            } else {
                QL3("Outlets not initialised")
            }
        }
    }

    var cancelText: String = "Cancel" {
        didSet {
            if let cancelButton = cancelButton {
                cancelButton.setTitle(cancelText, for: UIControlState())
            } else {
                QL3("Outlets not initialised")
            }
        }
    }

    var isConfirm: Bool = true {
        didSet {
            if let confirmButton = confirmButton {
                confirmButton.isHidden = !isConfirm
                cancelButton.isHidden = !isConfirm
                okButton.isHidden = isConfirm
            } else {
                QL3("Outlets not initialised")
            }
        }
    }
    
    var hasOkButton: Bool = true {
        didSet {
            if let okButton = okButton {
                okButton.isHidden = !hasOkButton
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
        
        okButton.setTitle(buttonText, for: UIControlState())
        confirmButton.setTitle(confirmText, for: UIControlState())
        cancelButton.setTitle(cancelText, for: UIControlState())
        
        animateFade(true)
    }
    
    fileprivate func animateFade(_ opening: Bool) {
        alpha = opening ? 0 : 1
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.alpha = opening ? 1 : 0
        }) 
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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

    func animateScale(_ open: Bool, anchorPoint: CGPoint, parentView: UIView, frame: CGRect? = nil, onFinish: VoidFunction? = nil) {

        let frame = frame ?? parentView.frame
        
        if open {
            let fractionX = anchorPoint.x / frame.width
            let fractionY = anchorPoint.y / frame.height
            
            layer.anchorPoint = CGPoint(x: fractionX, y: fractionY)
            
            self.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height)
        }
        
        transform = open ? CGAffineTransform(scaleX: 0.001, y: 0.001) : CGAffineTransform(scaleX: 1, y: 1)

        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.transform = open ? CGAffineTransform(scaleX: 1, y: 1) : CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: {finished in
            onFinish?()
        })
    }
    
    func handleTap(_ recognizer: UITapGestureRecognizer) {
        onTapAnywhere?()
    }

    fileprivate func updateContainerSize() {
        label.sizeToFit()

        let paddingMaxSize: CGFloat = 40
        let labelPadding: CGFloat = 20
        let maxWidth: CGFloat = frame.width - (paddingMaxSize * 2)
        
        print("alert frame: \(frame)")
        
//        let maxWidth: CGFloat = 200
        let maxHeight: CGFloat = frame.height - (paddingMaxSize * 2)
        
//        let labelSize = label.bounds.size
        let labelSize = CGSize(width: maxWidth - (labelPadding * 2), height: text.heightWithConstrainedWidth(maxWidth, font: label.font))
        
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
        case .fade:
            UIView.animate(withDuration: 0.2, animations: {[weak self] in
                self?.background.alpha = 0
                }, completion: {finished in
                    dismiss()
            })
        case .none:
            dismiss()
        }
    }
    
    // down 0 up 1
    fileprivate func pointsToMove(_ view: UIView, direction: Int, angle: CGFloat) -> CGFloat {
        let center = view.center
        let halfHeight = frame.height / 2
        let newY = direction > 0 ? halfHeight + frame.maxY : -halfHeight
        return center.y - newY * (1 + abs(angle))
    }
    
    func onPan(_ recognizer: UIPanGestureRecognizer) {
        
        switch recognizer.state {

        case .changed:
            let translation = recognizer.translation(in: self)
            container.center = CGPoint(x: container.center.x, y: container.center.y + (translation.y / 10))
            
        case .failed:
            fallthrough
        case .cancelled:
            fallthrough
        case .ended:

            let kTranslationThreshold: CGFloat = 100
            let kVelocityThreshold: CGFloat = 500
            let offset = self.center.y - container.center.y
            
            let vel = recognizer.velocity(in: self).y
            if (abs(offset) > kTranslationThreshold || abs(vel) > kVelocityThreshold) {
                var center = container.center;
                let halfPopupHeight = container.frame.height / 2;
                let newY = vel > 0 ? halfPopupHeight + self.frame.maxY : -halfPopupHeight;
                let pointsToMove = self.pointsToMove(container, direction: (vel > 0 ? 0 : 1), angle: 0)
                let duration: TimeInterval = TimeInterval(pointsToMove / vel)
                
                center.y = newY
            
                UIView.animate(withDuration: min(0.3, duration), animations: {
                    self.container.center = center
                }, completion: {finished in
                    self.dismiss()
                })
            } else {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 2, options: [], animations: {
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
