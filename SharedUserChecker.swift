//
//  SharedUserChecker.swift
//  shoppin
//
//  Created by ischuetz on 06/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


struct SharedUserChecker {

    static func check(_ email: String, users: [DBSharedUser], controller: UIViewController, onSuccess: @escaping VoidFunction) {
        
        if (Providers.userProvider.mySharedUser.map{$0.email == email}) ?? false {
            AlertPopup.show(title: trans("popup_title_info"), message: trans("popups_participants_you_dont_have_to_add_yourself"), controller: controller)
            
        } else {
            if users.contains(where: {$0.email == email}) {
                AlertPopup.show(title: trans("popup_title_info"), message: trans("popups_participants_user_already_in_list", email), controller: controller)
                
            } else {
                controller.progressVisible()
                Providers.userProvider.isRegistered(email) {result in
                    
                    switch result.status {
                    case .success:
                        onSuccess()
                        
                    case .notFound:
                        AlertPopup.show(title: trans("popup_title_info"), message: trans("popups_participants_user_not_registered", email), controller: controller)
                        
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
