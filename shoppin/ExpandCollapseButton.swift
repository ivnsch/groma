//
//  ExpandCollapseButton.swift
//  shoppin
//
//  Created by ischuetz on 25/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

protocol ExpandCollapseButtonDelegate {
    func onExpandButton(expanded: Bool)
}

class ExpandCollapseButton: PathButton {

    var delegate: ExpandCollapseButtonDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = frame.width / CGFloat(2)
        clipsToBounds = true
        
        let model = ExpandFloatingButtonModel()
        setup(offPaths: model.collapsedPaths, onPaths: model.expandedPaths)
    }
    
    override func onTap(on: Bool) {
        delegate?.onExpandButton(on)
    }
    
    func setExpanded(expanded: Bool) {
        on = expanded
    }
}
