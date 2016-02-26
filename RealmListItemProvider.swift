//
//  RealmListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

enum QuickAddItemSortBy {
    case Alphabetic, Fav
}

class RealmListItemProvider: RealmProvider {
    
    // MARK: - Section
    
    func loadSectionWithUuid(uuid: String, handler: Section? -> ()) {
        let mapper = {SectionMapper.sectionWithDB($0)}
        self.loadFirst(mapper, filter: "uuid = '\(uuid)'", handler: handler)
    }
    
    func loadSection(name: String, list: List, handler: Section? -> ()) {
        loadSections([name], list: list) {sections in
            handler(sections.first)
        }
    }
    
    func loadSections(names: [String], list: List, handler: [Section] -> ()) {
        let mapper = {SectionMapper.sectionWithDB($0)}
        let sectionsNamesStr: String = names.map{"'\($0)'"}.joinWithSeparator(",")
        self.load(mapper, filter: "name IN {\(sectionsNamesStr)} && list.uuid = '\(list.uuid)'", handler: handler)
    }
    
    func saveSection(section: Section, handler: Bool -> ()) {
        let dbSection = DBSection()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        
        self.saveObj(dbSection, handler: handler)
    }
    
    func saveSections(sections: [Section], handler: Bool -> ()) {
        let dbSections = sections.map{SectionMapper.dbWithSection($0)}
        self.saveObjs(dbSections, update: true, handler: handler)
    }
    
    func remove(section: Section, handler: Bool -> ()) {
        self.remove("uuid = '\(section.uuid)'", handler: handler, objType: DBSection.self)
    }

    func update(sections: [Section], handler: Bool -> ()) {
        let dbSections = sections.map{SectionMapper.dbWithSection($0)}
        self.saveObjs(dbSections, update: true, handler: handler)
    }
    
    // MARK: - Product
    
    func loadProductWithUuid(uuid: String, handler: Product? -> ()) {
        let mapper = {ProductMapper.productWithDB($0)}
        self.loadFirst(mapper, filter: "uuid = '\(uuid)'", handler: handler)
    }
    
    // TODO rename method (uses now brand too)
    func loadProductWithName(name: String, brand: String, handler: Product? -> ()) {
        let mapper = {ProductMapper.productWithDB($0)}
        self.loadFirst(mapper, filter: "name = '\(name)' && brand = '\(brand)'", handler: handler)
    }
    
    func loadProducts(range: NSRange, sortBy: ProductSortBy, handler: [Product] -> ()) {
        products(range: range, sortBy: sortBy) {tuple in
            handler(tuple.products)
        }
    }

