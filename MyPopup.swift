//
//  MyPopup.swift
//  groma
//
//  Created by Ivan Schuetz on 07.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

enum MyPopupAnimType {
    case grow, fall
}

class MyPopup: UIView {

    var contentView: UIView? {
        didSet {
            if let contentView = contentView {
                addSubview(contentView)
                contentView.layer.cornerRadius = cornerRadius
            }
        }
    }

    var backgroundAlpha: CGFloat = 0 {
        didSet {
            backgroundView.alpha = backgroundAlpha
        }
    }

    var cornerRadius: CGFloat = 0
    
    var backgroundFadeDuration: TimeInterval = 0
    var scaleDuration: TimeInterval = 0.3

    fileprivate weak var parent: UIView?

    var onTapBackground: (() -> Void)?

    // If not set, parent's center is used
    var contentCenter: CGPoint?

    fileprivate lazy var backgroundView: HandlingView = {
        let view = HandlingView(frame: self.bounds)
        return view
    } ()

    fileprivate var showFrom: CGPoint?

    var animType: MyPopupAnimType = .fall

    // used only in fall - optional y offset of target position (which is the center of the parent)
    // this is pased on show, stored here to restore it in return to origin
    fileprivate var centerYOffset: CGFloat = 0

    convenience init(parent: UIView) {
        self.init(parent: parent, frame: parent.bounds)
    }

    convenience init(parent: UIView, frame: CGRect) {
        self.init(frame: frame)
        self.parent = parent
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear

        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0
        backgroundView.touchHandler = { [weak self] in
            self?.onTapBackground?()
        }
        addSubview(backgroundView)
    }

    func show(from: UIView, offsetY: CGFloat = 0, onFinish: (() -> Void)? = nil) {
        guard let parent = parent else { logger.e("No parent!"); return }
        if let superview = from.superview {
            let from = superview.convert(from.center, to: parent)
            let finalfrom = CGPoint(x: from.x, y: from.y + offsetY)
            show(parent: parent, from: finalfrom, onFinish: onFinish)
        }
    }

    func hide(onFinish: (() -> Void)? = nil) {
        animateGrowHide(onFinish: { [weak self] in
            self?.removeFromSuperview()
            onFinish?()
        })
    }

    func showFall(centerYOffset: CGFloat = 0, onFinish: (() -> Void)? = nil) {
        guard let parent = parent else { logger.e("No parent!"); return }
        parent.addSubview(self)
        animateFallShow(parent: parent, centerYOffset: centerYOffset, onFinish: onFinish)
    }

    func hideFall(direction: DirectionUpDown = .up, onFinish: (() -> Void)? = nil) {
        animateFallHide(direction: direction, onFinish: { [weak self] in
            self?.removeFromSuperview()
            onFinish?()
        })
    }

    func hideFullFall(direction: DirectionUpDown = .up, onFinish: (() -> Void)? = nil) {
        animateFullFallHide(direction: direction, onFinish: { [weak self] in
            self?.removeFromSuperview()
            onFinish?()
        })
    }

    func returnToOriginFall(direction: DirectionUpDown = .up, onFinish: (() -> Void)? = nil) {
        guard let parent = parent else { logger.e("No parent!"); return }
        animateFallReturnToOrigin(parent: parent, onFinish: {
            onFinish?()
        })
    }

    fileprivate func show(parent: UIView, from: CGPoint? = nil, onFinish: (() -> Void)?) {
        parent.addSubview(self)
        animateGrowShow(parent: parent, from: from, onFinish: onFinish)
    }

