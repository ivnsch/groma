//
//  SyncResult.swift
//  shoppin
//
//  Created by ischuetz on 25/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

// Contains sync results that are relevant to controllers. The rest is handled internally inside provider, mapping directly to database objects.
struct SyncResult {

    let listInvites: [RemoteListInvitation]
    let inventoryInvites: [RemoteInventoryInvitation]
    
    init(listInvites: [RemoteListInvitation], inventoryInvites: [RemoteInventoryInvitation]) {
        self.listInvites = listInvites
        self.inventoryInvites = inventoryInvites
    }
}
