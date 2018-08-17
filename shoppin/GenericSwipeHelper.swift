//
//  GenericSwipeHelper.swift
//  groma
//
//  Created by Ivan Schuetz on 20.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class GenericSwipeHelper: NSObject, UIGestureRecognizerDelegate {

    fileprivate weak var view: UIView?

    fileprivate var panRecognizer: UIPanGestureRecognizer!
    fileprivate var panStartPoint: CGPoint!
    fileprivate var panLastPoint: CGPoint!

    fileprivate let delta: CGFloat
    fileprivate let orientation: Orientation

    fileprivate let onEnded: ((CGFloat) -> Void)
    fileprivate let onDelta: ((CGFloat, CGFloat) -> Void)

    fileprivate var cancelTouches: Bool

    init(view: UIView, delta: CGFloat = 50, orientation: Orientation = .horizontal, cancelTouches: Bool = true, onDelta: @escaping ((CGFloat, CGFloat) -> Void), onEnded: @escaping ((CGFloat) -> Void)) {
        self.view = view
        self.delta = delta
        self.orientation = orientation
        self.onDelta = onDelta
        self.onEnded = onEnded
        self.cancelTouches = cancelTouches

        super.init()

        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(GenericSwipeHelper.onPan(_:)))
        panRecognizer.delegate = self
        panRecognizer.cancelsTouchesInView = cancelTouches
        view.addGestureRecognizer(self.panRecognizer)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return !cancelTouches
    }

    fileprivate func getDeltas(currentPoint: CGPoint) -> (CGFloat, CGFloat) {

        let (delta, totalDelta) : (CGFloat, CGFloat) = {
            if orientation == .horizontal {
                return (currentPoint.x - panLastPoint.x, currentPoint.x - panStartPoint.x)
            } else {
                return (currentPoint.y - panLastPoint.y, currentPoint.y - panStartPoint.y)
            }
        } ()

        // Playing with friction but it's looking good without it
//        let friction: CGFloat = abs(totalDelta) > 40 ? 0.2 : 0.6
//        return (delta * friction, totalDelta * friction)

        return (delta, totalDelta)
    }

    @objc func onPan(_ recognizer: UIPanGestureRecognizer) {

        guard let view = view else {logger.e("No view"); return}

        let movingHorizontally = abs(recognizer.velocity(in: view).x) >= abs(recognizer.velocity(in: view).y)
        let movementOrientation: Orientation = movingHorizontally ? .horizontal : .vertical

        switch recognizer.state {
        case .began:
            panStartPoint = recognizer.translation(in: view)
            panLastPoint = panStartPoint

        case .changed:
            if movementOrientation == orientation {
                let currentPoint = recognizer.translation(in: view)
                let (delta, totalDelta) = getDeltas(currentPoint: currentPoint)
                onDelta(delta, totalDelta)
                panLastPoint = currentPoint
            }

        case .failed:
            logger.i("Failed pan")

        case .cancelled:
            logger.i("Cancelled pan")

        case .ended:
            let currentPoint = recognizer.translation(in: view)
            let (_, totalDelta) = getDeltas(currentPoint: currentPoint)

            onEnded(totalDelta)

            panStartPoint = nil
            panLastPoint = nil

        default:
            logger.w("Not handled: \(recognizer.state)")
        }
    }

}
