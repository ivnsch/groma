//
//  DBResult.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

enum DBStatusCode: Int {
    case success = 1
    
    case alreadyExists = 4
    case notFound = 5
    
    case unknown = 100
}

open class DBResult<T>: CustomDebugStringConvertible {
    let status: DBStatusCode
    let sucessResult: T?
    let errorMsg: String?
    
    var success: Bool {
        return self.status == .success
    }
    
    var error: NSError? {
        if !self.success {
            return NSError(domain: "remote", code: self.status.rawValue, userInfo: ["msg": self.errorMsg ?? ""])
        } else {
            return nil
        }
    }
    
    convenience init(status: DBStatusCode, sucessResult: T) {
        self.init(status: status, sucessResult: sucessResult, errorMsg: nil)
    }
    
    convenience init(status: DBStatusCode, errorMsg: String?) {
        self.init(status: status, sucessResult: nil, errorMsg: errorMsg)
    }
    
    convenience init(status: DBStatusCode) {
        self.init(status: status, sucessResult: nil, errorMsg: nil)
    }
    
    fileprivate init(status: DBStatusCode, sucessResult: T?, errorMsg: String?) {
        self.status = status
        self.sucessResult = sucessResult
        self.errorMsg = errorMsg
    }
    
    open var debugDescription: String {
        return "{\(type(of: self)) status: \(self.status), model: \(self.sucessResult), errorMsg: \(self.errorMsg)}"
    }
}
