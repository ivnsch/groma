//
//  ListItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemMapper {
    
    class func listItemWithDB(dbListItem: DBListItem) -> ListItem {
        let product = ProductMapper.productWithDB(dbListItem.product)
        let section = SectionMapper.sectionWithDB(dbListItem.section)
        let list = ListMapper.listWithDB(dbListItem.list)
        return ListItem(uuid: dbListItem.uuid, status: ListItemStatus(rawValue: dbListItem.status)!, quantity: dbListItem.quantity, product: product, section: section, list: list, order: dbListItem.order)
    }
    
    class func dbWithListItem(listItem: ListItem) -> DBListItem {
        let dbListItem = DBListItem()
        dbListItem.uuid = listItem.uuid
        dbListItem.quantity = listItem.quantity // TODO float
        dbListItem.status = listItem.status.rawValue
        dbListItem.order = listItem.order
        
        dbListItem.product = ProductMapper.dbWithProduct(listItem.product)
        dbListItem.section = SectionMapper.dbWithSection(listItem.section)
        dbListItem.list = ListMapper.dbWithList(listItem.list)
        
        dbListItem.lastUpdate = listItem.lastUpdate
        if let lastServerUpdate = listItem.lastServerUpdate { // needs if let because Realm doesn't support optional NSDate yet
            dbListItem.lastServerUpdate = lastServerUpdate
        }
        return dbListItem
    }
    
    /**
    Parses the remote list items into model objects
    Note that the list items are sorted here by order field. The backend doesn't do this.
    */
    class func listItemsWithRemote(remoteListItems: RemoteListItems, list: List) -> ListItemsWithRelations {
        
        func toProductDict(remoteProducts: [RemoteProduct]) -> ([String: Product], [Product]) {
            var dict: [String: Product] = [:]
            var arr: [Product] = []
            for remoteProduct in remoteProducts {
                let product = ProductMapper.ProductWithRemote(remoteProduct)
                dict[remoteProduct.uuid] = product
                arr.append(product)
                
            }
            return (dict, arr)
        }
        
        func toListDict(remoteLists: [RemoteList]) -> ([String: List], [List]) {
            var dict: [String: List] = [:]
            var arr: [List] = []
            for remoteList in remoteLists {
                let list = ListMapper.ListWithRemote(remoteList)
                dict[remoteList.uuid] = list
                arr.append(list)
            }
            return (dict, arr)
        }
        
        func toSectionDict(remoteSections: [RemoteSection]) -> ([String: Section], [Section]) {
            var dict: [String: Section] = [:]
            var arr: [Section] = []
            for remoteSection in remoteSections {
                let section = SectionMapper.SectionWithRemote(remoteSection)
                dict[remoteSection.uuid] = section
                arr.append(section)
            }
            return (dict, arr)
        }
        
        let (productsDict, products) = toProductDict(remoteListItems.products)
        let (sectionsDict, sections) = toSectionDict(remoteListItems.sections)
        
        let remoteListItemsArr = remoteListItems.listItems
        
        let listItems = remoteListItemsArr.map {remoteListItem in
            ListItem(
                uuid: remoteListItem.uuid,
                status: ListItemStatus(rawValue: remoteListItem.status)!,
                quantity: remoteListItem.quantity,
                product: productsDict[remoteListItem.productUuid]!,
                section: sectionsDict[remoteListItem.sectionUuid]!,
                list: list,
                order: remoteListItem.order
            )
        }
        
        let sortedListItems = listItems.sortedByOrder()

        return (
            sortedListItems,
            products,
            sections
        )
    }
}
