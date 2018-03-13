//
//  EmptyViewCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 28/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class EmptyViewCell: UITableViewCell {

    @IBOutlet weak var view: EmptyView!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = Theme.mainBGColor
    }
}
