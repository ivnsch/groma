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
        return ListItem(done: cdListItem.done, product: product, section:section)
    }
}
