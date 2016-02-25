//
//  InventoryInvitationsHandler.swift
//  shoppin
//
//  Created by ischuetz on 25/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class InventoryInvitationsHandler {
    
    static func handleInvitation(invitation: RemoteInventoryInvitation, controller: UIViewController) {
        handleInvitations([invitation], controller: controller)
    }
    
    static func handleInvitations(invitations: [RemoteInventoryInvitation], controller: UIViewController) {
        for invitation in invitations {
            ConfirmationPopup.show(
                title: "Invitation",
                message: "User \(invitation.sender) wants you to join inventory \(invitation.inventory.name)",
                okTitle: "Accept",
                cancelTitle: "Reject",
                controller: controller,
                onOk: {
                    Providers.inventoryProvider.acceptInvitation(invitation, controller.successHandler{
                    })
                },
                onCancel: {
                    Providers.inventoryProvider.rejectInvitation(invitation, controller.successHandler{
                    })
            })
        }
    }
}
