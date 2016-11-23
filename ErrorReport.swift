//
//  ErrorReport.swift
//  shoppin
//
//  Created by ischuetz on 02/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

struct ErrorReport: CustomDebugStringConvertible {

    let title: String
    let body: String
    
    init(title: String, body: String) {
        self.title = title
        self.body = body
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) title: \(title), body: \(body)"
    }

}

struct ErrorReportTitle {
    static let request = "Request"
}
