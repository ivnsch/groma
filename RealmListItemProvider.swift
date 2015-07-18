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
        let dbList = ListMapper.dbWithList(list)
        self.saveObj(dbList, update: true, handler: handler)
    }
    
    func saveLists(lists: [List], update: Bool = false, handler: Bool -> ()) {
        let dbLists = lists.map{ListMapper.dbWithList($0)}
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
        let dbListItem = ListItemMapper.dbWithListItem(listItem)
        self.saveObj(dbListItem, update: true, handler: handler)
    }
    
    func saveListItems(listItem: [ListItem], handler: Bool -> ()) {
        let dbListItems = listItem.map{ListItemMapper.dbWithListItem($0)}
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
        
        let dbListItems = listItemsWithRelations.listItems.map{ListItemMapper.dbWithListItem($0)}
        self.saveObjs(dbListItems, update: true) {listItemsMaybe in
            handler(true)
        }
    }
    
    func updateListItems(listItems: [ListItem], handler: Bool -> ()) {
        self.saveListItems(listItems) {saved in
            handler(saved)
        }
    }
}
