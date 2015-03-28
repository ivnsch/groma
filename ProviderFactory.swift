//
//  ProviderFactory.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

class ProviderFactory {
   
    lazy var listItemProvider:ListItemProvider = ListItemProviderMock()

    lazy var inventoryProvider:InventoryProvider = InventoryProviderImpl()
}