//
//  ProductGroupMapper.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ProductGroupMapper {

    class func listItemGroupWithRemote(_ remoteGroup: RemoteGroup) -> ProductGroup {
        return ProductGroup(
            uuid: remoteGroup.uuid,
            name: remoteGroup.name,
            color: remoteGroup.color,
            order: remoteGroup.order,
            fav: remoteGroup.fav,
            lastServerUpdate: remoteGroup.lastUpdate
        )
    }
}
