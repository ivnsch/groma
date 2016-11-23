//
//  InventoryAuthChecker.swift
//  shoppin
//
//  Created by ischuetz on 08/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

struct InventoryAuthChecker {
    
    // Note that of course there's also a serverside check for this, but we need clientside also to filter these inventories so the user doesn't see or can't interact with them.
    // The reason we have inventories in the client they have no access to, is that the list needs a target inventory
    // we could maybe allow lists without target inventory, but this would need changes we have to think about. Having always the inventory is easier to implement.
    // Note also that the current implementation means any user who has access to a list associated with unauthorised inventory receives the emails of the shared users of this inventory
    // this is not great (TODO) but for now also don't consider it a big issue, as if someone shares a list with a user (note though - this someone not necessarily has access to the inventory neither), it means there's trust between the users / they know themselves (at least indirectly). In most cases they'll also be sharing the inventory.
    // Note also that here (list) we don't send inventory items.
    static func checkAccess(_ inventory: Inventory) -> Bool {
        if let me = Providers.userProvider.mySharedUser {
            if inventory.users.isEmpty // the inventory doesn't have shared users -> it wasn't synchronised yet (after sync it contains at least myself) -> it's local, so it belongs to me
                || (inventory.users.contains{$0.email == me.email}) // the inventory has shared users and I'm included
            {
                return true
                
            } else { // the inventory has shared users and I'm not included
                return false
            }
        } else { // I don't have registered or logged in on this device, which means all the data is local so I'm the owner of everything
            return true
        }
    }
}
