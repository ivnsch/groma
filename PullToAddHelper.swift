//
//  PullToAddHelper.swift
//  shoppin
//
//  Created by ischuetz on 21/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class PullToAddHelper {

    var onPull: (() -> Void)?

    private var pullToRefresh: PullToRefresh?

    var consumed = false
    var consumedAnim = false

    init(tableView: UITableView, onPull: @escaping () -> Void) {
        // Pull to add isn't necessary for blind people and it confuses voice over so disable
        guard !UIAccessibility.isVoiceOverRunning else { return }

        self.onPull = onPull

        let pullToRefresh = PullToRefresh()
        let height: CGFloat = 150
        pullToRefresh.isHidden = true // hidden by default - just convenience for this app since it often interferes with animation, so we explicitly have to make it visible (usually after a delay)
        pullToRefresh.frame = CGRect(x: 0, y: -height, width: tableView.width, height: height)
        tableView.addSubview(pullToRefresh)

        self.pullToRefresh = pullToRefresh
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        // Pull to add isn't necessary for blind people and it confuses voice over so disable
        guard !UIAccessibility.isVoiceOverRunning else { return }

        let offset = scrollView.contentOffset.y
        pullToRefresh?.updateForScrollOffset(offset: offset)
        if (offset < -120 && !consumed) {
            consumed = true
            onPull?()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Pull to add isn't necessary for blind people and it confuses voice over so disable
        guard !UIAccessibility.isVoiceOverRunning else { return }

        // TODO sometimes (about 1 in 20) the + icon isn't resetted - because scrollViewDidEndDecelerating isn't called?
        // This means when the user drags down again they see a + instead of the expected arrow.
        // Non-critical, since it comes back to normal when this drag snaps back to top. But it should be fixed.
        // Note that listening to a 0 offset in scrollViewDidScroll also doesn't work because this is called
        // before the recyclerview snaps back sometimes interfering with the still valid + state, so there's flickering
        // between the animations.
        if scrollView.contentOffset.y <= 0 {
            onSnapToTop()
        }
    }

    func setHidden(_ hidden: Bool) {
        // Pull to add isn't necessary for blind people and it confuses voice over so disable
        guard !UIAccessibility.isVoiceOverRunning else { return }

        pullToRefresh?.isHidden = hidden
    }

    private func onSnapToTop() {
        consumed = false
        pullToRefresh?.scrollViewDidEndDecelerating()
    }
}
