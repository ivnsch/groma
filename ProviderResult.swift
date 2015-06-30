//
//  ProviderStatusCodes.swift
//  shoppin
//
//  Created by ischuetz on 27/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

enum ProviderStatusCode: Int {
    case Success = 1
    // Remote related
    case AlreadyExists = 4
    case NotFound = 5
    case Unknown = 100
    case ParsingError = 101
    
    // DB related
    
    
    // Other
}

public class ProviderResult<T>: DebugPrintable {
    let status: ProviderStatusCode
    let sucessResult: T?
    let errorMsg: String?
    
    var success: Bool {
        return self.status == .Success
    }
    
    var error: NSError? {
        if !self.success {
            return NSError(domain: "remote", code: self.status.rawValue, userInfo: ["msg": self.errorMsg ?? ""])
        } else {
            return nil
        }
    }
    
    convenience init(status: ProviderStatusCode, sucessResult: T) {
        self.init(status: status, sucessResult: sucessResult, errorMsg: nil)
    }
    
    convenience init(status: ProviderStatusCode, errorMsg: String?) {
        self.init(status: status, sucessResult: nil, errorMsg: errorMsg)
    }
    
    convenience init(status: ProviderStatusCode) {
        self.init(status: status, sucessResult: nil, errorMsg: nil)
    }
    
    private init(status: ProviderStatusCode, sucessResult: T?, errorMsg: String?) {
        self.status = status
        self.sucessResult = sucessResult
        self.errorMsg = errorMsg
    }
    
    public var debugDescription: String {
        return "{\(self.dynamicType) status: \(self.status), model: \(self.sucessResult), errorMsg: \(self.errorMsg)}"
    }
}


struct DefaultRemoteResultMapper {
    static func toProviderStatus(remoteStatus: RemoteStatusCode) -> ProviderStatusCode {
        switch remoteStatus {
        case .AlreadyExists: return .AlreadyExists
        case .NotFound: return .NotFound
        case .ParsingError: return .ParsingError
        case .Success: return .Success
        case .Unknown: return .Unknown
        }
    }
    
}