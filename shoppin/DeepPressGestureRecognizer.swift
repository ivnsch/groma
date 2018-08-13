//
//  DeepPressGestureRecognizer.swift
//  groma
//
//  Created by Ivan Schuetz on 13.08.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//
//  Src: https://stackoverflow.com/a/38383593/930450 (modified)

import UIKit
import UIKit.UIGestureRecognizerSubclass
import AudioToolbox

class DeepPressGestureRecognizer: UIGestureRecognizer {
    fileprivate var vibrateOnDeepPress = true
    fileprivate let threshold: CGFloat = 1
    fileprivate var hardTriggerMinTime: TimeInterval = 0.5

    var onDeepPress: (() -> Void)?

    private var deepPressed: Bool = false {
        didSet {
            if (deepPressed && deepPressed != oldValue) {
                onDeepPress?()
            }
        }
    }

    fileprivate var deepPressedAt: TimeInterval = 0
    fileprivate var k_PeakSoundID: UInt32 = 1519
    fileprivate var hardAction: Selector?

    required init() {
        super.init(target: nil, action: nil)
    }

    @objc func onDeepPress(_ sender: UIGestureRecognizer) {
        // Not used - we use closure instead
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first {
            handle(touch: touch)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first {
            handle(touch: touch)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        state = deepPressed ? UIGestureRecognizerState.ended : UIGestureRecognizerState.failed
        deepPressed = false
    }

    fileprivate func handle(touch: UITouch) {
        guard let _ = view, touch.force != 0 && touch.maximumPossibleForce != 0 else {
            return
        }

        let forcePercentage = (touch.force / touch.maximumPossibleForce)
        let currentTime = Date.timeIntervalSinceReferenceDate

        if !deepPressed && forcePercentage >= threshold {
            state = UIGestureRecognizerState.began

            if vibrateOnDeepPress {
                AudioServicesPlaySystemSound(k_PeakSoundID)
            }

            deepPressedAt = Date.timeIntervalSinceReferenceDate
            deepPressed = true

        } else if deepPressed && forcePercentage <= 0 {
            endGesture()

        } else if deepPressed && currentTime - deepPressedAt > hardTriggerMinTime && forcePercentage == 1.0 {
            endGesture()

            if vibrateOnDeepPress {
                AudioServicesPlaySystemSound(k_PeakSoundID)
            }

            //fire hard press
            if let hardAction = self.hardAction {
                _ = perform(hardAction, with: self)
            }
        }
    }

    func endGesture() {
        state = UIGestureRecognizerState.ended
        deepPressed = false
    }
}
