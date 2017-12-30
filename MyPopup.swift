//
//  MyPopup.swift
//  groma
//
//  Created by Ivan Schuetz on 07.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

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

    fileprivate func show(parent: UIView, from: CGPoint? = nil, onFinish: (() -> Void)?) {
        parent.addSubview(self)

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

    func hide(onFinish: (() -> Void)? = nil) {

        func onFinishAnimation() {
            removeFromSuperview()
            onFinish?()
        }

        // Remove when the slowest anim finishes
        let removeOnScaleFinish: Bool = { if scaleDuration > backgroundFadeDuration { return true } else { return false } } ()

        if let from = showFrom {
            UIView.animate(withDuration: scaleDuration, delay: 0, options: [], animations: {
                self.contentView?.center = from
                self.contentView?.transform = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
            }, completion: { finished in
                if removeOnScaleFinish {
                    onFinishAnimation()
                }
            })
        }

        if backgroundAlpha > 0 {
            UIView.animate(withDuration: backgroundFadeDuration, delay: 0, options: [], animations: {
                self.backgroundView.alpha = 0
            }, completion: { finished in
                if !removeOnScaleFinish {
                    onFinishAnimation()
                }
            })
        }

        // If there are no animations, remove immediately
        if showFrom == nil && backgroundAlpha == 0 {
            onFinishAnimation()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

