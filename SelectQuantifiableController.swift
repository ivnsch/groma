//
//  SelectQuantifiableController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 07/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers


class SelectQuantifiableController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var onSelected: (((quantifiableProduct: QuantifiableProduct, quantity: Float)) -> Void)?
 
    var onViewDidLoad: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        onViewDidLoad?()

        titleLabel.text = trans("popup_select_quantifiable_title")
    }
    
    var quantifiableProducts: [QuantifiableProduct] = [] {
        didSet {
            tableView.reloadData()
        }
    }
}

extension SelectQuantifiableController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quantifiableProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SelectQuantifiableCell
        cell.quantifiableProduct = quantifiableProducts[indexPath.row]
        
        // When returning cell height programatically (which we need now in order to use different cell heights for different screen sizes), here it's still the height from the storyboard so we have to pass the offset for the line to eb draw at the bottom. Apparently there's no method where we get the cell with final height (did move to superview / window also still have the height from the storyboard)
        cell.contentView.addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.defaultCellHeight)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let quantity = (tableView.cellForRow(at: indexPath) as? SelectQuantifiableCell).map{$0.quantity} ?? {
            logger.e("Invalid state: No cell for selected indexPath: \(indexPath), or cell has invalid class. Returning default quantity.")
            return 1
        }()
        
        onSelected?((quantifiableProducts[indexPath.row], quantity))
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
}
