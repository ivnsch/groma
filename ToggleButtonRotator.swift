//
//  ToggleButtonRotator.swift
//  shoppin
//
//  Created by ischuetz on 21/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs


class ToggleButtonRotator {

    // This is a hack to set the initial table view offset to 0, sometimes in groups or inventories list, the table view starts with -20 offset which makes the X appear rotated. Tried diabling adjust scroll view insets in storyboars etc. without success. TODO correct fix.
    func reset(scrollView: UIScrollView, topBar: ListTopBarView) {
        if let toggleButton = topBar.rightButton(.ToggleOpen) {
            toggleButton.rotate(0)
        }
    }
    
    func rotateForOffset(start: CGFloat, topBar: ListTopBarView, scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
//        QL1("Call rotate for offset, offset: \(offset)")
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
