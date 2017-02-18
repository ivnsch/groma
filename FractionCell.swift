//
//  FractionCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 10/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

protocol FractionCellDelegate {
    func onLongPress(cell: FractionCell)
}

class FractionCell: UICollectionViewCell, FractionViewDelegate {

    @IBOutlet weak var fractionView: FractionView!
    
    var delegate: FractionCellDelegate?
 
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        fractionView.delegate = self
    }
    
    // MARK: - FractionViewDelegate
    
    func onLongPress() {
        delegate?.onLongPress(cell: self)
    }
}
