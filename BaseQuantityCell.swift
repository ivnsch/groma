//
//  BaseQuantityCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 22/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

protocol BaseQuantityCellDelegate {
    func onLongPress(cell: BaseQuantityCell)
}

class BaseQuantityCell: UICollectionViewCell, BaseQuantityViewDelegate {
    
    @IBOutlet weak var baseQuantityView: BaseQuantityView!
    
    var delegate: BaseQuantityCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        baseQuantityView.delegate = self
    }
    
    // MARK: - BaseQuantityViewDelegate
    
    func onLongPress() {
        delegate?.onLongPress(cell: self)
    }
}
