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
    
    func loadSectionWithName(name: String, handler: Section? -> ()) {
        let mapper = {SectionMapper.sectionWithDB($0)}
        self.loadFirst(mapper, filter: "name = '\(name)'", handler: handler)
    }
    
    func loadSections(handler: [Section] -> ()) {
        let mapper = {SectionMapper.sectionWithDB($0)}
        self.load(mapper, handler: handler)
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
    
    // MARK: - ListItem
    
    func saveListItem(listItem: ListItem, handler: Bool -> ()) {
        let dbListItem = ListItemMapper.dbWithListItem(listItem)
        self.saveObj(dbListItem, update: true, handler: handler)
    }
    
    func saveListItems(listItem: [ListItem], handler: Bool -> ()) {
        let dbListItems = listItem.map{ListItemMapper.dbWithListItem($0)}
        self.saveObjs(dbListItems, update: true, handler: handler)
    }
    
    func loadListItems(list: List, handler: [ListItem] -> ()) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.load(mapper, filter: "list.uuid = '\(list.uuid)'", handler: handler)
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
        self.saveListItems(listItems, handler: handler)
    }
}
