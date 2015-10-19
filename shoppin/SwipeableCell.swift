//
//  SwipeableCell.swift
//  shoppin
//
//  Created by ischuetz on 27.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

//
//  SwipeableCell.swift
//  SwipeableCell
//
//  Created by ischuetz on 27.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit


//protocol SwipeableCellDelegate {
//    func buttonOneActionForItemText()
//    func buttonTwoActionForItemText()
//    func buttonThreeActionForItemText()
//}

class SwipeableCell: UITableViewCell {
    
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    
    @IBOutlet weak var myContentView: UIView!
    
    var panRecognizer:UIPanGestureRecognizer!
    var panStartPoint:CGPoint!
    var startingLeftLayoutConstraint: CGFloat = 0
    
    var startItemSwipe:(()->())?
    var itemSwiped:(()->())?
    var buttonTwoTap:(()->())?
    
    var onNoteTapFunc: VoidFunction?
    
    @IBOutlet weak var contentViewRightConstraint:NSLayoutConstraint!
    @IBOutlet weak var contentViewLeftConstraint:NSLayoutConstraint!
    
//    var delegate:SwipeableCellDelegate!
    @IBOutlet weak var noteButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: "onPanCell:")
        self.panRecognizer.delegate = self
        self.myContentView.addGestureRecognizer(self.panRecognizer)
        
        myContentView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func buttonTotalWidth() -> CGFloat {
        return CGRectGetWidth(self.frame)
        //            - CGRectGetMinX(self.button2.frame)
    }
    
    func setOpen(open: Bool, animated: Bool = false) {
        if open {
            setConstraintsToShowAllButtons(animated, notifyDelegateDidOpen: false)
        } else {
            resetConstraintContstantsToZero(animated, notifyDelegateDidClose: false)
        }
    }
    
    func resetConstraintContstantsToZero(animated:Bool, notifyDelegateDidClose:Bool) {
        if self.startingLeftLayoutConstraint == 0 && self.contentViewLeftConstraint.constant == 0 {
            return
        }
        
        self.updateConstraintsIfNeeded(animated, onCompletion: { (finished) -> Void in
            
            self.contentViewLeftConstraint.constant = 0
            self.contentViewRightConstraint.constant = 0
            
            self.updateConstraintsIfNeeded(animated, alpha: 1, onCompletion: { (finished) -> Void in
                self.startingLeftLayoutConstraint = self.contentViewLeftConstraint.constant
            })
        })
    }
    
    func setConstraintsToShowAllButtons(animated: Bool, notifyDelegateDidOpen: Bool) {
        if self.startingLeftLayoutConstraint == self.buttonTotalWidth() && self.contentViewLeftConstraint.constant == self.buttonTotalWidth() {
            return
        }
        
        self.updateConstraintsIfNeeded(animated, onCompletion: { (finished) -> Void in
            self.contentViewLeftConstraint.constant = self.buttonTotalWidth()
            self.contentViewRightConstraint.constant = -self.buttonTotalWidth()
            
            
            self.updateConstraintsIfNeeded(animated, alpha: 0, onCompletion: { (finished) -> Void in
                self.startingLeftLayoutConstraint = self.contentViewLeftConstraint.constant

                if notifyDelegateDidOpen {
                    self.itemSwiped?()
                }
            })
        })
    }
    
    func updateConstraintsIfNeeded(animated:Bool, alpha: CGFloat? = nil, onCompletion:((Bool)->Void)?) {
        var duration:NSTimeInterval = 0
        if animated {
            duration = 0.2
        }
        let delay:NSTimeInterval = 0
        
        UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseOut, animations: {() -> Void in
            self.layoutIfNeeded()
            if let alpha = alpha {
                self.myContentView.alpha = alpha
            }
            
            }, completion: onCompletion)
    }
    
    func onPanCell(recognizer:UIPanGestureRecognizer) {
        
        var movingHorizontally = false
        if let panStartPoint = self.panStartPoint {
            movingHorizontally = fabsf(Float(panStartPoint.y)) < fabsf(Float(panStartPoint.x))
        }
        
        
        switch recognizer.state {
        case .Began:
            self.panStartPoint = recognizer.translationInView(self.myContentView)
            self.startingLeftLayoutConstraint = self.contentViewLeftConstraint.constant
            
            self.startItemSwipe?()
            
        case .Changed:
            if movingHorizontally {
                let currentPoint = recognizer.translationInView(self.myContentView)
                let deltaX = currentPoint.x - self.panStartPoint.x
                let panningRight = currentPoint.x > self.panStartPoint.x
                
                if self.startingLeftLayoutConstraint == 0 { //closed
                    if !panningRight {
                        let constant = max(-deltaX, 0)
                        if constant == 0 {
                            self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
                        } else {
                            //                        self.contentViewRightConstraint.constant = constant
                        }
                    } else {
                        let constant = min(deltaX, self.buttonTotalWidth())
                        if constant == self.buttonTotalWidth() {
                            self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: false)
                        } else {
                            self.contentViewLeftConstraint.constant = constant
                            
                            //                            let alpha:CGFloat = 1 - (constant / buttonTotalWidth())
                            //                            self.myContentView.alpha = alpha
                        }
                        
                    }
                }
                else { //al least partially open
                    let adjustment = self.startingLeftLayoutConstraint - deltaX
                    if !panningRight {
                        let constant = max(adjustment, 0)
                        if constant == 0 {
                            self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
                        } else {
                            //                        self.contentViewRightConstraint.constant = constant
                        }
                        
                    } else {
                        let constant = min(adjustment, self.buttonTotalWidth())
                        if constant == self.buttonTotalWidth() {
                            self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: false)
                        } else {
                            self.contentViewLeftConstraint.constant = constant
                        }
                    }
                }
                
                self.contentViewRightConstraint.constant = -self.contentViewLeftConstraint.constant
            }
            
        case .Ended:
            if movingHorizontally {
                if self.startingLeftLayoutConstraint == 0 {
                    let halfOfArea = self.buttonTotalWidth() / 2
                    if self.contentViewLeftConstraint.constant >= halfOfArea {
                        self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: true)
                    } else {
                        self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: true)
                    }
                } else {
                    //                let buttonOnePlusHalfOfButton2 = CGRectGetWidth(self.button1.frame) + (CGRectGetWidth(self.button2.frame) / 2)
                    let halfOfArea = self.buttonTotalWidth() / 2
                    if self.contentViewLeftConstraint.constant >= halfOfArea {
                        self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: true)
                    } else {
                        self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: true)
                    }
                }
            }
            
            
        case .Cancelled:
            if movingHorizontally {
                if self.startingLeftLayoutConstraint == 0 {
                    self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: true)
                } else {
                    self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: true)
                }
                
            }
            
        default:
            "Not handled"
        }
        
    }
    
    override func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //        self.resetConstraintContstantsToZero(false, notifyDelegateDidClose: false)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func buttonClicked(sender: AnyObject) {
//        self.delegate.buttonTwoActionForItemText()
        self.buttonTwoTap?()
        self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
    }
    
    @IBAction func onNoteTap(sender: UIButton) {
        onNoteTapFunc?()
    }
}
