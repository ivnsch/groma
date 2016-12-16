//
//  SizeLimitChecker.swift
//  shoppin
//
//  Created by ischuetz on 13/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import Providers

class SizeLimitChecker {

    
    static func checkGroupsSizeLimit(_ itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.groups
        check(itemsCount, limit: limit, line1: trans("popups_size_limit_groups", "\(limit)"), controller: controller, onSuccess: onSuccess)
    }
    
    static func checkGroupItemsSizeLimit(_ itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.groupItems
        check(itemsCount, limit: limit, line1: trans("popups_size_limit_group_items", "\(limit)"), controller: controller, onSuccess: onSuccess)
    }
    
    static func checkInventoriesSizeLimit(_ itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.inventories
        check(itemsCount, limit: limit, line1: trans("popups_size_limit_inventories", "\(limit)"), controller: controller, onSuccess: onSuccess)
    }
    
    static func checkInventoryItemsSizeLimit(_ itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.inventoryItems
        check(itemsCount, limit: limit, line1: trans("popups_size_limit_inventory_items", "\(limit)"), controller: controller, onSuccess: onSuccess)
    }
    
    static func checkHistoryItemsSizeLimit(_ itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.historyItems
        check(itemsCount, limit: limit, line1: trans("popups_size_limit_history_items", "\(limit)"), controller: controller, onSuccess: onSuccess)
    }
    
    static func checkListItemsSizeLimit(_ itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.listItems
        check(itemsCount, limit: limit, line1: trans("popups_size_limit_list_items", "\(limit)"), controller: controller, onSuccess: onSuccess)
    }
    
    static func checkListsSizeLimit(_ itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.lists
        check(itemsCount, limit: limit, line1: trans("popups_size_limit_lists", "\(limit)"), controller: controller, onSuccess: onSuccess)
    }
    
    static func checkProductsSizeLimit(_ itemsCount: Int, controller: UIViewController, onSuccess: VoidFunction) {
        let limit = SizeLimits.products
        check(itemsCount, limit: limit, line1: trans("popups_size_limit_products", "\(limit)"), controller: controller, onSuccess: onSuccess)
    }
    
    fileprivate static func check(_ itemsCount: Int, limit: Int, line1: String, controller: UIViewController, onSuccess: VoidFunction) {
        let afterLine1 = trans("popups_size_limit_line2")
        check(itemsCount, limit: limit, line1: line1, afterLine1: afterLine1, controller: controller, onSuccess: onSuccess)
    }
    
    fileprivate static func check(_ itemsCount: Int, limit: Int, line1: String, afterLine1: String, controller: UIViewController, onSuccess: VoidFunction) {
        if itemsCount > limit {
            AlertPopup.show(title: trans("popup_title_size_limit"), message: "\(line1)\(afterLine1)" , controller: controller)
        } else {
            onSuccess()
        }
    }
}
