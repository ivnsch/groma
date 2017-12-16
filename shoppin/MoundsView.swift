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
    fileprivate var xSpacing: CGFloat = -10

    fileprivate let wholeOneSize: CGFloat = 50

    fileprivate var didLayoutSubviews = false

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

        let wholeView = UIView()
        wholeView.frame.size = CGSize(width: wholeOneSize, height: wholeOneSize)
        wholeView.backgroundColor = UIColor.flatRed
        addSubview(wholeView)
        self.wholeView = wholeView

        let fractionView = UIView()
        fractionView.frame.size = CGSize(width: wholeOneSize, height: wholeOneSize)
        fractionView.backgroundColor = UIColor.flatGreen
        addSubview(fractionView)
        self.fractionView = fractionView

    }

    fileprivate func calculateWholeViewScale(wholePart: Int) -> CGFloat {
        if wholePart == 0 || wholePart == 1 { return CGFloat(wholePart) }
        else {
            let mult = CGFloat(wholePart) * 0.54
            return min(2, mult)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard !didLayoutSubviews else { return }
        didLayoutSubviews = true

        guard let wholeView = wholeView, let fractionView = fractionView else { return }

        _ = wholeView.setAnchorWithoutMovingNoTransform(CGPoint(x: 0, y: 1))
        _ = fractionView.setAnchorWithoutMovingNoTransform(CGPoint(x: 0, y: 1))

        let minX = wholeView.frame.origin.x
        let maxX = minX + wholeView.frame.width + fractionView.frame.width
        let contentWidth = maxX - minX

        let originX = (frame.width - contentWidth) / 2
        let originY = (frame.height - wholeOneSize) / 2

        wholeView.frame.origin = CGPoint(x: originX, y: originY)
        fractionView.frame.origin = CGPoint(x: wholeView.frame.origin.x + wholeView.frame.width, y: wholeView.frame.origin.y)
    }

    // MARK: QuantityImage

    func showQuantity(whole: Int, fraction: Fraction) {
        guard let wholeView = wholeView, let fractionView = fractionView else {
            print("Views not initialized yet")
            return
        }

//        xSpacing = xSpacing + CGFloat(whole) * 4
        xSpacing = 0
        fractionView.frame.origin.x = fractionView.frame.origin.x + xSpacing

        let minScale: CGFloat = 0.00001 // if 0 the view disappears and can't be scaled up again
        let wholeViewScale = max(minScale, calculateWholeViewScale(wholePart: whole))
        wholeView.transform = CGAffineTransform.identity.scaledBy(x: wholeViewScale, y: wholeViewScale)
        let fractionViewScale = max(minScale, CGFloat(fraction.decimalValue))
        fractionView.transform = CGAffineTransform.identity.scaledBy(x: fractionViewScale, y: fractionViewScale)
    }
}
