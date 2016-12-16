//
//  ProviderFactory.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

// TODO make variables static (static is lazy)
public class ProviderFactory {

    public init() {}
    
    public lazy var listItemProvider: ListItemProvider = ListItemProviderImpl()

    public lazy var inventoryProvider: InventoryProvider = InventoryProviderImpl()
    public lazy var inventoryItemsProvider: InventoryItemsProvider = InventoryItemsProviderImpl()
    
    public lazy var userProvider: UserProvider = UserProviderImpl()
    
    public lazy var listProvider: ListProvider = ListProviderImpl()
    
    public lazy var historyProvider: HistoryProvider = HistoryProviderImpl()
    
    public lazy var statsProvider: StatsProvider = StatsProviderImpl()
}
