//
//  SyncResult.swift
//  shoppin
//
//  Created by ischuetz on 25/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

// Contains sync results that are relevant to controllers. The rest is handled internally inside provider, mapping directly to database objects.
public struct SyncResult {

    public let listInvites: [RemoteListInvitation]
    public let inventoryInvites: [RemoteInventoryInvitation]
    
    public init(listInvites: [RemoteListInvitation], inventoryInvites: [RemoteInventoryInvitation]) {
        self.listInvites = listInvites
        self.inventoryInvites = inventoryInvites
    }
}
