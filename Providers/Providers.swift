//
//  Prov.swift
//  shoppin
//
//  Created by ischuetz on 10/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public struct Prov {
    
    public static var itemsProvider: ItemProvider = ItemProviderImpl()
    
    public static var listItemsProvider: ListItemProvider = ListItemProviderImpl()
    
    public static var productProvider: ProductProvider = ProductProviderImpl()

    public static var productCategoryProvider: ProductCategoryProvider = ProductCategoryProviderImpl()

    public static var sectionProvider: SectionProvider = SectionProviderImpl()
    
    public static var inventoryProvider: InventoryProvider = InventoryProviderImpl()
    public static var inventoryItemsProvider: InventoryItemsProvider = InventoryItemsProviderImpl()
    
    public static var userProvider: UserProvider = RealmUserProviderImpl() // Realm object server
//    public static var userProvider: UserProvider = UserProviderImpl() // Own server
//    public static var userProvider: UserProvider = UserProviderMock()
    
    public static var listProvider: ListProvider = ListProviderImpl()
    
    public static var historyProvider: HistoryProvider = HistoryProviderImpl()
    
    public static var statsProvider: StatsProvider = StatsProviderImpl()
    
    public static var planProvider: PlanProvider = PlanProviderImpl()
    
    public static var listItemGroupsProvider: ProductGroupProvider = ProductGroupProviderImpl()

    public static var recipeProvider: RecipeProvider = RecipeProviderImpl()
    public static var ingredientProvider: IngredientProvider = IngredientProviderImpl()
    public static var addableIngredientProvider: AddableIngredientProvider = AddableIngredientProviderImpl()
    
    public static var helpProvider: HelpProvider = HelpProviderImpl()
    
    public static var brandProvider: BrandProvider = BrandProviderImpl()
    
    public static var globalProvider: GlobalProvider = GlobalProviderImpl()
    
    public static var errorProvider: ErrorProvider = ErrorProviderImpl()
    
    public static var pullProvider: PullProvider = PullProviderImpl()
}
