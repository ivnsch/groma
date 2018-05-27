//
//  PullToRefresh.swift
//  groma
//
//  Created by Ivan Schuetz on 26.05.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

@IBDesignable
class PullToRefresh: UIView {

    @IBOutlet weak var pullButton: PathButton!
    @IBOutlet weak var label: UILabel!

    private var expanded: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }

    fileprivate func xibSetup() {
        let view = Bundle.loadView("PullToRefresh", owner: self)!

        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        view.fillSuperview()

        isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true

        setupButton()
    }

    private func setupButton() {
        let model = PullToRefreshArrowModel()
        pullButton.setup(offPaths: model.collapsedPaths, onPaths: model.expandedPaths, lineWidth: 3.2)
        pullButton.strokeColor = UIColor.white
    }

    func updateForScrollOffset(offset: CGFloat, startOffset: CGFloat = 0) {
        if offset < -110 && !expanded {
            expanded = true
            pullButton.on = true
        } else if offset == 0 {

        }
    }

    func scrollViewDidEndDecelerating() {
        pullButton.on = false
        expanded = false
    }
}
