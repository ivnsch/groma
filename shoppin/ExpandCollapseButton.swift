//
//  ExpandCollapseButton.swift
//  shoppin
//
//  Created by ischuetz on 25/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

protocol ExpandCollapseButtonDelegate: class {
    func onExpandButton(expanded: Bool)
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = frame.width / CGFloat(2)
        clipsToBounds = true
        
        let model = ExpandFloatingButtonModel()
        setup(offPaths: model.collapsedPaths, onPaths: model.expandedPaths)

        strokeColor = UIColor(hexString: "2C3D50")
    }
    
    override func onTap(on: Bool) {
        delegate?.onExpandButton(on)
    }
}
