//
//  ListInvitationsHandler.swift
//  shoppin
//
//  Created by ischuetz on 25/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

struct ListInvitationsHandler {

    static func handleInvitation(_ invitation: RemoteListInvitation, controller: UIViewController) {
        handleInvitations([invitation], controller: controller)
    }
    
    static func handleInvitations(_ invitations: [RemoteListInvitation], controller: UIViewController) {
        for invitation in invitations {
            ConfirmationPopup.show(
                title: "Invitation",
                message: "User \(invitation.sender) wants you to join list \(invitation.list.name)",
                okTitle: "Accept",
                cancelTitle: "Reject",
                controller: controller,
                onOk: {
                    Providers.listProvider.acceptInvitation(invitation, controller.successHandler{
                        Notification.send(.ListInvitationAccepted)
                    })
                },
                onCancel: {
                    Providers.listProvider.rejectInvitation(invitation, controller.successHandler{
                    })
            })
        }
    }
}
