//
//  UnitCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 19/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

protocol UnitCellDelegate {
    func onLongPress(cell: UnitCell)
}

class UnitCell: UICollectionViewCell, UnitViewDelegate {
    
    @IBOutlet weak var unitView: UnitView!
    
    var delegate: UnitCellDelegate?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        unitView.delegate = self
    }
    
    // MARK: - UnitViewDelegate
    
    func onLongPress() {
        delegate?.onLongPress(cell: self)
    }
}
