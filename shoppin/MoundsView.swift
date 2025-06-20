//
//  MoundsView.swift
//  groma
//
//  Created by Ivan Schuetz on 16.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

@IBDesignable
class MoundsView: UIView, QuantityImage {

    fileprivate var wholeView: UIView?
    fileprivate var fractionView: UIView?

    fileprivate let wholeOneSize: CGFloat = 150
    fileprivate var wholeOneHeight: CGFloat {
        return wholeOneSize * 0.4622560538 // aspect ratio of the image (this is only for the whole image - it's not exactly the same as the fraction image but for now we reuse it - the bottom line covers the imperfection.
    }

    fileprivate var didLayoutSubviews = false
    fileprivate var wholeOriginalFrame: CGRect = CGRect.zero
    fileprivate var fractionOriginalFrame: CGRect = CGRect.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    fileprivate func sharedInit() {
        clipsToBounds = false

        let wholeView = UIImageView()
        wholeView.image = #imageLiteral(resourceName: "mound1")
        wholeView.contentMode = .scaleAspectFit
        wholeView.frame.size = CGSize(width: wholeOneSize, height: wholeOneHeight)
        addSubview(wholeView)
        self.wholeView = wholeView

        let fractionView = UIImageView()
        fractionView.image = #imageLiteral(resourceName: "mound2")
        fractionView.contentMode = .scaleAspectFit
        fractionView.frame.size = CGSize(width: wholeOneSize, height: wholeOneHeight)
        addSubview(fractionView)
        self.fractionView = fractionView
    }

    fileprivate func calculateWholeViewScale(wholePart: Int) -> CGFloat {
        if wholePart == 0 || wholePart == 1 { return CGFloat(wholePart) }
        else {
            let mult = 1 + CGFloat(wholePart) * 0.1 // 0.1 - higher values make it grow quicker
            return min(1.4, mult) // don't grow more than 1.4x
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard !didLayoutSubviews else { return }
        didLayoutSubviews = true

        guard let wholeView = wholeView, let fractionView = fractionView else { return }

        let originX = (frame.width - wholeView.width) / 2
        let originY = (frame.height - wholeOneHeight) / 2

        wholeView.frame.origin = CGPoint(x: originX, y: originY)
        fractionView.frame.origin = CGPoint(x: center.x, y: wholeView.frame.origin.y)

        wholeOriginalFrame = wholeView.frame
        fractionOriginalFrame = fractionView.frame

        // Bottom line
        let line = UIView()
        line.backgroundColor = UIColor(hexString: "4A90E2")
        line.frame.size = CGSize(width: 300, height: 6)
        line.layer.cornerRadius = 3
        addSubview(line)
        line.center = CGPoint(x: center.x, y: wholeView.frame.maxY)
    }

    // MARK: QuantityImage

    func showQuantity(whole: Int, fraction: Fraction, animated: Bool) {
        guard let wholeView = wholeView, let fractionView = fractionView else {
            logger.e("Views not initialized yet")
            return
        }

        let minScale: CGFloat = 0.00001 // if 0 the view disappears and can't be scaled up again
        let wholeViewScale = max(minScale, calculateWholeViewScale(wholePart: whole))
        scaleFrame(view: wholeView, originalFrame: wholeOriginalFrame, scale: wholeViewScale, animated: animated)
        let fractionViewScale = max(minScale, CGFloat(fraction.decimalValue))
        scaleFrame(view: fractionView, originalFrame: fractionOriginalFrame, scale: fractionViewScale, animated: animated)
    }

    fileprivate func scaleFrame(view: UIView, originalFrame: CGRect, scale: CGFloat, animated: Bool) {
        let scaledWidth = originalFrame.width * scale
        let scaledHeight = originalFrame.height * scale

        let xDelta = scaledWidth - originalFrame.width
        let newX = originalFrame.minX - xDelta / 2
        let newY = originalFrame.maxY - scaledHeight
        let newFrame = CGRect(x: newX, y: newY, width: scaledWidth, height: scaledHeight)

        func update() {
            view.frame = newFrame
        }

        if animated {
            if view.frame != newFrame {
                UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5,
                               initialSpringVelocity: 0, options: [], animations: {
                    update()
                }) { _ in }
            }
        } else {
            update()
        }
    }
}
