//
//  EditableFractionCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 18/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class EditableFractionCell: UICollectionViewCell {

    @IBOutlet weak var editableFractionView: EditableFractionView!
    
    override var intrinsicContentSize: CGSize {
        return editableFractionView.intrinsicContentSize
    }

}
