//
//  ListItemsSectionHeaderView.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol ListItemsSectionHeaderViewDelegate {
    func onHeaderTap(header: ListItemsSectionHeaderView)
}

class ListItemsSectionHeaderView: UIView {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    var section: Section? {
        didSet {
            if let section = section {
                nameLabel.text = NSLocalizedString(section.name, comment: "")
            }
        }
    }
    
    var delegate: ListItemsSectionHeaderViewDelegate!
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        delegate?.onHeaderTap(self)
    }
}
