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


protocol SwipeableCellDelegate {
    func onStartItemSwipe()
    func onItemSwiped()
    func onButtonTwoTap()
}

enum ListItemCellMode {
    case increment, note // TODO rename Increment -> Edit, Note -> Normal
}

enum SwipeableCellDirection {
    case left, right
}

class SwipeableCell: UITableViewCell {
    
    @IBOutlet weak var button1: UIButton!
//    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    
    @IBOutlet weak var myContentView: UIView!
    
    var startingLeftLayoutConstraint: CGFloat = 0
    
    @IBOutlet weak var contentViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewLeftConstraint: NSLayoutConstraint!

    var direction: SwipeableCellDirection = .right
    
    
    var panRecognizer:UIPanGestureRecognizer!
    var panStartPoint:CGPoint!

    var swipeDelegate: SwipeableCellDelegate?
    

    fileprivate var panningRight = false
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPanCell(_:)))
        self.panRecognizer.delegate = self
        self.myContentView.addGestureRecognizer(self.panRecognizer)
        
        myContentView.translatesAutoresizingMaskIntoConstraints = false
    }
    

    func buttonTotalWidth() -> CGFloat {
        return self.frame.width
        //            - CGRectGetMinX(self.button2.frame)
    }
    
    func setOpen(_ open: Bool, animated: Bool = false) {
        if open {
            backgroundColor = UIColor.clear
            setConstraintsToShowAllButtons(animated, notifyDelegateDidOpen: false)
        } else {
            resetConstraintContstantsToZero(animated, notifyDelegateDidClose: false)
        }
    }
    
    func resetConstraintContstantsToZero(_ animated:Bool, notifyDelegateDidClose:Bool) {
        if self.startingLeftLayoutConstraint == 0 && self.contentViewLeftConstraint.constant == 0 {
            return
        }

        onResetConstraints(delta: contentViewRightConstraint.constant)
        
        self.updateConstraintsIfNeeded(animated, onCompletion: {[weak self] finished in
            if let weakSelf = self {
                weakSelf.contentViewLeftConstraint.constant = 0
                weakSelf.contentViewRightConstraint.constant = 0
                
                weakSelf.updateConstraintsIfNeeded(animated, alpha: 1, onCompletion: {finished in
                    weakSelf.startingLeftLayoutConstraint = weakSelf.contentViewLeftConstraint.constant
                    
                    weakSelf.backgroundColor = UIColor.white // resetConstraintContstantsToZero is used to set back cell when tap on it while "undo" so reset color also here... (TODO colors in 1 place now we are setting white/clear in 3 different places)
                })
            }
        })
    }
    
    func setConstraintsToShowAllButtons(_ animated: Bool, notifyDelegateDidOpen: Bool) {
        if self.startingLeftLayoutConstraint == self.buttonTotalWidth() && self.contentViewLeftConstraint.constant == self.buttonTotalWidth() {
            return
        }
        
        onShowAllButtons(delta: contentViewRightConstraint.constant)

        self.updateConstraintsIfNeeded(animated, onCompletion: { (finished) -> Void in
//            let constant = self.direction == .right ? self.buttonTotalWidth() : -self.buttonTotalWidth()
            let constant = self.panningRight ? self.buttonTotalWidth() : -self.buttonTotalWidth()
            self.contentViewLeftConstraint.constant = constant
            self.contentViewRightConstraint.constant = -constant
            
            
            self.updateConstraintsIfNeeded(animated, alpha: 0, onCompletion: {[weak self] (finished) -> Void in
                if let weakSelf = self {
                    weakSelf.startingLeftLayoutConstraint = weakSelf.contentViewLeftConstraint.constant
                    if notifyDelegateDidOpen {
                        weakSelf.onItemSwiped()
                    }
                }
            })
        })
    }
    
    
    func updateConstraintsIfNeeded(_ animated:Bool, alpha: CGFloat? = nil, onCompletion:((Bool)->Void)?) {
        var duration:TimeInterval = 0
        if animated {
            duration = 0.1
        }
        let delay:TimeInterval = 0
        
        UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions.curveEaseOut, animations: {() -> Void in
            self.layoutIfNeeded()
            if let alpha = alpha {
                self.myContentView.alpha = alpha
            }
            
            }, completion: onCompletion)
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //        self.resetConstraintContstantsToZero(false, notifyDelegateDidClose: false)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func buttonClicked(_ sender: AnyObject) {
//        self.delegate.buttonTwoActionForItemText()
        onButtonTwoTap()
        self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
    }
    
    func onStartItemSwipe() {
        // override
    }
    
    func onItemSwiped() {
        // override
    }
    
    func onButtonTwoTap() {
        // override
    }
    
    func onSwipe(delta: CGFloat, panningRight: Bool) {
        // override
    }
    
    func onShowAllButtons(delta: CGFloat) {
        // override
    }

    func onResetConstraints(delta: CGFloat) {
        // override
    }
    
    func onPanCell(_ recognizer: UIPanGestureRecognizer) {
        
        var movingHorizontally = false
        if let panStartPoint = self.panStartPoint {
            movingHorizontally = fabsf(Float(panStartPoint.y)) < fabsf(Float(panStartPoint.x))
        }
        
        switch recognizer.state {
        case .began:
            self.panStartPoint = recognizer.translation(in: self.myContentView)
            self.startingLeftLayoutConstraint = self.contentViewLeftConstraint.constant
            
            onStartItemSwipe()
            
        case .changed:
            
            if panStartPoint == CGPoint.zero {
                self.panStartPoint = recognizer.translation(in: self.myContentView)
                return
            }
            
            if movingHorizontally {
                let currentPoint = recognizer.translation(in: self.myContentView)
                let deltaX = currentPoint.x - self.panStartPoint.x
                
                if currentPoint.x == self.panStartPoint.x {
                    return // workaround, in .todo when swipe to right
                }
                
                let panningRight = currentPoint.x > self.panStartPoint.x
                self.panningRight = panningRight
                
                if self.startingLeftLayoutConstraint == 0 { //closed
                    if !panningRight {
                        let constant = max(-deltaX, 0)
                        if constant == 0 {
                            self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: false)
//                            self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
                        } else {
                            self.contentViewRightConstraint.constant = constant
                        }
                        self.contentViewLeftConstraint.constant = -self.contentViewRightConstraint.constant
                        
                    } else {
                        let constant = min(deltaX, self.buttonTotalWidth())
                        if constant == self.buttonTotalWidth() {
                            self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: false)
                        } else {
                            self.contentViewLeftConstraint.constant = constant
                            
                            //                            let alpha:CGFloat = 1 - (constant / buttonTotalWidth())
                            //                            self.myContentView.alpha = alpha
                        }
                        self.contentViewRightConstraint.constant = -self.contentViewLeftConstraint.constant
                    }
      
                } else { // at least partially open
                    let adjustment = self.startingLeftLayoutConstraint - deltaX
                    if !panningRight {
                        let constant = max(adjustment, 0)
                        if constant == 0 {
                            self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: false)
//                            self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
                        } else {
                            self.contentViewRightConstraint.constant = constant
                        }
                        self.contentViewLeftConstraint.constant = -self.contentViewRightConstraint.constant

                    } else {
                        let constant = min(adjustment, self.buttonTotalWidth())
                        if constant == self.buttonTotalWidth() {
                            self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: false)
                        } else {
                            self.contentViewLeftConstraint.constant = constant
                        }
                        self.contentViewRightConstraint.constant = -self.contentViewLeftConstraint.constant
                    }
                }
                
                // Since both sides are in sync passing one is ok
                onSwipe(delta: contentViewRightConstraint.constant, panningRight: panningRight)
            }
            
        case .ended:
            if movingHorizontally {
                
                
                let halfOfArea = self.buttonTotalWidth() / 5
                if abs(contentViewLeftConstraint.constant) >= halfOfArea {
                    self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: true)
                } else {
                    self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: true)
                }
            }
            
            
        case .cancelled:
            if movingHorizontally {
                if self.startingLeftLayoutConstraint == 0 {
                    self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: true)
                } else {
                    self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: true)
                }
                
            }
            
        default: print("Not handled")
        }
        
    }
    

}
