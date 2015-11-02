//
//  ExpandCellAnimator.swift
//  shoppin
//
//  Created by ischuetz on 31/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//
// Heavily modified version of https://github.com/ifitdoesntwork/DAExpandAnimation/

import UIKit

protocol ExpandCellAnimatorDelegate {
    func animationsForCellAnimator(isExpanding: Bool, frontView: UIView)
    func animationsComplete(wasExpanding: Bool, frontView: UIView)
    func prepareAnimations(willExpand: Bool, frontView: UIView)
}

class ExpandCellAnimator {

    var collapsedFrame: CGRect = CGRectZero
    private var topSlidingView: UIView?
    private var bottomSlidingView: UIView?

    var fromView: UIView = UIView()
    var toView: UIView = UIView()
    var inView: UIView = UIView()
    
    var delegate: ExpandCellAnimatorDelegate?
    
    func animateTransition(isExpand: Bool, topOffsetY: CGFloat, expandedViewFrame: CGRect? = nil) {
        
        fromView.layoutIfNeeded()
        
        let expandedFrame = expandedViewFrame ?? inView.bounds
        
        // Create the sliding views and add them to the scene.
        let topSlidingViewFrame = CGRect(
            x: fromView.bounds.origin.x,
            y: fromView.bounds.origin.y,
            width: fromView.bounds.width,
            height: collapsedFrame.origin.y
        )
        
        let topSlidingView = self.topSlidingView ?? {
            let view = fromView.resizableSnapshotViewFromRect(
                topSlidingViewFrame,
                afterScreenUpdates: false,
                withCapInsets: UIEdgeInsetsZero
            )
            self.topSlidingView = view
            return view
        }()
        topSlidingView.frame = CGRectMake(topSlidingViewFrame.origin.x, topSlidingViewFrame.origin.y, topSlidingViewFrame.width, topSlidingViewFrame.height)
        
        
        let bottomSlidingViewOriginY = collapsedFrame.maxY
        let bottomSlidingViewFrame = CGRect(
            x: fromView.bounds.origin.x,
            y: bottomSlidingViewOriginY,
            width: fromView.bounds.width,
            height: fromView.bounds.maxY - bottomSlidingViewOriginY
        )
        let bottomSlidingView = self.bottomSlidingView ?? {
            let view = fromView.resizableSnapshotViewFromRect(
                bottomSlidingViewFrame,
                afterScreenUpdates: false,
                withCapInsets: UIEdgeInsetsZero
            )
            self.bottomSlidingView = view
            return view
            }()
        
        //        bottomSlidingView.frame = bottomSlidingViewFrame
        bottomSlidingView.frame = CGRectMake(bottomSlidingViewFrame.origin.x, bottomSlidingViewFrame.origin.y, bottomSlidingViewFrame.width, bottomSlidingViewFrame.height)

        let collapsedFrame2 = fromView.convertRect(collapsedFrame, toView: inView) // frame in main view
        
        
//        let topSlidingDistance = collapsedFrame.origin.y - fromView.bounds.origin.y
        let topSlidingDistance = collapsedFrame2.origin.y
        let bottomSlidingDistance = inView.bounds.maxY - collapsedFrame2.maxY
        if !isExpand {
            topSlidingView.center.y -= topSlidingDistance
            bottomSlidingView.center.y += bottomSlidingDistance
        }
        
        topSlidingView.frame = fromView.convertRect(topSlidingView.frame, toView: inView)
        bottomSlidingView.frame = fromView.convertRect(bottomSlidingView.frame, toView: inView)
        inView.addSubview(topSlidingView)
        inView.addSubview(bottomSlidingView)
        
        // Add the expanding view to the scene.
        if isExpand {
//            toView.frame = CGRectMake(collapsedFrame.origin.x, collapsedFrame.origin.y, collapsedFrame.width, collapsedFrame.height)
            toView.frame = collapsedFrame2
            inView.addSubview(toView)
            // toViewAnimationsAdapter?.prepareExpandingView?(frontView)
        } else {
            // toViewAnimationsAdapter?.prepareCollapsingView?(frontView)
        }
        
        delegate?.prepareAnimations(isExpand, frontView: toView)
        
        UIView.animateWithDuration(
            0.3,
            animations: {
                if isExpand {
                    topSlidingView.center.y -= topSlidingDistance
                    bottomSlidingView.center.y += bottomSlidingDistance
                    self.toView.frame = expandedFrame
                    self.delegate?.animationsForCellAnimator(true, frontView: self.toView)
                    self.toView.layoutIfNeeded()
                    self.inView.layoutIfNeeded()
                    
                } else {
                    topSlidingView.center.y += topSlidingDistance
                    bottomSlidingView.center.y -= bottomSlidingDistance
                    //                    self.toView.frame = self.collapsedFrame
                    self.toView.frame = CGRectMake(collapsedFrame2.origin.x, collapsedFrame2.origin.y, collapsedFrame2.width, collapsedFrame2.height)
                    self.delegate?.animationsForCellAnimator(false, frontView: self.toView)
                    self.toView.layoutIfNeeded()
                    self.inView.layoutIfNeeded()
                }
            },
            completion: { _ in
                topSlidingView.removeFromSuperview()
                bottomSlidingView.removeFromSuperview()
                if !isExpand {
                    self.toView.removeFromSuperview()
                }
                self.delegate?.animationsComplete(isExpand, frontView: self.toView)
            }
        )
    }

    func reset() {
        topSlidingView = nil
        bottomSlidingView = nil
    }
}
