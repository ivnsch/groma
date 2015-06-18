//
//  ListItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

class ListItemMapper {

    class func listItemWithCD(cdListItem: CDListItem) -> ListItem {
        let product = ProductMapper.productWithCD(cdListItem.product)
        let section = SectionMapper.sectionWithCD(cdListItem.section)
        let list = ListMapper.listWithCD(cdListItem.list)
        return ListItem(id: cdListItem.id, done: cdListItem.done, quantity: cdListItem.quantity.integerValue, product: product, section:section, list: list, order: cdListItem.order.integerValue)
    }
    
    
    class func listItemsWithRemote(remoteListItems: RemoteListItems) -> ListItemsWithRelations {
        
        func toProductDict(remoteProducts: [RemoteProduct]) -> ([String: Product], [Product]) {
            var dict: [String: Product] = [:]
            var arr: [Product] = []
            for remoteProduct in remoteProducts {
                let product = ProductMapper.ProductWithRemote(remoteProduct)
                dict[remoteProduct.id] = product
                arr.append(product)
                
            }
            return (dict, arr)
        }
        
        func toListDict(remoteLists: [RemoteList]) -> ([String: List], [List]) {
            var dict: [String: List] = [:]
            var arr: [List] = []
            for remoteList in remoteLists {
                let list = ListMapper.ListWithRemote(remoteList)
                dict[remoteList.id] = list
                arr.append(list)
            }
            return (dict, arr)
        }
        
        func toSectionDict(remoteSections: [RemoteSection]) -> ([String: Section], [Section]) {
            var dict: [String: Section] = [:]
            var arr: [Section] = []
            for remoteSection in remoteSections {
                let section = SectionMapper.SectionWithRemote(remoteSection)
                dict[remoteSection.id] = section
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
                id: remoteListItem.id,
                done: remoteListItem.done,
                quantity: remoteListItem.quantity,
                product: productsDict[remoteListItem.productId]!,
                section: sectionsDict[remoteListItem.sectionId]!,
                list: listsDict[remoteListItem.listId]!,
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
