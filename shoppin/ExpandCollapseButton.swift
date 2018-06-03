//
//  ExpandCollapseButton.swift
//  shoppin
//
//  Created by ischuetz on 25/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

protocol ExpandCollapseButtonDelegate: class {
    func onExpandButton(_ expanded: Bool)
}

class ExpandCollapseButton: PathButton {

    weak var delegate: ExpandCollapseButtonDelegate?
    
    var expanded: Bool {
        set {
            on = newValue
        }
        get {
            return on
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        sharedInit()
    }

    private func sharedInit() {
        layer.cornerRadius = frame.width / CGFloat(2)
        clipsToBounds = true

        let model = ExpandFloatingButtonModel()
        setup(offPaths: model.collapsedPaths, onPaths: model.expandedPaths)

        strokeColor = UIColor(hexString: "2D3D4F")
    }

    override var intrinsicContentSize: CGSize {
        // TODO don't fix the size - using this for now since used only in top bar and we need 25x25 there
        return CGSize(width: 20, height: 20)
    }

    override func onTap(_ on: Bool) {
        delegate?.onExpandButton(on)
    }
}
