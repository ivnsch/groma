//
//  ListMapper.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListMapper {
    
    class func listWithCD(cdList: CDList) -> List {
        let users = (cdList.users.allObjects as! [CDSharedUser]).map{SharedUserMapper.sharedUserWithCD($0)}
        return List(uuid: cdList.uuid, name: cdList.name, users: users)
    }
    
    class func ListWithRemote(remoteList: RemoteList) -> List {
        return List(uuid: remoteList.uuid, name: remoteList.name, users: remoteList.users.map{SharedUserMapper.sharedUserWithRemote($0)})
    }
}
