//
//  ToggleButtonRotator.swift
//  shoppin
//
//  Created by ischuetz on 21/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class ToggleButtonRotator {

    func rotateForOffset(start: CGFloat, topBar: ListTopBarView, scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        if offset < start
//            && offset < lastScrollViewOffset
        {
//            lastScrollViewOffset = offset
            let max: CGFloat = start - 60 // the smaller the value the quicker the button will reach its final rotation
            let current = scrollView.contentOffset.y - start
            let rotationPercent: CGFloat = current / (max - start) // value between 0 and 1 indicating how much of the total rotation we want to rotate
            let truncatedRotationPercent = min(abs(rotationPercent), 1)
            if let toggleButton = topBar.rightButton(.ToggleOpen) {
                let degrees = 45 * truncatedRotationPercent
                toggleButton.rotate(Double(degrees))
            }
        }
    }
}
