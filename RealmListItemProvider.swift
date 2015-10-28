//
//  RealmListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmListItemProvider: RealmProvider {
    
    // MARK: - Section
    
    func loadSectionWithUuid(uuid: String, handler: Section? -> ()) {
        let mapper = {SectionMapper.sectionWithDB($0)}
        self.loadFirst(mapper, filter: "uuid = '\(uuid)'", handler: handler)
    }
    
    func loadSection(name: String, handler: Section? -> ()) {
        loadSections([name]) {sections in
            handler(sections.first)
        }
    }
    
    func loadSections(names: [String], handler: [Section] -> ()) {
        let mapper = {SectionMapper.sectionWithDB($0)}
        let sectionsNamesStr: String = ",".join(names.map{"'\($0)'"})
        self.load(mapper, filter: "name IN {\(sectionsNamesStr)}", handler: handler)
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
    
    
    // MARK: - Product
    
    func loadProductWithUuid(uuid: String, handler: Product? -> ()) {
        let mapper = {ProductMapper.productWithDB($0)}
        self.loadFirst(mapper, filter: "uuid = '\(uuid)'", handler: handler)
    }
    
    func loadProductWithName(name: String, handler: Product? -> ()) {
        let mapper = {ProductMapper.productWithDB($0)}
        self.loadFirst(mapper, filter: "name = '\(name)'", handler: handler)
    }
    
    func loadProducts(handler: [Product] -> ()) {
        let mapper = {ProductMapper.productWithDB($0)}
        self.load(mapper, handler: handler)
    }
    
    func deleteProductAndDependencies(product: Product, handler: Bool -> Void) {
        
        doInWriteTransaction({realm in
            let productResult = realm.objects(DBProduct).filter("uuid = '\(product.uuid)'")
            realm.delete(productResult)
            let inventoryResult = realm.objects(DBInventoryItem).filter("product.uuid = '\(product.uuid)'")
            realm.delete(inventoryResult)
            let historyResult = realm.objects(DBHistoryItem).filter("product.uuid = '\(product.uuid)'")
            realm.delete(historyResult)
            let planResult = realm.objects(DBPlanItem).filter("product.uuid = '\(product.uuid)'")
            realm.delete(planResult)
            
            return true
            
            }, finishHandler: {success in
                handler(success)
        })
    }
    
    func saveProduct(productInput: ProductInput, updateSuggestions: Bool = true, update: Bool = true, handler: Product? -> ()) {
        
        loadProductWithName(productInput.name) {[weak self] productMaybe in

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
            
            let product = Product(uuid: uuid, name: productInput.name, price: productInput.price, category: productInput.category)
            
            self?.saveProducts([product]) {saved in
                if saved {
                    handler(product)
                } else {
                    print("Error: RealmListItemProvider.saveProductError, could not save product: \(product)")
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
                    handler(success)
            })
        }
    }
    
    
    // MARK: - Suggestion

    func loadProductSuggestions(handler: [Suggestion] -> ()) {
        let mapper = {ProductSuggestionMapper.suggestionWithDB($0)}
        self.load(mapper, handler: handler)
    }

    func loadSectionSuggestions(handler: [Suggestion] -> ()) {
        let mapper = {SectionSuggestionMapper.suggestionWithDB($0)}
        self.load(mapper, handler: handler)
    }
    
    /**
    * Batch save of product suggestions, used to prefill database
    */
    func saveProductSuggestions(suggestions: [Suggestion], handler: Bool -> ()) {
        let dbSuggestions = suggestions.map{ProductSuggestionMapper.dbWithSuggestion($0)}
        self.saveObjs(dbSuggestions, update: true, handler: handler)
    }

    /**
    * Batch save of section suggestions, used to prefill database
    */
    func saveSectionSuggestions(suggestions: [Suggestion], handler: Bool -> ()) {
        let dbSuggestions = suggestions.map{SectionSuggestionMapper.dbWithSuggestion($0)}
        self.saveObjs(dbSuggestions, update: true, handler: handler)
    }
    
    // MARK: - List
    
    func saveList(list: List, handler: Bool -> ()) {
        let dbList = ListMapper.dbWithList(list)
        self.saveObj(dbList, update: true, handler: handler)
    }
    
    func saveLists(lists: [List], update: Bool = false, handler: Bool -> ()) {
        let dbLists = lists.map{ListMapper.dbWithList($0)}
        self.saveObjs(dbLists, update: update, handler: handler)
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
        self.remove("uuid = '\(list.uuid)'", handler: handler, objType: DBList.self)
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
    */
    func saveListItems(var listItems: [ListItem], updateSuggestions: Bool = true, incrementQuantity: Bool, handler: [ListItem]? -> ()) {
        doInWriteTransaction({[weak self] realm in
           
            // if we want to increment if item with same product name exists
            // Note that we always want this except when saveListItems is called after having cleared the database, e.g. (currently) on server sync, or when doing an update
            if incrementQuantity {
                // get all existing list items with product names using IN query
                let productNamesStr: String = ",".join(listItems.map{"'\($0.product.name)'"})
                let existingListItems = realm.objects(DBListItem).filter("product.name IN {\(productNamesStr)}") // TODO get only listitems in the list!
                
                let uuidToDBListItemDict: [String: DBListItem] = existingListItems.toDictionary{
                    ($0.product.uuid, $0)
                }
                // merge list items with existing, in order to do update (increment quantity)
                // this means: use uuid of existing item, increment quantity, and for the rest copy fields of new item
                listItems = listItems.map {listItem in
                    if let existingDBListItem = uuidToDBListItemDict[listItem.product.uuid] {
                        return listItem.copy(uuid: existingDBListItem.uuid, quantity: listItem.quantity + existingDBListItem.quantity)
                    } else {
                        return listItem
                    }
                }
            }
            
            for listItem in listItems {
//                self?.saveListItemHelper(realm, listItem: listItem, updateSuggestions: updateSuggestions)

                // TODO possible to use batch save here?
                let dbListItem = ListItemMapper.dbWithListItem(listItem)
                realm.add(dbListItem, update: true)
                
                if updateSuggestions {
                    self?.saveProductSuggestionHelper(realm, product: listItem.product)
                    
                    let sectionSuggestion = SectionSuggestionMapper.dbWithSection(listItem.section)
                    realm.add(sectionSuggestion, update: true)
                }
                
            }
            return true
            
            }, finishHandler: {success in
                if success {
                    handler(listItems)
                } else {
                    handler(nil)
                }
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
        saveListItems(listItems, incrementQuantity: false) {updatedListItemsMaybe in
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
                let count = realm.objects(DBListItem).filter("status = \(status.rawValue) AND list.uuid = '\(list.uuid)'").count
                finished(count)
            } catch _ {
                print("Error: creating Realm() in load, returning empty results")
                finished(nil) // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        })
    }
    
    func saveListsSyncResult(syncResult: RemoteListWithListItemsSyncResult, handler: Bool -> ()) {
        
        self.doInWriteTransaction({realm in
            
            let inventories = realm.objects(DBList)
            let inventoryItems = realm.objects(DBListItem)
            let sections = realm.objects(DBSection)
            
            realm.delete(inventories)
            realm.delete(inventoryItems)
            realm.delete(sections)
            // we don't delete the products because these are referenced also by inventory items and maybe also other things in the future
            
            // save inventories
            var dbInventoriesDict: [String: DBList] = [:] // cache saved inventories for fast access when saving inventory items, which need the inventory
            let remoteInventories = syncResult.lists
            for remoteInventory in remoteInventories {
                let dbInventory = ListMapper.dbWithList(remoteInventory)
                dbInventoriesDict[remoteInventory.uuid] = dbInventory
                realm.add(dbInventory, update: true)
            }
            
            // save inventory items
            for listItemsSyncResult in syncResult.listItemsSyncResults {
                
                if let list = dbInventoriesDict[listItemsSyncResult.listUuid] {
                    let listItemsWithRelations = ListItemMapper.listItemsWithRemote(listItemsSyncResult.listItems, list: ListMapper.listWithDB(list))
                    
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
                } else {
                    print("Error: Invalid response: Inventory item sync response: No inventory found for inventory item uuid")
                    // TODO good unit test for this, also send to error monitoring
                    // This should not happen, but if it does we just don't save these inventory items. The rest continues normally.
                }
            }
            
            return true
            
            }, finishHandler: {success in
                handler(success)
        })
    }
}
