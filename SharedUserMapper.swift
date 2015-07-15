//
//  SharedUserMapper.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class SharedUserMapper {
   
    class func sharedUserWithCD(cdSharedUser: CDSharedUser) -> SharedUser {
        return SharedUser(email: cdSharedUser.email, uuid: cdSharedUser.uuid, firstName: cdSharedUser.firstName, lastName: cdSharedUser.lastName)
    }
    
    class func sharedUserWithDB(dbSharedUser: DBSharedUser) -> SharedUser {
        return SharedUser(email: dbSharedUser.email, uuid: dbSharedUser.uuid, firstName: dbSharedUser.firstName, lastName: dbSharedUser.lastName)
    }
    
    class func sharedUserWithRemote(remoteSharedUser: RemoteSharedUser) -> SharedUser {
        return SharedUser(email: remoteSharedUser.email, uuid: remoteSharedUser.uuid, firstName: remoteSharedUser.firstName, lastName: remoteSharedUser.lastName)
    }
}
