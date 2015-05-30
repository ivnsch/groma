//
//  ListItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

class ListItemMapper {

    class func listItemWithCD(cdListItem:CDListItem) -> ListItem {
        let product = ProductMapper.productWithCD(cdListItem.product)
        let section = SectionMapper.sectionWithCD(cdListItem.section)
        let list = ListMapper.listWithCD(cdListItem.list)
        return ListItem(id: cdListItem.id, done: cdListItem.done, quantity: cdListItem.quantity.integerValue, product: product, section:section, list: list, order: cdListItem.order.integerValue)
    }
}
