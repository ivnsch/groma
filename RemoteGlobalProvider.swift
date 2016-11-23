//
//  RemoteGlobalProvider.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class RemoteGlobalProvider {

    func sync(_ params: [String: AnyObject], handler: @escaping (RemoteResult<RemoteSyncResult>) -> ()) {
        RemoteProvider.authenticatedRequest(.post, Urls.sync, params) {result in
            handler(result)
        }
    }
    
    func fullDownload(_ handler: @escaping (RemoteResult<RemoteSyncResult>) -> ()) {
        RemoteProvider.authenticatedRequest(.get, Urls.fullDownload) {result in
            handler(result)
        }
    }
}
