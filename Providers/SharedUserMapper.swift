//
//  SharedUserMapper.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class SharedUserMapper {
    
    class func sharedUserWithDB(_ dbSharedUser: DBSharedUser) -> DBSharedUser {
        return DBSharedUser(email: dbSharedUser.email)
    }
    
    class func sharedUserWithRemote(_ remoteSharedUser: RemoteSharedUser) -> DBSharedUser {
        return DBSharedUser(email: remoteSharedUser.email)
    }
    
    class func dbWithSharedUser(_ sharedUser: DBSharedUser) -> DBSharedUser {
        let dbSharedUser = DBSharedUser()
        dbSharedUser.email = sharedUser.email
        return dbSharedUser
    }
    
    class func dbWithSharedUser(_ sharedUser: RemoteSharedUser) -> DBSharedUser {
        let dbSharedUser = DBSharedUser()
        dbSharedUser.email = sharedUser.email
        return dbSharedUser
    }
}
