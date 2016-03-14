//
//  DBProviders.swift
//  shoppin
//
//  Created by ischuetz on 14/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class DBProviders {

    static var listItemProvider = RealmListItemProvider()

    static var productProvider = RealmProductProvider()

    static var productCategoryProvider = RealmProductCategoryProvider()
    
    static var sectionProvider = RealmSectionProvider()
    
    static var inventoryProvider = RealmInventoryProvider()
    static var inventoryItemProvider = RealmInventoryItemProvider()
    
    static var listProvider = RealmListProvider()
    
    static var historyProvider = RealmHistoryProvider()
    
    static var listItemGroupProvider = RealmListItemGroupProvider()
    static var groupItemProvider = RealmGroupItemProvider()

    static var globalProvider = RealmGlobalProvider()
}