    func products(substring: String? = nil, range: NSRange? = nil, sortBy: ProductSortBy, handler: (substring: String?, products: [Product]) -> ()) {
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .Alphabetic: return ("name", true)
            case .Fav: return ("fav", false)
            }
        }()
        let filterMaybe = substring.map{"name CONTAINS[c] '\($0)'"}
        let mapper = {ProductMapper.productWithDB($0)}
        self.load(mapper, filter: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending), range: range) {products in
            handler(substring: substring, products: products)
        }
    }
    
    func countProducts(handler: Int? -> Void) {
        withRealm({realm in
            realm.objects(DBProduct).count
            }) { (countMaybe: Int?) -> Void in
                if let count = countMaybe {
                    handler(count)
                } else {
                    QL4("No count")
                    handler(nil)
                }
        }
    }

    func deleteProductAndDependencies(product: Product, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            if let weakSelf = self {
                return weakSelf.deleteProductAndDependenciesSync(realm, productUuid: product.uuid)
            } else {
                print("WARN: RealmListItemProvider.deleteProductAndDependencies: self is nil")
                return false
            }
        }, finishHandler: {success in
            handler(success ?? false)
        })
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductAndDependenciesSync(realm: Realm, productUuid: String) -> Bool {
        if deleteProductAndDependenciesSync(realm, productUuid: productUuid) {
            let productResult = realm.objects(DBProduct).filter("uuid = '\(productUuid)'")
            realm.delete(productResult)
            return true
        } else {
            return false
        }
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductDependenciesSync(realm: Realm, productUuid: String) -> Bool {
        let listItemResult = realm.objects(DBListItem).filter("product.uuid = '\(productUuid)'")
        realm.delete(listItemResult)
        let inventoryResult = realm.objects(DBInventoryItem).filter("product.uuid = '\(productUuid)'")
        realm.delete(inventoryResult)
        let historyResult = realm.objects(DBHistoryItem).filter("product.uuid = '\(productUuid)'")
        realm.delete(historyResult)
        let planResult = realm.objects(DBPlanItem).filter("product.uuid = '\(productUuid)'")
        realm.delete(planResult)
        return true
    }
    
    
    func saveProduct(productInput: ProductInput, updateSuggestions: Bool = true, update: Bool = true, handler: Product? -> ()) {
        
        loadProductWithName(productInput.name, brand: productInput.brand ?? "") {[weak self] productMaybe in

            if productMaybe.isSet && !update {
                print("Product with name: \(productInput.name), already exists, no update")
                handler(nil)
                return
            }
            
            let uuid: String = {
                if let existingProduct = productMaybe { // since realm doesn't support unique besides primary key yet, we have to fetch first possibly existing product
                    return existingProduct.uuid
                } else {
                    return NSUUID().UUIDString
                }
            }()
            
            Providers.productCategoryProvider.categoryWithName(productInput.category) {result in
                
                if result.status == .Success || result.status == .NotFound  {
                    
                    // Create a new category or update existing one
                    let category: ProductCategory? = {
                        if let existingCategory = result.sucessResult {
                            return existingCategory.copy(name: productInput.category, color: productInput.categoryColor)
                        } else if result.status == .NotFound {
                            return ProductCategory(uuid: NSUUID().UUIDString, name: productInput.category, color: productInput.categoryColor)
                        } else {
                            print("Error: RealmListItemProvider.saveProductError, invalid state: status is .Success but there is not successResult")
                            return nil
                        }
                    }()
                    
                    // Save product with new/updated category
                    if let category = category {
                        let product = Product(uuid: uuid, name: productInput.name, price: productInput.price, category: category, baseQuantity: productInput.baseQuantity, unit: productInput.unit, brand: productInput.brand)
                        self?.saveProducts([product]) {saved in
                            if saved {
                                handler(product)
                            } else {
                                print("Error: RealmListItemProvider.saveProductError, could not save product: \(product)")
                                handler(nil)
                            }
                        }
                    } else {
                        print("Error: RealmListItemProvider.saveProduct, category is nill")
                        handler(nil)
                    }

                } else {
                    print("Error: RealmListItemProvider.saveProduct, couldn't fetch category: \(result)")
                    handler(nil)
                }
            }
        }
    }

    func saveProducts(products: [Product], updateSuggestions: Bool = true, update: Bool = true, handler: Bool -> ()) {
        
        for product in products { // product marked as var to be able to update uuid
            
            doInWriteTransaction({[weak self] realm in
                let dbProduct = ProductMapper.dbWithProduct(product)
                realm.add(dbProduct, update: update)
                if updateSuggestions {
                    self?.saveProductSuggestionHelper(realm, product: product)
                }
                return true
                
                }, finishHandler: {success in
                    handler(success ?? false)
            })
        }
    }
    
    func categoriesContaining(text: String, handler: [String] -> Void) {
        let mapper: DBProduct -> String = {$0.category.name}
        self.load(mapper, filter: "category CONTAINS[c] '\(text)'") {categories in
            let distinctCategories = NSOrderedSet(array: categories).array as! [String] // TODO re-check: Realm can't distinct yet https://github.com/realm/realm-cocoa/issues/1103
            handler(distinctCategories)
        }
    }
    
    // MARK: - Suggestion

    func loadProductSuggestions(handler: [Suggestion] -> ()) {
        let mapper = {ProductSuggestionMapper.suggestionWithDB($0)}
        self.load(mapper, handler: handler)
    }

    // Gets suggestions both from section and category names
    func sectionSuggestionsContainingText(text: String, handler: [String] -> Void) {
        withRealm({ realm in
            let sectionNames: [String] = realm.objects(DBSection).filter("name CONTAINS[c] '\(text)'").map{$0.name}
            let categoryNames: [String] = realm.objects(DBProductCategory).filter("name CONTAINS[c] '\(text)'").map{$0.name}
            let allNames: [String] = (sectionNames + categoryNames).distinct()
            return allNames
            
            }) { (allNamesMaybe: [String]?) -> Void in
                if let allNames = allNamesMaybe {
                    handler(allNames)
                } else {
                    print("Error: RealmListItemProvider.loadSectionSuggestions: Couldn't load section suggestions")
                    handler([])
                }
        }
    }
    
    // MARK: - List
    
    func saveList(list: List, handler: Bool -> ()) {
        let dbList = ListMapper.dbWithList(list)
        self.saveObj(dbList, update: true, handler: handler)
    }
    
    func saveLists(lists: [List], update: Bool = false, handler: Bool -> ()) {
        let dbLists = lists.map{ListMapper.dbWithList($0)}
        saveLists(dbLists, update: update, handler: handler)
    }
    
    func saveLists(lists: [DBList], update: Bool = false, handler: Bool -> ()) {
        self.saveObjs(lists, update: update, handler: handler)
    }
    
    func overwriteLists(lists: [List], handler: Bool -> ()) {
        let dbLists = lists.map{ListMapper.dbWithList($0)}
        self.overwrite(dbLists, resetLastUpdateToServer: true, handler: handler)
    }
    
    func loadList(uuid: String, handler: List? -> ()) {
        let mapper = {ListMapper.listWithDB($0)}
        self.loadFirst(mapper, filter: "uuid = '\(uuid)'", handler: handler)
    }
    
    func loadLists(handler: [List] -> ()) {
        let mapper = {ListMapper.listWithDB($0)}
        self.load(mapper, handler: handler)
    }
    
    func remove(list: List, handler: Bool -> ()) {
        remove(list.uuid, handler: handler)
    }

    func remove(listUuid: String, handler: Bool -> Void) {
        background({[weak self] in
            do {
                let realm = try Realm()
                var success = false
                realm.write {
                    success = self?.removeListSync(realm, listUuid: listUuid) ?? false
                }
                return success
            } catch _ {
                QL4("Error creating Realm() in remove")
                return false
            }
            }) {(result: Bool) in
                handler(result)
        }
    }

    // Expected to be executed in do/catch and write block
    func removeListSync(realm: Realm, listUuid: String) -> Bool {
        let dbListItems = realm.objects(DBListItem).filter("list.uuid = '\(listUuid)'")
        // delete listItems
        realm.delete(dbListItems)
        // delete list
        let listResults = realm.objects(DBList).filter("uuid = '\(listUuid)'")
        realm.delete(listResults)
        return true
    }

    // TODO update list
    
    // MARK: - ListItem
    
    func saveListItem(listItem: ListItem, updateSuggestions: Bool = true, incrementQuantity: Bool, handler: ListItem -> ()) {
        saveListItems([listItem], incrementQuantity: incrementQuantity) {listItemsMaybe in
            if let listItems = listItemsMaybe {
                if let listItem = listItems.first {
                    handler(listItem)
                } else {
                    // FIXME for now not calling the handler if error happen, but to be correct the handler should get optional list item.
                    print("Error: RealmListItemProvider: saveListItem: returned empty array after (maybe) saving: \(listItem)")
                }
            } else {
                // FIXME for now not calling the handler if error happen, but to be correct the handler should get optional list item.
                print("Error: RealmListItemProvider: saveListItem: returned nil array after (maybe) saving: \(listItem)")
            }
        }
    }
    
    /**
    Batch add/update of list items
    When used for add: incrementQuantity should be true, update: false. After clearing db (e.g. sync) also false (since there's nothing to increment)
    NOTE: Assumes all listItems belong to the same list (only the list of first list item is used for filtering)
    */
    func saveListItems(var listItems: [ListItem], updateSuggestions: Bool = true, incrementQuantity: Bool, updateSection: Bool = true, handler: [ListItem]? -> ()) {
        doInWriteTransaction({[weak self] realm in
           
            // if we want to increment if item with same product name exists
            // Note that we always want this except when saveListItems is called after having cleared the database, e.g. (currently) on server sync, or when doing an update
            if incrementQuantity {
                // get all existing list items with product names using IN query
                let productNamesStr: String = listItems.map{"'\($0.product.name)'"}.joinWithSeparator(",")
                let listUuid = listItems.first?.list.uuid ?? ""
                let existingListItems = realm.objects(DBListItem).filter("product.name IN {\(productNamesStr)} AND list.uuid = '\(listUuid)'")
                
                let uuidToDBListItemDict: [String: DBListItem] = existingListItems.toDictionary{
                    ($0.product.uuid, $0)
                }
                // merge list items with existing, in order to do update (increment quantity)
                // this means: use uuid of existing item, increment quantity, and for the rest copy fields of new item
                listItems = listItems.map {listItem in
                    if let existingDBListItem = uuidToDBListItemDict[listItem.product.uuid] {
                        return listItem.increment(existingDBListItem.todoQuantity, doneQuantity: existingDBListItem.doneQuantity, stashQuantity: existingDBListItem.stashQuantity)
                    } else {
                        return listItem
                    }
                }
            }
            
            for listItem in listItems {

                // TODO possible to use batch save here?
                let dbListItem = ListItemMapper.dbWithListItem(listItem)
                realm.add(dbListItem, update: true)
                
                if updateSuggestions {
                    self?.saveProductSuggestionHelper(realm, product: listItem.product) // TODO still needed?
                    
                    let sectionSuggestion = SectionSuggestionMapper.dbWithSection(listItem.section)
                    realm.add(sectionSuggestion, update: true)
                }
                
            }
            return listItems
            
            }, finishHandler: {listItemsMaybe in
                handler(listItemsMaybe)
        })
    }
    
    
    func addListItem(status: ListItemStatus, product: Product, sectionNameMaybe: String?, quantity: Int, list: List, note noteMaybe: String? = nil, _ handler: ListItem? -> Void) {
        
        doInWriteTransaction({realm in
            return syncedRet(self) {
                
                // see if there's already a listitem for this product in the list - if yes only increment it
                if let existingListItem = realm.objects(DBListItem).filter("product.name == '\(product.name)'").first {
                    existingListItem.increment(ListItemStatusQuantity(status: status, quantity: quantity))
                    
                    // possible updates (when user submits a new list item using add edit product controller)
                    if let sectionName = sectionNameMaybe {
                        existingListItem.section.name = sectionName
                    }
                    if let note = noteMaybe {
                        existingListItem.note = note
                    }
                    
                    // TODO!! update sectionnaeme, note (for case where this is from add product with inputs)
                    realm.add(existingListItem, update: true)
                    return ListItemMapper.listItemWithDB(existingListItem)
                    
                } else { // no list item for product in the list, create a new one
                    
                    // see if there's already a section for the new list item in the list, if not create a new one
                    let listItemsInList = realm.objects(DBListItem).filter("list.uuid == '\(list.uuid)'")
                    let sectionName = sectionNameMaybe ?? product.category.name
                    let section = listItemsInList.findFirst{$0.section.name == sectionName}.map {item in  // it's is a bit more practical to use plain models and map than adding initialisers to db objs
                        return SectionMapper.sectionWithDB(item.section)
                        } ?? {
                            let sectionCount = Set(listItemsInList.map{$0.section}).count
                            return Section(uuid: NSUUID().UUIDString, name: sectionName, list: list, order: ListItemStatusOrder(status: status, order: sectionCount))
                        }()
                    
                    
                    // calculate list item order, which is at the end of it's section (==count of listitems in section). Note that currently we are doing this iteration even if we just created the section, where order is always 0. This if for clarity - can be optimised later (TODO)
                    var listItemOrder = 0
                    for existingListItem in listItemsInList {
                        if existingListItem.section.uuid == section.uuid {
                            listItemOrder++
                        }
                    }
                    
                    // create the list item and save it
                    let listItem = ListItem(uuid: NSUUID().UUIDString, product: product, section: section, list: list, statusOrder: ListItemStatusOrder(status: status, order: listItemOrder), statusQuantity: ListItemStatusQuantity(status: status, quantity: quantity))
                    
                    let dbListItem = ListItemMapper.dbWithListItem(listItem)
                    realm.add(dbListItem, update: true) // this should be update false, but update true is a little more "safer" (e.g uuid clash?), TODO review, maybe false better performance
                    return ListItemMapper.listItemWithDB(dbListItem)
                }
            }
        }, finishHandler: {(savedListItemMaybe: ListItem?) in
                handler(savedListItemMaybe)
        })
    }

    
//    /**
//    Helper to save a list item with optional saving of product and section autosuggestion
//    Expected to be executed inside a transaction
//    */
//    private func saveListItemHelper(realm: Realm, listItem: ListItem, updateSuggestions: Bool = true) {
//        let dbListItem = ListItemMapper.dbWithListItem(listItem)
//        realm.add(dbListItem, update: true)
//        
//        if updateSuggestions {
//            saveProductSuggestionHelper(realm, product: listItem.product)
//            
//            let sectionSuggestion = SectionSuggestionMapper.dbWithSection(listItem.section)
//            realm.add(sectionSuggestion, update: true)
//        }
//    }

    /**
    Helper to save suggestion corresponding to a product
    Expected to be executed in a write block
    */
    private func saveProductSuggestionHelper(realm: Realm, product: Product) {
        // TODO update suggestions - right now only insert - product is updated based on uuid, but with autosuggestion, since no ids old names keep there
        // so we need to either do a query for the product/old name, and delete the autosuggestion with this name or use ids
        let suggestion = ProductSuggestionMapper.dbWithProduct(product)
        realm.add(suggestion, update: true)
    }
    
    func loadListItems(list: List, handler: [ListItem] -> ()) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.load(mapper, filter: "list.uuid = '\(list.uuid)'", handler: handler)
    }
    
    // hm...
    func loadAllListItems(handler: [ListItem] -> ()) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.load(mapper, handler: handler)
    }
    
    func remove(listItem: ListItem, handler: Bool -> ()) {
        self.remove("uuid = '\(listItem.uuid)'", handler: handler, objType: DBListItem.self)
    }
    
    // TODO remove this method? Or if it's still needed, pass only list items, all the dependencies are in list items already
    // TODO do we really need ListItemsWithRelations here, maybe convenience holder made sense only for coredata?
    func saveListItems(listItemsWithRelations: ListItemsWithRelations, handler: Bool -> ()) {
        
        //        let dbProducts = listItemsWithRelations.products.map{self.toDBProduct($0)}
        //        let dbSections = listItemsWithRelations.sections.map{self.toDBSection($0)}
        //        let dbLists = listItemsWithRelations.lists.map{self.toDBList($0)}
        //
        //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        //            let realm = Realm()
        //            realm.write {
        //
        //                for dbProduct in dbProducts {
        //                    realm.add(dbProduct)
        //                }
        //            }
        //            dispatch_async(dispatch_get_main_queue(), {
        //                handler(true)
        //            })
        //        })
        
        let dbListItems = listItemsWithRelations.listItems.map{ListItemMapper.dbWithListItem($0)}
        self.saveObjs(dbListItems, update: true) {listItemsMaybe in
            handler(true)
        }
    }
    
    func updateListItems(listItems: [ListItem], handler: Bool -> ()) {
        saveListItems(listItems, incrementQuantity: false, updateSection: false) {updatedListItemsMaybe in
            if let updatedListItems = updatedListItemsMaybe {
                if listItems.count == updatedListItems.count {
                    handler(true)
                } else {
                    print("Error: RealmListItemProvider: updateListItems: list items count != updated items count. list items: \(listItems), updated: \(updatedListItemsMaybe)")
                    handler(false)
                }
            } else {
                print("Error: RealmListItemProvider: saveListItem: returned nil array after (maybe) saving: \(updatedListItemsMaybe)")
                handler(false)
            }
        }
    }
    
    func overwrite(listItems: [ListItem], listUuid: String, handler: Bool -> ()) {
        let dbListItems = listItems.map{ListItemMapper.dbWithListItem($0)}
        self.overwrite(dbListItems, deleteFilter: "list.uuid = '\(listUuid)'", resetLastUpdateToServer: true, handler: handler)
    }
    
    /**
    Gets list items count with a certain status in a certain list
    */
    func listItemCount(status: ListItemStatus, list: List, handler: Int? -> Void) {
        let finished: Int? -> Void = {result in
            dispatch_async(dispatch_get_main_queue(), {
                handler(result)
            })
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            do {
                let realm = try Realm()
                let listItems = realm.objects(DBListItem).filter("list.uuid = '\(list.uuid)'")
                let count = listItems.filter{$0.hasStatus(status)}.count
                finished(count)
            } catch _ {
                print("Error: creating Realm() in load, returning empty results")
                finished(nil) // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        })
    }
    
    // TODO Asynchronous. dispatch_async + lock inside for some reason didn't work correctly (tap 10 times on increment, only shows 4 or so (after refresh view controller it's correct though), maybe use serial queue?
    func incrementTodoListItem(item: ListItem, delta: Int, handler: Bool -> ()) {
        
        //        synced(self)  {
        
        // load
        let realm = try! Realm()
        let results = realm.objects(DBListItem).filter("uuid == '\(item.uuid)'")
//        results = results.filter(NSPredicate(format: DBInventoryItem.createFilter(item.product, item.inventory), argumentArray: []))
        let objs: [DBListItem] = results.toArray(nil)
        let dbInventoryItems = objs.map{ListItemMapper.listItemWithDB($0)}
        let listItemMaybe = dbInventoryItems.first
        
        if let listItem = listItemMaybe {
            // increment
            let incrementedListitem = listItem.copy(note: nil, todoQuantity: listItem.todoQuantity + delta)
            
            // convert to db object
            let dbIncrementedInventoryitem = ListItemMapper.dbWithListItem(incrementedListitem)
            
            // save
            realm.write {
                for obj in objs {
                    obj.lastUpdate = NSDate()
                    realm.add(dbIncrementedInventoryitem, update: true)
                }
            }
            
            handler(true)
            
            
        } else {
            print("Info: RealmListItemProvider.incrementTodoListItem: List item not found: \(item)")
            handler(false)
        }
        //        }
    }
    
    // MARK: - Sync
    
    func saveListsSyncResult(syncResult: RemoteListWithListItemsSyncResult, handler: Bool -> ()) {
        
        doInWriteTransaction({realm in
            
            let inventories = realm.objects(DBList)
            let inventoryItems = realm.objects(DBListItem)
            let sections = realm.objects(DBSection)
            
            realm.delete(inventories)
            realm.delete(inventoryItems)
            realm.delete(sections)
            // we don't delete the products because these are referenced also by inventory items and maybe also other things in the future
            
            // save inventories
            let lists = ListMapper.listsWithRemote(syncResult.lists)
            let remoteInventories = lists
            for remoteInventory in remoteInventories {
                let dbInventory = ListMapper.dbWithList(remoteInventory)
                realm.add(dbInventory, update: true)
            }
            
            // save inventory items
            for listItemsSyncResult in syncResult.listItemsSyncResults {
                
                let listItemsWithRelations = ListItemMapper.listItemsWithRemote(listItemsSyncResult.listItems, sortOrderByStatus: nil)
                
                for product in listItemsWithRelations.products {
                    let dbProduct = ProductMapper.dbWithProduct(product)
                    realm.add(dbProduct, update: true) // since we don't delete products (see comment above) we do update
                }
                
                for section in listItemsWithRelations.sections {
                    let dbSection = SectionMapper.dbWithSection(section)
                    realm.add(dbSection, update: true)
                }
                
                for listItem in listItemsWithRelations.listItems {
                    let dbInventoryItem = ListItemMapper.dbWithListItem(listItem)
                    realm.add(dbInventoryItem, update: true)

                }
            }
            
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStamp(listItems: RemoteListItems, handler: Bool -> Void) {
        doInWriteTransaction({[weak self]realm in
            for listItem in listItems.listItems {
                realm.create(DBListItem.self, value: listItem.timestampUpdateDict, update: true)
            }
            for product in listItems.products {
                realm.create(DBProduct.self, value: product.timestampUpdateDict, update: true)
            }
            for productCategory in listItems.productsCategories {
                realm.create(DBProductCategory.self, value: productCategory.timestampUpdateDict, update: true)
            }
            for section in listItems.sections {
                realm.create(DBSection.self, value: section.timestampUpdateDict, update: true)
            }
            self?.updateLastSyncTimeStampSync(realm, lists: listItems.lists)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStamp(lists: RemoteListsWithDependencies, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateLastSyncTimeStampSync(realm, lists: lists)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    private func updateLastSyncTimeStampSync(realm: Realm, lists: RemoteListsWithDependencies) {
        for list in lists.lists {
            realm.create(DBList.self, value: list.timestampUpdateDict, update: true)
        }
        for inventory in lists.inventories {
            realm.create(DBInventory.self, value: inventory.timestampUpdateDict, update: true)
        }
    }
}
