//
//  UnitCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 19/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

protocol DefaultItemMeasureCellDelegate {
    func onLongPress(cell: DefaultItemMeasureCell)
}

class UnitCell: DefaultItemMeasureCell, UnitViewDelegate {
    
    @IBOutlet weak var unitView: UnitView!
    
    var delegate: DefaultItemMeasureCellDelegate?

    override var itemName: String {
        return unitView.unit?.name ?? ""
    }

    override func show(selected: Bool, animated: Bool) {
        unitView.showSelected(selected: selected, animated: animated)
    }

    override func show(toDelete: Bool, animated: Bool) {
        unitView.mark(toDelete: toDelete, animated: animated)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        unitView.delegate = self
    }
    
    // MARK: - UnitViewDelegate
    
    func onLongPress() {
        delegate?.onLongPress(cell: self)
    }

    // MARK: - DefaultItemMeasureCell


}
