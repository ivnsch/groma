//
//  QuickAddGroupItemsViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol QuickAddGroupItemsViewControllerDelegate {
    func onSubmit(items: [GroupItem])
    func onCancel()
}

class QuickAddGroupItemsViewController: UIViewController, QuickAddGroupItemsTableViewControllerDelegate {

    @IBOutlet weak var itemsLabel: UILabel!
    @IBOutlet weak var itemsTableViewContainer: UIView!
    
    var list: List? // TODO list should not be necessary here
    
    var groupItemsController: QuickAddGroupItemsTableViewController?
    
    private var itemsDictionary = OrderedDictionary<String, GroupItem>()
    
    var delegate: QuickAddGroupItemsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let groupItemsController = UIStoryboard.wuickAddGroupItemsTableViewController()
        itemsTableViewContainer.addSubview(groupItemsController.view)
        addChildViewController(groupItemsController)
          groupItemsController.view.translatesAutoresizingMaskIntoConstraints = false
        groupItemsController.view.fillSuperview()
        groupItemsController.delegate = self
        self.groupItemsController = groupItemsController
    }
    
    func submit() {
        delegate?.onSubmit(itemsDictionary.values)
    }
    
    // MARK: - QuickAddGroupItemsTableViewControllerDelegate
    
    func incrementProduct(product: Product, quantity: Int) {
//        
//        let incrementedItem: GroupItem = {
//            if let item = itemsDictionary[product.uuid] {
//                return item.copy(quantity: item.quantity + quantity)
//            } else {
//                // TODO section
//                return GroupItem(uuid: NSUUID().UUIDString, quantity: quantity, product: product)
//            }
//        }()
//        
//        if incrementedItem.quantity > 0 {
//            itemsDictionary[incrementedItem.product.uuid] = incrementedItem
//        } else {
//            itemsDictionary.removeIfExists(incrementedItem.product.uuid)
//        }
//        
//        let text = buildItemsLabelString() // TODO incr/decr quantity in QuickAddListItemViewController. Hold numbers there (also show in light blue in tableview) (and pass current quantity to delegate?)
//        
//        // Highlight updated quantity
//        // Note on noBreakSpaceStr: Since the products names in text have no break space we also have to look for product name with no break space
//        if let productNameRange = text.range(incrementedItem.product.name.noBreakSpaceStr(), caseInsensitive: true) {
//
//            if productNameRange.location != NSNotFound {
//                let rangeAfterProductName = NSRange(location: productNameRange.end, length: text.characters.count - productNameRange.end)
//                
//                do {
//                    // look for the quantity of product - first number in rangeAfterProductName
//                    let regex = try NSRegularExpression(pattern: "\\d+", options: [])
//                    let quantityRange = regex.rangeOfFirstMatchInString(text, options: [], range: rangeAfterProductName)
//                    
//                    if quantityRange.location != NSNotFound {
//                        let attributedText = text.makeAttributed(quantityRange, normalFont: Fonts.verySmallLight, font: Fonts.verySmallBold)
//                        itemsLabel.attributedText = attributedText
//                    } else {
//                        itemsLabel.text = text
//                    }
//
//                } catch _ {
//                    print("Error with regex")
//                    
//                    
//                }
//            } else {  // product was not found in text - this happens when it's removed (q
//                itemsLabel.text = text
//            }
//        }
    }
    
    private func buildItemsLabelString() -> String {
        // use no break space in product names and between product and quantity, this way line break comes only with space before comma
        return itemsDictionary.mapValues{
            let productNameNoBreakSpaces = $0.product.name.noBreakSpaceStr()
            return "\(productNameNoBreakSpaces)\u{00A0}\($0.quantity)x"}.joinWithSeparator(", ")
    }
    
    func onCloseQuickAddTap() {
        // not used
    }
    
    func onGroupItemMinusTap(product: Product) {
        incrementProduct(product, quantity: -1)
    }

    func onGroupItemPlusTap(product: Product) {
        incrementProduct(product, quantity: 1)
    }
}
