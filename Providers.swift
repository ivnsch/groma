//
//  Providers.swift
//  shoppin
//
//  Created by ischuetz on 10/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct Providers {
    
    static var listItemsProvider: ListItemProvider = ListItemProviderImpl()
    
    static var inventoryProvider: InventoryProvider = InventoryProviderImpl()
    static var inventoryItemsProvider: InventoryItemsProvider = InventoryItemsProviderImpl()
    
    static var userProvider: UserProvider = UserProviderImpl()
    
    static var listProvider: ListProvider = ListProviderImpl()
    
    static var historyProvider: HistoryProvider = HistoryProviderImpl()
    
    static var statsProvider: StatsProvider = StatsProviderImpl()
}
