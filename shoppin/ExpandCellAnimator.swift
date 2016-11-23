//
//  ExpandCellAnimator.swift
//  shoppin
//
//  Created by ischuetz on 31/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//
// Heavily modified version of https://github.com/ifitdoesntwork/DAExpandAnimation/

import UIKit

protocol ExpandCellAnimatorDelegate: class {
    func animationsForCellAnimator(_ isExpanding: Bool, frontView: UIView)
    func animationsComplete(_ wasExpanding: Bool, frontView: UIView)
    func prepareAnimations(_ willExpand: Bool, frontView: UIView)
}

class ExpandCellAnimator {

    var collapsedFrame: CGRect = CGRect.zero
    fileprivate var topSlidingView: UIView?
    fileprivate var bottomSlidingView: UIView?

    weak var fromView: UIView? = UIView()
    weak var toView: UIView? = UIView()
    weak var inView: UIView? = UIView()
    
    weak var delegate: ExpandCellAnimatorDelegate?
    
    func animateTransition(_ isExpand: Bool, topOffsetY: CGFloat, expandedViewFrame: CGRect? = nil) {
        
        guard let fromView = fromView, let toView = toView, let inView = inView else {return}
        
        
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
            let view = fromView.resizableSnapshotView(
                from: topSlidingViewFrame,
                afterScreenUpdates: false,
                withCapInsets: UIEdgeInsets.zero
            )
            self.topSlidingView = view
            return view!
        }()
        topSlidingView.frame = CGRect(x: topSlidingViewFrame.origin.x, y: topSlidingViewFrame.origin.y, width: topSlidingViewFrame.width, height: topSlidingViewFrame.height)
        
        
        let bottomSlidingViewOriginY = collapsedFrame.maxY
        let bottomSlidingViewFrame = CGRect(
            x: fromView.bounds.origin.x,
            y: bottomSlidingViewOriginY,
            width: fromView.bounds.width,
            height: fromView.bounds.maxY - bottomSlidingViewOriginY
        )
        let bottomSlidingView = self.bottomSlidingView ?? {
            let view = fromView.resizableSnapshotView(
                from: bottomSlidingViewFrame,
                afterScreenUpdates: false,
                withCapInsets: UIEdgeInsets.zero
            )
            self.bottomSlidingView = view
            return view!
            }()
        
        //        bottomSlidingView.frame = bottomSlidingViewFrame
        bottomSlidingView.frame = CGRect(x: bottomSlidingViewFrame.origin.x, y: bottomSlidingViewFrame.origin.y, width: bottomSlidingViewFrame.width, height: bottomSlidingViewFrame.height)

        let collapsedFrame2 = fromView.convert(collapsedFrame, to: inView) // frame in main view
        
        
//        let topSlidingDistance = collapsedFrame.origin.y - fromView.bounds.origin.y
        let topSlidingDistance = collapsedFrame2.origin.y
        let bottomSlidingDistance = inView.bounds.maxY - collapsedFrame2.maxY
        if !isExpand {
            topSlidingView.center.y -= topSlidingDistance
            bottomSlidingView.center.y += bottomSlidingDistance
        }
        
        topSlidingView.frame = fromView.convert(topSlidingView.frame, to: inView)
        bottomSlidingView.frame = fromView.convert(bottomSlidingView.frame, to: inView)
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
        
        UIView.animate(
            withDuration: 0.3,
            animations: {[weak self] in guard let weakSelf = self else {return}
                if isExpand {
                    topSlidingView.center.y -= topSlidingDistance
                    bottomSlidingView.center.y += bottomSlidingDistance
                    toView.frame = expandedFrame
                    weakSelf.delegate?.animationsForCellAnimator(true, frontView: toView)
                    toView.layoutIfNeeded()
                    inView.layoutIfNeeded()
                    
                } else {
                    topSlidingView.center.y += topSlidingDistance
                    bottomSlidingView.center.y -= bottomSlidingDistance
                    //                    self.toView.frame = self.collapsedFrame
                    toView.frame = CGRect(x: collapsedFrame2.origin.x, y: collapsedFrame2.origin.y, width: collapsedFrame2.width, height: collapsedFrame2.height)
                    weakSelf.delegate?.animationsForCellAnimator(false, frontView: toView)
                    toView.layoutIfNeeded()
                    inView.layoutIfNeeded()
                }
            },
            completion: {[weak self] _ in guard let weakSelf = self else {return}
                topSlidingView.removeFromSuperview()
                bottomSlidingView.removeFromSuperview()
                if !isExpand {
                    toView.removeFromSuperview()
                }
                weakSelf.delegate?.animationsComplete(isExpand, frontView: toView)
            }
        )
    }

    func reset() {
        topSlidingView = nil
        bottomSlidingView = nil
    }
}
