//
//  BaseQuantityCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 22/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class BaseQuantityCell: DefaultItemMeasureCell, BaseQuantityViewDelegate {
    
    @IBOutlet weak var baseQuantityView: BaseQuantityView!
    
    var delegate: DefaultItemMeasureCellDelegate?

    override var itemName: String {
        return baseQuantityView.base?.val.quantityString ?? ""
    }

    override func show(selected: Bool, animated: Bool) {
        baseQuantityView.showSelected(selected: selected, animated: animated)
    }

    override func show(toDelete: Bool, animated: Bool) {
        baseQuantityView.mark(toDelete: toDelete, animated: animated)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        baseQuantityView.delegate = self
    }
    
    // MARK: - BaseQuantityViewDelegate
    
    func onLongPress() {
        delegate?.onLongPress(cell: self)
    }
}
