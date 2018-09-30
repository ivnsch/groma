//
//  TwitterShareHelper.swift
//  groma
//
//  Created by Ivan Schuetz on 17.08.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import Foundation
import Accounts
import Social
import Providers

class TwitterShareHelper {

    static func followOnTwitter() {

        let accountStore = ACAccountStore()
        let twitterType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)

        accountStore.requestAccessToAccounts(with: twitterType, options: nil,
                                             completion: { isGranted, error in

                                                if let error = error {
                                                    logger.w("Error requesting accounts: \(error.localizedDescription)", .ui)
                                                }

                                                // NOTE accounts doesn't work anymore for iOS 11!
                                                guard let userAccounts = accountStore.accounts(with: twitterType),
                                                    userAccounts.count > 0 else {
                                                        openInBrowser()
                                                        logger.i("No Twitter accounts found, opening browser")
                                                        return
                                                }

                                                guard let firstActiveTwitterAccount = userAccounts[0] as? ACAccount else { return }

                                                // post params
                                                var params = [AnyHashable: Any]() //NSMutableDictionary()
                                                params["screen_name"] = "groma_app"
                                                params["follow"] = "true"

                                                // post request
                                                guard let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                                                              requestMethod: SLRequestMethod.POST,
                                                                              url: URL(string: "https://api.twitter.com/1.1/friendships/create.json"),
                                                                              parameters: params) else { return }
                                                request.account = firstActiveTwitterAccount

                                                // execute request
                                                request.perform(handler: { data, response, error in
                                                    logger.e(String(describing: response?.statusCode))
                                                    logger.e(String(describing: error?.localizedDescription))
                                                })
        })
    }

    fileprivate static func openInBrowser() {
        DispatchQueue.main.async {
            let url = URL(string: "https://twitter.com/intent/follow?screen_name=groma_app")!
            if UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
