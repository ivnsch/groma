//
//  ErrorReport.swift
//  shoppin
//
//  Created by ischuetz on 02/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public struct ErrorReport: CustomDebugStringConvertible {

    public let title: String
    public let body: String
    
    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) title: \(title), body: \(body)"
    }

}

public struct ErrorReportTitle {
    static let request = "Request"
}
