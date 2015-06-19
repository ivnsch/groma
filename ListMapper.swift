//
//  ListMapper.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

class ListMapper {
    
    class func listWithCD(cdList: CDList) -> List {
        return List(uuid: cdList.uuid, name: cdList.name)
    }
    
    
    class func ListWithRemote(remoteList: RemoteList) -> List {
        return List(uuid: remoteList.uuid, name: remoteList.name)
    }
    
}
