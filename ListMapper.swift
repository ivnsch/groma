//
//  ListMapper.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

class ListMapper {
    
    class func listWithCD(cdList:CDList) -> List {
        return List(id: cdList.id, name: cdList.name)
    }
    
    
    class func ListWithRemote(remoteList: RemoteList) -> List {
        return List(id: remoteList.id, name: remoteList.name)
    }
    
}
