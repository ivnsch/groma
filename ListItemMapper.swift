//
//  ListItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemMapper {

    // TODO remove
    class func listItemWithCD(cdListItem: CDListItem) -> ListItem {
        let product = ProductMapper.productWithCD(cdListItem.product)
        let section = SectionMapper.sectionWithCD(cdListItem.section)
        let list = ListMapper.listWithCD(cdListItem.list)
        return ListItem(uuid: cdListItem.uuid, done: cdListItem.done, quantity: cdListItem.quantity.integerValue, product: product, section:section, list: list, order: cdListItem.order.integerValue)
    }
    
    class func listItemWithDB(dbListItem: DBListItem) -> ListItem {
        let product = ProductMapper.productWithDB(dbListItem.product)
        let section = SectionMapper.sectionWithDB(dbListItem.section)
        let list = ListMapper.listWithDB(dbListItem.list)
        return ListItem(uuid: dbListItem.uuid, done: dbListItem.done, quantity: dbListItem.quantity, product: product, section: section, list: list, order: dbListItem.order)
    }
    
    class func dbWithListItem(listItem: ListItem) -> DBListItem {
        let dbListItem = DBListItem()
        dbListItem.uuid = listItem.uuid
        dbListItem.quantity = listItem.quantity // TODO float
        dbListItem.done = listItem.done
        dbListItem.order = listItem.order
        
        dbListItem.product = ProductMapper.dbWithProduct(listItem.product)
        dbListItem.section = SectionMapper.dbWithSection(listItem.section)
        dbListItem.list = ListMapper.dbWithList(listItem.list)
        
        return dbListItem
    }
    
    
    class func listItemsWithRemote(remoteListItems: RemoteListItems) -> ListItemsWithRelations {
        
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
        let (listsDict, lists) = toListDict(remoteListItems.lists)
        
        let remoteListItems = remoteListItems.listItems
        
        let listItems = remoteListItems.map {remoteListItem in
            ListItem(
                uuid: remoteListItem.uuid,
                done: remoteListItem.done,
                quantity: remoteListItem.quantity,
                product: productsDict[remoteListItem.productUuid]!,
                section: sectionsDict[remoteListItem.sectionUuid]!,
                list: listsDict[remoteListItem.listUuid]!,
                order: remoteListItem.order
            )
        }
        
        return (
            listItems,
            products,
            sections,
            lists
        )
    }
}