    fileprivate func animateGrowShow(parent: UIView, from: CGPoint? = nil, onFinish: (() -> Void)?) {
        if let from = from {
            showFrom = from

            contentView?.center = from
            contentView?.transform = CGAffineTransform(scaleX: 0.00001, y: 0.00001)

            UIView.animate(withDuration: scaleDuration, animations: {
                self.contentView?.center = self.contentCenter ?? parent.center
                self.contentView?.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: { finished in
                onFinish?()
            })
        }

        if backgroundAlpha > 0 {
            UIView.animate(withDuration: backgroundFadeDuration, animations: {
                self.backgroundView.alpha = self.backgroundAlpha
            })
        }
    }

    fileprivate func animateGrowHide(onFinish: @escaping (() -> Void)) {

        // Remove when the slowest anim finishes
        let removeOnScaleFinish: Bool = { if scaleDuration > backgroundFadeDuration { return true } else { return false } } ()

        if let from = showFrom {
            UIView.animate(withDuration: scaleDuration, delay: 0, options: [], animations: {
                self.contentView?.center = from
                self.contentView?.transform = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
            }, completion: { finished in
                if removeOnScaleFinish {
                    onFinish()
                }
            })
        }

        if backgroundAlpha > 0 {
            UIView.animate(withDuration: backgroundFadeDuration, delay: 0, options: [], animations: {
                self.backgroundView.alpha = 0
            }, completion: { finished in
                if !removeOnScaleFinish {
                    onFinish()
                }
            })
        }

        // If there are no animations, remove immediately
        if showFrom == nil && backgroundAlpha == 0 {
            onFinish()
        }
    }

    fileprivate func animateFallShow(parent: UIView, centerYOffset: CGFloat = 0, onFinish: (() -> Void)?) {
        let from = parent.center.copy(y: parent.center.y + centerYOffset - 100) // start a little above from target (thus "fall")
        animateFallShow(parent: parent, from: from, centerYOffset: centerYOffset, onFinish: onFinish)
    }

    fileprivate func animateFallShow(parent: UIView, from: CGPoint, centerYOffset: CGFloat = 0, onFinish: (() -> Void)?) {
        showFrom = from

        contentView?.center = from
        contentView?.alpha = 0

        self.centerYOffset = centerYOffset

        UIView.animate(withDuration: scaleDuration, animations: {
            self.contentView?.center = parent.center.copy(y: parent.center.y + centerYOffset)
            self.contentView?.alpha = 1
        }, completion: { finished in
            onFinish?()
        })

        if backgroundAlpha > 0 {
            UIView.animate(withDuration: backgroundFadeDuration, animations: {
                self.backgroundView.alpha = self.backgroundAlpha
            })
        }
    }

    fileprivate func animateFallHide(direction: DirectionUpDown, onFinish: @escaping (() -> Void)) {
        guard let contentView = self.contentView else {
            logger.e("No content view! Can't hide.", .ui)
            return
        }

        // Remove when the slowest anim finishes
        let removeOnScaleFinish: Bool = { if scaleDuration > backgroundFadeDuration { return true } else { return false } } ()

        UIView.animate(withDuration: scaleDuration, delay: 0, options: [], animations: {
            // Note that we don't animate to `from` but use a delta, since when swiped the popup isn't at the target/center location. So we just want to go a little up, from wherever it is.
            let delta: CGFloat = 100
            contentView.center = CGPoint(x: contentView.center.x, y: contentView.center.y + (direction == .up ? -delta : delta))
            contentView.alpha = 0
        }, completion: { finished in
            if removeOnScaleFinish {
                onFinish()
            }
        })

        if backgroundAlpha > 0 {
            UIView.animate(withDuration: backgroundFadeDuration, delay: 0, options: [], animations: {
                self.backgroundView.alpha = 0
            }, completion: { finished in
                if !removeOnScaleFinish {
                    onFinish()
                }
            })
        }

        // If there are no animations, remove immediately
        if showFrom == nil && backgroundAlpha == 0 {
            onFinish()
        }
    }

    fileprivate func animateFullFallHide(direction: DirectionUpDown, onFinish: @escaping (() -> Void)) {
        guard let contentView = self.contentView else {
            logger.e("No content view! Can't hide.", .ui)
            return
        }

        // Remove when the slowest anim finishes
        let removeOnScaleFinish: Bool = { if scaleDuration > backgroundFadeDuration { return true } else { return false } } ()

        UIView.animate(withDuration: scaleDuration, delay: 0, options: [], animations: {
            // Note that we don't animate to `from` but use a delta, since when swiped the popup isn't at the target/center location. So we just want to go a little up, from wherever it is.
            let delta: CGFloat = 500
            contentView.center = CGPoint(x: contentView.center.x, y: contentView.center.y + (direction == .up ? -delta : delta))
            contentView.alpha = 0
        }, completion: { finished in
            if removeOnScaleFinish {
                onFinish()
            }
        })

        if backgroundAlpha > 0 {
            UIView.animate(withDuration: backgroundFadeDuration, delay: 0, options: [], animations: {
                self.backgroundView.alpha = 0
            }, completion: { finished in
                if !removeOnScaleFinish {
                    onFinish()
                }
            })
        }

        // If there are no animations, remove immediately
        if showFrom == nil && backgroundAlpha == 0 {
            onFinish()
        }
    }


    fileprivate func animateFallReturnToOrigin(parent: UIView, onFinish: @escaping (() -> Void)) {
        UIView.animate(withDuration: scaleDuration, delay: 0, usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0, options: [], animations: {
                        self.contentView?.center = parent.center.copy(y: parent.center.y + self.centerYOffset)
                        self.contentView?.alpha = 1 // ensure alpha at the end is 0
        }) { _ in
            onFinish()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

