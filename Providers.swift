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
    
    static var productProvider: ProductProvider = ProductProviderImpl()

    static var productCategoryProvider: ProductCategoryProvider = ProductCategoryProviderImpl()

    static var sectionProvider: SectionProvider = SectionProviderImpl()
    
    static var inventoryProvider: InventoryProvider = InventoryProviderImpl()
    static var inventoryItemsProvider: InventoryItemsProvider = InventoryItemsProviderImpl()
    
    static var userProvider: UserProvider = UserProviderImpl()
//    static var userProvider: UserProvider = UserProviderMock()
    
    static var listProvider: ListProvider = ListProviderImpl()
    
    static var historyProvider: HistoryProvider = HistoryProviderImpl()
    
    static var statsProvider: StatsProvider = StatsProviderImpl()
    
    static var planProvider: PlanProvider = PlanProviderImpl()
    
    static var listItemGroupsProvider: ListItemGroupProvider = ListItemGroupProviderImpl()

    static var helpProvider: HelpProvider = HelpProviderImpl()
    
    static var brandProvider: BrandProvider = BrandProviderImpl()
    
    static var globalProvider: GlobalProvider = GlobalProviderImpl()
    
    static var errorProvider: ErrorProvider = ErrorProviderImpl()
}
