//
//  UnitEditableCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 19/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class UnitEditableCell: UICollectionViewCell {
 
    @IBOutlet weak var editableUnitView: UnitEditableView!
    
    override var intrinsicContentSize: CGSize {
        return editableUnitView.intrinsicContentSize
    }
}
