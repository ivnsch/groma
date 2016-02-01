//
//  RemoteGlobalProvider.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class RemoteGlobalProvider {

    func sync(params: [String: AnyObject], handler: RemoteResult<RemoteSyncResult> -> ()) {
        RemoteProvider.authenticatedRequest(.POST, Urls.sync, params) {result in
            handler(result)
        }
    }
}
