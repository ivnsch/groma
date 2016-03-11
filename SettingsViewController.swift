//
//  SettingsViewController.swift
//  shoppin
//
//  Created by ischuetz on 04/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func onClearAllDataTap(sender: UIButton) {
        Providers.globalProvider.clearAllData(successHandler{
            AlertPopup.show(message: "The data was cleared", controller: self)
        })
    }
    
    @IBAction func onClearHistoryTap(sender: UIButton) {
        Providers.historyProvider.removeAllHistoryItems(successHandler{
            AlertPopup.show(message: "The history was cleared", controller: self)
        })
    }
    
    // MARK: - Debug settings
    
    @IBAction func onAddDummyHistoryTap(sender: UIButton) {

        let user = SharedUser(email: "dummy@user.test")
        
        Providers.inventoryProvider.inventories(true, successHandler{[weak self] inventories in
            
            if let weakSelf = self {
                
                if let inventory = inventories.first {
                    
                    Providers.productProvider.products(NSRange(location: 0, length: 500), sortBy: .Alphabetic, weakSelf.successHandler{products in

                        guard products.count > 0 else {
                            AlertPopup.show(message: "You need some products to be able to add history items", controller: weakSelf)
                            return
                        }
                        
                        // In order to fill the stats - add a random number if history items between 2 and 50 for each month to each of the past 12 months (excluding current, it's maybe better for testers to have current month empty so they can see more clearly the effect of items they are adding)
                        let historyItems: [[HistoryItem]] = (-1).stride(to: -12, by: -1).map {monthOffset in
                          
                            let date: NSDate = NSDate.inMonths(monthOffset)
                            
                            let monthHistoryItems: [HistoryItem] = (2..<Int.random(2, max: 50)).map {_ in
                                let randomIndex = Int.random(products.count)
                                let product = products[randomIndex]
                                return HistoryItem(uuid: NSUUID().UUIDString, inventory: inventory, product: product, addedDate: date, quantity: Int.random(10), user: user, paidPrice: product.price)
                            }
                            return monthHistoryItems
                        }
                        
                        // put the history items for past months in a flat array and save
                        let flattened: [HistoryItem] = Array(historyItems.flatten())
                        Providers.historyProvider.addHistoryItems(flattened, weakSelf.successHandler{
                            AlertPopup.show(message: "Dummy history items added to inventory: \(inventory.name)", controller: weakSelf)
                        })
                    })
                    
                } else {
                    AlertPopup.show(message: "You need to have at least 1 inventory to add history items", controller: weakSelf)
                }
                
            } else {
                print("Warn: SettingsViewController.onAddDummyHistoryTap: weakSelf is not set")
            }
        })
    }
}