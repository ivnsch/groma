//
//  SharedUserChecker.swift
//  shoppin
//
//  Created by ischuetz on 06/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


struct SharedUserChecker {

    static func check(email: String, users: [SharedUser], controller: UIViewController, onSuccess: VoidFunction) {
        
        if (Providers.userProvider.mySharedUser.map{$0.email == email}) ?? false {
            AlertPopup.show(title: "Info", message: "You don't have to add yourself to the list", controller: controller)
            
        } else {
            if users.contains({$0.email == email}) {
                AlertPopup.show(title: "Info", message: "The user: \(email)\n is already in the list", controller: controller)
                
            } else {
                controller.progressVisible()
                Providers.userProvider.isRegistered(email) {result in
                    
                    switch result.status {
                    case .Success:
                        onSuccess()
                        
                    case .NotFound:
                        AlertPopup.show(title: "Info", message: "The user: \(email)\n is not registered", controller: controller)
                        
                    default:
                        controller.defaultErrorHandler()(providerResult: result)
                        print("Error: AddEditListController.onAddUserTap: unexpeted result status in isRegistered: \(result), input: \(email)")
                    }
                    controller.progressVisible(false)
                }
            }

        }
    }
}