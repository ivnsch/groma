//
//  ListItemsSectionHeaderView.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

protocol ListItemsSectionHeaderViewDelegate: class {
    func onHeaderTap(_ header: ListItemsSectionHeaderView)
}

class ListItemsSectionHeaderView: UIView {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    var section: Section?
    
    func config(section: Section, contracted: Bool) {
        
        self.section = section
        
        nameLabel.text = contracted ? "" : NSLocalizedString(section.name, comment: "").uppercased()
        
        backgroundColor = section.color
        nameLabel.textColor = UIColor(contrastingBlackOrWhiteColorOn: section.color, isFlat: true)
        //            nameLabel.textColor = headerFontColor
        //            nameLabel.font = headerFont
    }
    
    weak var delegate: ListItemsSectionHeaderViewDelegate!
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.onHeaderTap(self)
    }
}
