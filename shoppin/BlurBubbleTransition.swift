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
    var startingPoint = CGPoint.zero {
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
    var transitionMode: BubbleTransitionMode = .present
    
    /**
    The color of the bubble. Make sure that it matches the destination controller's background color.
    */
//    var bubbleColor: UIColor = .whiteColor() // ivan - disable color since we will not use it
    
    var bubble = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.light)) // ivan - change UIView with UIVisualEffectView
    
    // MARK: - UIViewControllerAnimatedTransitioning
    
    /**
    Required by UIViewControllerAnimatedTransitioning
    */
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    fileprivate func frameForBubble(_ originalCenter: CGPoint, size originalSize: CGSize, start: CGPoint) -> CGRect {
        let lengthX = fmax(start.x, originalSize.width - start.x);
        let lengthY = fmax(start.y, originalSize.height - start.y)
        let offset = sqrt(lengthX * lengthX + lengthY * lengthY) * 2;
        let size = CGSize(width: offset, height: offset)
        
        return CGRect(origin: CGPoint.zero, size: size)
    }
    
    
    /**
    Required by UIViewControllerAnimatedTransitioning
    */
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        
        if transitionMode == .present {
            let presentedControllerView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
            let originalCenter = presentedControllerView.center
            let originalSize = presentedControllerView.frame.size
            
            bubble = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.light)) // ivan - change UIView with UIVisualEffectView
            bubble.frame = frameForBubble(originalCenter, size: originalSize, start: startingPoint)
            bubble.layer.cornerRadius = bubble.frame.size.height / 2
            bubble.clipsToBounds = true // ivan - without this the visual effect view will not show rounded corners
            
            bubble.center = startingPoint
            bubble.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            //                bubble.backgroundColor = bubbleColor // ivan
            containerView.addSubview(bubble)
            
            presentedControllerView.center = startingPoint
            presentedControllerView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            presentedControllerView.alpha = 0
            containerView.addSubview(presentedControllerView)
            
            UIView.animate(withDuration: duration, animations: {
                self.bubble.transform = CGAffineTransform.identity
                presentedControllerView.transform = CGAffineTransform.identity
                presentedControllerView.alpha = 1
                presentedControllerView.center = originalCenter
                }, completion: { (_) in
                    transitionContext.completeTransition(true)
            }) 
        } else {
            let key = (transitionMode == .pop) ? UITransitionContextViewKey.to : UITransitionContextViewKey.from
            let returningControllerView = transitionContext.view(forKey: key)!
            let originalCenter = returningControllerView.center
            let originalSize = returningControllerView.frame.size
            
            bubble.frame = frameForBubble(originalCenter, size: originalSize, start: startingPoint)
            bubble.layer.cornerRadius = bubble.frame.size.height / 2
            bubble.center = startingPoint
            
            UIView.animate(withDuration: duration, animations: {
                self.bubble.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                returningControllerView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                returningControllerView.center = self.startingPoint
                returningControllerView.alpha = 0
                
                if self.transitionMode == .pop {
                    containerView.insertSubview(returningControllerView, belowSubview: returningControllerView)
                    containerView.insertSubview(self.bubble, belowSubview: returningControllerView)
                }
                }, completion: { (_) in
                    returningControllerView.removeFromSuperview()
                    self.bubble.removeFromSuperview()
                    transitionContext.completeTransition(true)
            }) 
        }
    }
    
    /**
    The possible directions of the transition
    */
    @objc enum BubbleTransitionMode: Int {
        case present, dismiss, pop
    }

    
}
