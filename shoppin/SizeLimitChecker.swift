//
//  SizeLimitChecker.swift
//  shoppin
//
//  Created by ischuetz on 13/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class SizeLimitChecker {

    
    static func checkGroupsSizeLimit(itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.groups
        check(itemsCount, limit: limit, line1: "You can't have more than \(limit) groups", controller: controller, onSuccess: onSuccess)
    }
    
    static func checkGroupItemsSizeLimit(itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.groupItems
        check(itemsCount, limit: limit, line1: "You can't have more than \(limit) group items", controller: controller, onSuccess: onSuccess)
    }
    
    static func checkInventoriesSizeLimit(itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.inventories
        check(itemsCount, limit: limit, line1: "You can't have more than \(limit) inventories", controller: controller, onSuccess: onSuccess)
    }
    
    static func checkInventoryItemsSizeLimit(itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.inventoryItems
        check(itemsCount, limit: limit, line1: "You can't have more than \(limit) inventory items", controller: controller, onSuccess: onSuccess)
    }
    
    static func checkHistoryItemsSizeLimit(itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.historyItems
        check(itemsCount, limit: limit, line1: "You can't have more than \(limit) history entries", controller: controller, onSuccess: onSuccess)
    }
    
    static func checkListItemsSizeLimit(itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.listItems
        check(itemsCount, limit: limit, line1: "You can't have more than \(limit) list items", controller: controller, onSuccess: onSuccess)
    }
    
    static func checkListsSizeLimit(itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.lists
        check(itemsCount, limit: limit, line1: "You can't have more than \(limit) lists", controller: controller, onSuccess: onSuccess)
    }
    
    static func checkProductsSizeLimit(itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.products
        check(itemsCount, limit: limit, line1: "You can't have more than \(limit) products", controller: controller, onSuccess: onSuccess)
    }
    
    private static func check(itemsCount: Int, limit: Int, line1: String, controller: UIViewController, onSuccess: VoidFunction) {
        let afterLine1 = "\nMaybe you can remove a not used one?\nIf you *really* need more feel free to contact us via feedback email.\nHappy to adjust this if there are enough complaints or for a special case."
        check(itemsCount, limit: limit, line1: line1, afterLine1: afterLine1, controller: controller, onSuccess: onSuccess)
    }
    
    private static func check(itemsCount: Int, limit: Int, line1: String, afterLine1: String, controller: UIViewController, onSuccess: VoidFunction) {
        if itemsCount > limit {
            AlertPopup.show(title: "Size limit!", message: "\(line1)\(afterLine1)" , controller: controller)
        } else {
            onSuccess()
        }
    }
}