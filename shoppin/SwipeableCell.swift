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
//    func onStartItemSwipe()
//    func onItemSwiped()
//    func onButtonTwoTap()
//}

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
    
    @IBOutlet weak var contentViewRightConstraint:NSLayoutConstraint!
    @IBOutlet weak var contentViewLeftConstraint:NSLayoutConstraint!

    var direction: SwipeableCellDirection = .right
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
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
        
        self.updateConstraintsIfNeeded(animated, onCompletion: { (finished) -> Void in
            let constant = self.direction == .right ? self.buttonTotalWidth() : -self.buttonTotalWidth()
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
            duration = 0.3
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
}
