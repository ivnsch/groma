//
//  InventoryInvitationsHandler.swift
//  shoppin
//
//  Created by ischuetz on 25/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class InventoryInvitationsHandler {
    
    static func handleInvitation(_ invitation: RemoteInventoryInvitation, controller: UIViewController) {
        handleInvitations([invitation], controller: controller)
    }
    
    static func handleInvitations(_ invitations: [RemoteInventoryInvitation], controller: UIViewController) {
        for invitation in invitations {
            ConfirmationPopup.show(
                title: "Invitation",
                message: "User \(invitation.sender) wants you to join inventory \(invitation.inventory.name)",
                okTitle: "Accept",
                cancelTitle: "Reject",
                controller: controller,
                onOk: {
                    Prov.inventoryProvider.acceptInvitation(invitation, controller.successHandler{
                        Notification.send(Notification.InventoryInvitationAccepted)
                    })
                },
                onCancel: {
                    Prov.inventoryProvider.rejectInvitation(invitation, controller.successHandler{
                    })
            })
        }
    }
}
