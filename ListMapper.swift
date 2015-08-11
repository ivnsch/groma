//
//  ListMapper.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListMapper {
    
    class func dbWithList(list: List) -> DBList {
        let dbList = DBList()
        dbList.uuid = list.uuid
        dbList.name = list.name
        let dbSharedUsers = list.users.map{SharedUserMapper.dbWithSharedUser($0)}
        for dbObj in dbSharedUsers {
            dbList.users.append(dbObj)
        }
        return dbList
    }

    class func dbWithList(list: RemoteList) -> DBList {
        let dbList = DBList()
        dbList.uuid = list.uuid
        dbList.name = list.name
        let dbSharedUsers = list.users.map{SharedUserMapper.dbWithSharedUser($0)}
        for dbObj in dbSharedUsers {
            dbList.users.append(dbObj)
        }
        return dbList
    }
    
    class func listWithDB(dbList: DBList) -> List {
        let users = dbList.users.toArray().map{SharedUserMapper.sharedUserWithDB($0)}
        return List(uuid: dbList.uuid, name: dbList.name, users: users)
    }
    
    class func ListWithRemote(remoteList: RemoteList) -> List {
        return List(uuid: remoteList.uuid, name: remoteList.name, users: remoteList.users.map{SharedUserMapper.sharedUserWithRemote($0)})
    }
}
