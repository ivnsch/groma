//
//  SyncInvitationsHandler.swift
//  shoppin
//
//  Created by ischuetz on 25/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class InvitationsHandler {
    
    static func handleInvitations(_ listInvitations: [RemoteListInvitation], inventoryInvitations: [RemoteInventoryInvitation], controller: UIViewController) {
        ListInvitationsHandler.handleInvitations(listInvitations, controller: controller)
        InventoryInvitationsHandler.handleInvitations(inventoryInvitations, controller: controller)
    }
}
