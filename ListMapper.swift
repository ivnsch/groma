//
//  ListMapper.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

class ListMapper {
    
    class func listWithCD(cdList:CDList) -> List {
        let id = cdList.objectID.URIRepresentation().absoluteString
        return List(id:id!, name: cdList.name)
    }
}
