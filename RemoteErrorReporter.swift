//
//  RemoteErrorReporter.swift
//  shoppin
//
//  Created by ischuetz on 02/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteErrorReporter {
    
    func report(error: ErrorReport, handler: RemoteResult<NoOpSerializable> -> ()) {
        let parameters = self.toRequestParams(error)
        RemoteProvider.authenticatedRequest(.POST, Urls.error, parameters) {result in
            handler(result)
        }
    }
    
    private func toRequestParams(error: ErrorReport) -> [String: AnyObject] {
        return [
            "title": error.title,
            "body": error.body
        ]
    }
}
