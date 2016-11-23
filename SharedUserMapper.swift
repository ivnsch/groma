//
//  SharedUserMapper.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class SharedUserMapper {
    
    class func sharedUserWithDB(_ dbSharedUser: DBSharedUser) -> SharedUser {
        return SharedUser(email: dbSharedUser.email)
    }
    
    class func sharedUserWithRemote(_ remoteSharedUser: RemoteSharedUser) -> SharedUser {
        return SharedUser(email: remoteSharedUser.email)
    }
    
    class func dbWithSharedUser(_ sharedUser: SharedUser) -> DBSharedUser {
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
