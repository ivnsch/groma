//
//  DBProv.swift
//  shoppin
//
//  Created by ischuetz on 14/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class DBProv {

    static var itemProvider = RealmItemProvider()
    
    static var listItemProvider = RealmListItemProvider()

    static var productProvider = RealmProductProvider()
    static var storeProductProvider = RealmStoreProductProvider()
    static var brandProvider = RealmBrandProvider()
    
    static var productCategoryProvider = RealmProductCategoryProvider()
    
    static var sectionProvider = RealmSectionProvider()
    
    static var inventoryProvider = RealmInventoryProvider()
    static var inventoryItemProvider = RealmInventoryItemProvider()
    
    static var listProvider = RealmListProvider()
    
    static var historyProvider = RealmHistoryProvider()
    
    static var listItemGroupProvider = RealmProductGroupProvider()
    static var groupItemProvider = RealmGroupItemProvider()

    static var recipeProvider = RealmRecipeProvider()
    static var ingredientProvider = RealmIngredientProvider()
    
    static var unitProvider = RealmUnitProvider()
    
    static var fractionProvider = RealmFractionProvider()
    
    static var globalProvider = RealmGlobalProvider()
}
