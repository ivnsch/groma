//
//  RemoteErrorReporter.swift
//  shoppin
//
//  Created by ischuetz on 02/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteErrorReporter {
    
    func report(_ error: ErrorReport, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        let parameters = self.toRequestParams(error)
        RemoteProvider.authenticatedRequest(.post, Urls.error, parameters) {result in
            handler(result)
        }
    }
    
    fileprivate func toRequestParams(_ error: ErrorReport) -> [String: AnyObject] {
        return [
            "title": error.title as AnyObject,
            "body": error.body as AnyObject
        ]
    }
}
