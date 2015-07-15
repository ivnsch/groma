//
//  RealmProvider.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

// TODO maybe remove the mapping toArray later if we want to stick with realm, as this can increase performance
// this would mean the provider is more coupled with realm but that's ok in this case

class RealmProvider {
    
    private func saveObj<T: Object>(obj: T, update: Bool = false, handler: Bool -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let realm = Realm()
            realm.write {
                realm.add(obj, update: update)
            }
            dispatch_async(dispatch_get_main_queue(), {
                handler(true)
            })
        })
    }

    private func saveObjs<T: Object>(objs: [T], update: Bool = false, handler: Bool -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let realm = Realm()
            realm.write {
                for obj in objs {
                    realm.add(obj, update: update)
                }
            }
            dispatch_async(dispatch_get_main_queue(), {
                handler(true)
            })
        })
    }
    
    private func load<T: Object, U>(mapper: T -> U, filter filterMaybe: String? = nil, handler: [U] -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var results = Realm().objects(T)
            if let filter = filterMaybe {
                results = results.filter(filter)
            }
            
            let objs: [T] = Realm().objects(T).toArray()
            let models = objs.map{mapper($0)}
            
            dispatch_async(dispatch_get_main_queue(), {
                handler(models)
            })
        })
    }
    
    func remove<T: Object>(pred: String, handler: Bool -> (), objType: T.Type) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let realm = Realm()
            let results: Results<T> = realm.objects(T).filter(pred)
            realm.write {
                realm.delete(results)
            }

            dispatch_async(dispatch_get_main_queue(), {
                handler(true)
            })
        })
    }
    
    
    // MARK: - Section
    
    func loadSectionWithUuid(uuid: String, handler: DBSection? -> ()) {
        var dbSections: Results<DBSection> = Realm().objects(DBSection).filter("uuid = '\(uuid)'")
        handler(dbSections.first)
    }

    func loadSectionWithName(name: String, handler: DBSection? -> ()) {
        var dbSections: Results<DBSection> = Realm().objects(DBSection).filter("name = '\(name)'")
        handler(dbSections.first)
    }
    
    func loadSections(handler: [DBSection] -> ()) {
        var dbSections: Results<DBSection> = Realm().objects(DBSection)
        handler(dbSections.toArray())
    }
    
    func saveSection(section: Section, handler: Bool -> ()) {
        let dbSection = DBSection()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        
        self.saveObj(dbSection, handler: handler)
    }
    
    func remove(section: Section, handler: Bool -> ()) {
        self.remove("uuid = '\(section.uuid)'", handler: handler, objType: DBSection.self)
    }
    
    
    // MARK: - Product
    
    func loadProductWithUuid(uuid: String, handler: DBProduct? -> ()) {
        var dbProducts: Results<DBProduct> = Realm().objects(DBProduct).filter("uuid = '\(uuid)'")
        handler(dbProducts.first)
    }

    func loadProductWithName(name: String, handler: DBProduct? -> ()) {
        var dbProducts: Results<DBProduct> = Realm().objects(DBProduct).filter("name = '\(name)'")
        handler(dbProducts.first)
    }
    
    func loadProducts(handler: [DBProduct] -> ()) {
        var dbProducts: Results<DBProduct> = Realm().objects(DBProduct)
        handler(dbProducts.toArray())
    }
    
    // MARK: - List
    
    func saveList(list: List, handler: Bool -> ()) {
        let dbList = self.toDBList(list)
        self.saveObj(dbList, update: true, handler: handler)
    }

    func saveLists(lists: [List], update: Bool = false, handler: Bool -> ()) {
        let dbLists = lists.map{self.toDBList($0)}
        self.saveObjs(dbLists, update: update, handler: handler)
    }
    
    func loadList(uuid: String, handler: DBList? -> ()) {
        var dbProducts: Results<DBList> = Realm().objects(DBList).filter("uuid = '\(uuid)'")
        handler(dbProducts.first)
    }
    
    func loadLists(handler: [List] -> ()) {
        let mapper = {dbList in
            return ListMapper.listWithDB(dbList)
        }
        self.load(mapper) {lists in
            handler(lists)
        }
    }
    
    func remove(list: List, handler: Bool -> ()) {
        self.remove("uuid = '\(list.uuid)'", handler: handler, objType: DBList.self)
    }
    
    // MARK: - ListItem

    func saveListItem(listItem: ListItem, handler: Bool -> ()) {
        let dbListItem = self.toDBListItem(listItem)
        self.saveObj(dbListItem, update: true, handler: handler)
    }
    
    func saveListItems(listItem: [ListItem], handler: Bool -> ()) {
        let dbListItems = listItem.map{self.toDBListItem($0)}
        self.saveObjs(dbListItems, update: true, handler: handler)
    }
    
    func loadListItems(list: List, handler: [DBListItem] -> ()) {
        let dbLists: Results<DBListItem> = Realm().objects(DBListItem).filter("list.uuid = '\(list.uuid)'")
        handler(dbLists.toArray())
    }

    
    
    func remove(listItem: ListItem, handler: Bool -> ()) {
        self.remove("uuid = '\(listItem.uuid)'", handler: handler, objType: DBListItem.self)
    }
    
    // TODO do we really need ListItemsWithRelations here, maybe convenience holder made sense only for coredata?
    func saveListItems(listItemsWithRelations: ListItemsWithRelations, handler: Bool -> ()) {
        let realm = Realm()
        
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
        
        let dbListItems = listItemsWithRelations.listItems.map{self.toDBListItem($0)}
        self.saveObjs(dbListItems, update: true) {listItemsMaybe in
            handler(true)
        }
    }
    
    func updateListItems(listItems: [ListItem], handler: Bool -> ()) {
        self.saveListItems(listItems) {saved in
            handler(saved)
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////
    // mapping
    
    private func toDBProduct(product: Product) -> DBProduct {
        let dbProduct = DBProduct()
        dbProduct.uuid = product.uuid
        dbProduct.name = product.name
        dbProduct.price = product.price
        return dbProduct
    }

    private func toDBList(list: List) -> DBList {
        let dbList = DBList()
        dbList.uuid = list.uuid
        dbList.name = list.name
        let dbSharedUsers = list.users.map{self.toDBSharedUser($0)}
        for dbObj in dbSharedUsers {
            dbList.users.append(dbObj)
        }
        return dbList
    }

    private func toDBSection(section: Section) -> DBSection {
        let dbSection = DBSection()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        return dbSection
    }
    
    private func toDBSharedUser(sharedUser: SharedUser) -> DBSharedUser {
        let dbSharedUser = DBSharedUser()
        dbSharedUser.uuid = sharedUser.uuid
        dbSharedUser.email = sharedUser.email
        dbSharedUser.firstName = sharedUser.firstName
        dbSharedUser.lastName = sharedUser.lastName
        return dbSharedUser
    }
    
    private func toDBListItem(listItem: ListItem) -> DBListItem {
        let dbListItem = DBListItem()
        dbListItem.uuid = listItem.uuid
        dbListItem.quantity = listItem.quantity // TODO float
        dbListItem.done = listItem.done
        dbListItem.order = listItem.order
        
        dbListItem.product = self.toDBProduct(listItem.product)
        dbListItem.section = self.toDBSection(listItem.section)
        dbListItem.list = self.toDBList(listItem.list)
        
        return dbListItem
    }
    
    
    
    
    
    
    
    
    
    
    
    
}
