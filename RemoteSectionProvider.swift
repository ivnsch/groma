//
//  RemoteSectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class RemoteSectionProvider: RemoteProvider {

    func removeSection(uuid: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.section + "/\(uuid)") {result in
            handler(result)
        }
    }
}
