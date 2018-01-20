//
//  SharedUserChecker.swift
//  shoppin
//
//  Created by ischuetz on 06/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import Providers

struct SharedUserChecker {

    static func check(_ email: String, users: [DBSharedUser], controller: UIViewController, onSuccess: @escaping VoidFunction) {
        
        if (Prov.userProvider.mySharedUser.map{$0.email == email}) ?? false {
            MyPopupHelper.showPopup(parent: controller, type: .info, message: trans("popups_participants_you_dont_have_to_add_yourself"), centerYOffset: -80)

        } else {
            if users.contains(where: {$0.email == email}) {
                MyPopupHelper.showPopup(parent: controller, type: .info, message: trans("popups_participants_user_already_in_list"), centerYOffset: -80)

            } else {
                controller.progressVisible()
                Prov.userProvider.isRegistered(email) {result in
                    
                    switch result.status {
                    case .success:
                        onSuccess()
                        
                    case .notFound:
                        MyPopupHelper.showPopup(parent: controller, type: .info, message: trans("popups_participants_user_not_registered"), centerYOffset: -80)

                    default:
                        controller.defaultErrorHandler()(result)
                        print("Error: AddEditListController.onAddUserTap: unexpeted result status in isRegistered: \(result), input: \(email)")
                    }
                    controller.progressVisible(false)
                }
            }

        }
    }
}
