//
//  BubbleTransition.swift
//  BubbleTransition
//
//  Created by Andrea Mazzini on 04/04/15.
//  Copyright (c) 2015 Fancy Pixel. All rights reserved.
//
// Modified by Ivan to have UIBlurEffect effect, for modified lines look for text "ivan" (based on BubbleTransition v1.0)
//
import UIKit

/**
A custom modal transition that presents and dismiss a controller with an expanding bubble effect.
*/
class BlurBubbleTransition: NSObject, UIViewControllerAnimatedTransitioning {

    /**
    The point that originates the bubble.
    */
    var startingPoint = CGPointZero {
        didSet {
            bubble.center = startingPoint
        }
    }
    
    /**
    The transition duration.
    */
    var duration = 0.5
    
    /**
    The transition direction. Either `.Present` or `.Dismiss.`
    */
    var transitionMode: BubbleTransitionMode = .Present
    
    /**
    The color of the bubble. Make sure that it matches the destination controller's background color.
    */
//    var bubbleColor: UIColor = .whiteColor() // ivan - disable color since we will not use it
    
    var bubble = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light)) // ivan - change UIView with UIVisualEffectView
    
    // MARK: - UIViewControllerAnimatedTransitioning
    
    /**
    Required by UIViewControllerAnimatedTransitioning
    */
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration
    }
    
    private func frameForBubble(originalCenter: CGPoint, size originalSize: CGSize, start: CGPoint) -> CGRect {
        let lengthX = fmax(start.x, originalSize.width - start.x);
        let lengthY = fmax(start.y, originalSize.height - start.y)
        let offset = sqrt(lengthX * lengthX + lengthY * lengthY) * 2;
        let size = CGSize(width: offset, height: offset)
        
        return CGRect(origin: CGPointZero, size: size)
    }
    
    
    /**
    Required by UIViewControllerAnimatedTransitioning
    */
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let containerView = transitionContext.containerView() else {
            return
        }
        
        if transitionMode == .Present {
            let presentedControllerView = transitionContext.viewForKey(UITransitionContextToViewKey)!
            let originalCenter = presentedControllerView.center
            let originalSize = presentedControllerView.frame.size
            
            bubble = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light)) // ivan - change UIView with UIVisualEffectView
            bubble.frame = frameForBubble(originalCenter, size: originalSize, start: startingPoint)
            bubble.layer.cornerRadius = bubble.frame.size.height / 2
            bubble.clipsToBounds = true // ivan - without this the visual effect view will not show rounded corners
            
            bubble.center = startingPoint
            bubble.transform = CGAffineTransformMakeScale(0.001, 0.001)
            //                bubble.backgroundColor = bubbleColor // ivan
            containerView.addSubview(bubble)
            
            presentedControllerView.center = startingPoint
            presentedControllerView.transform = CGAffineTransformMakeScale(0.001, 0.001)
            presentedControllerView.alpha = 0
            containerView.addSubview(presentedControllerView)
            
            UIView.animateWithDuration(duration, animations: {
                self.bubble.transform = CGAffineTransformIdentity
                presentedControllerView.transform = CGAffineTransformIdentity
                presentedControllerView.alpha = 1
                presentedControllerView.center = originalCenter
                }) { (_) in
                    transitionContext.completeTransition(true)
            }
        } else {
            let key = (transitionMode == .Pop) ? UITransitionContextToViewKey : UITransitionContextFromViewKey
            let returningControllerView = transitionContext.viewForKey(key)!
            let originalCenter = returningControllerView.center
            let originalSize = returningControllerView.frame.size
            
            bubble.frame = frameForBubble(originalCenter, size: originalSize, start: startingPoint)
            bubble.layer.cornerRadius = bubble.frame.size.height / 2
            bubble.center = startingPoint
            
            UIView.animateWithDuration(duration, animations: {
                self.bubble.transform = CGAffineTransformMakeScale(0.001, 0.001)
                returningControllerView.transform = CGAffineTransformMakeScale(0.001, 0.001)
                returningControllerView.center = self.startingPoint
                returningControllerView.alpha = 0
                
                if self.transitionMode == .Pop {
                    containerView.insertSubview(returningControllerView, belowSubview: returningControllerView)
                    containerView.insertSubview(self.bubble, belowSubview: returningControllerView)
                }
                }) { (_) in
                    returningControllerView.removeFromSuperview()
                    self.bubble.removeFromSuperview()
                    transitionContext.completeTransition(true)
            }
        }
    }
    
    /**
    The possible directions of the transition
    */
    @objc enum BubbleTransitionMode: Int {
        case Present, Dismiss, Pop
    }

    
}
