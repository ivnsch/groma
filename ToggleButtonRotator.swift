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

    var enabled: Bool = true
    
    // This is a hack to set the initial table view offset to 0, sometimes in groups or inventories list, the table view starts with -20 offset which makes the X appear rotated. Tried diabling adjust scroll view insets in storyboars etc. without success. TODO correct fix.
    func reset(_ scrollView: UIScrollView, topBar: ListTopBarView) {
        if let toggleButton = topBar.rightButton(.toggleOpen) {
            toggleButton.rotate(0)
        }
    }
    
    func rotateForOffset(_ start: CGFloat, topBar: ListTopBarView, scrollView: UIScrollView) {
        guard enabled else {return}
        guard let toggleButton = topBar.rightButton(.toggleOpen) else {return}

        let startOffset: CGFloat = start
        let offset: CGFloat = scrollView.contentOffset.y
        
        let totalAngle: CGFloat = 45
        let distanceForTotalAngle: CGFloat = 75
        
        let ratio = totalAngle / distanceForTotalAngle
        
        let currentDistance = offset - startOffset
        let currentAngle = min(0, currentDistance * ratio) // TODO when scrolling back (lifting finger) we get here 0 and arrow jumps back. Should revert gradually. When scrolling manually back this doesn't happen.
        
        toggleButton.transform = CGAffineTransform(rotationAngle: min(totalAngle.degreesToRadians, abs(currentAngle.degreesToRadians)))
    }
}
