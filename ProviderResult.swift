//
//  ProviderStatusCodes.swift
//  shoppin
//
//  Created by ischuetz on 27/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

// Status codes relevant to the user
enum ProviderStatusCode: Int {
    case Success = 1
    // Remote related
    case NotAuthenticated = 3
    case AlreadyExists = 4
    case NotFound = 5
    case InvalidCredentials = 6
    case ServerError = 101 // Generic server error - invalid json, etc.
    case ServerNotReachable = 102 // This is currently both server is down and no internet connection
    case UnknownServerCommunicationError = 103
    case ServerInvalidParamsError = 104 // Generic server error - invalid json, etc.

    // DB related
    case DatabaseUnknown = 1000
    
    // Other
    case Unknown = 2000 // Note: This represents unknown client error. Unknown server error is mapped to .ServerError
}

public class ProviderResult<T>: CustomDebugStringConvertible {
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
        case .InvalidParameters: return .ServerError
        case .NotAuthenticated: return .NotAuthenticated
        case .NotFound: return .NotFound
        case .ParsingError: return .ServerError
        case .InvalidCredentials: return .InvalidCredentials
        case .Success: return .Success
        case .Unknown: return .ServerError
        case .NotHandledHTTPStatusCode: return .ServerError
        case .NotRecognizedStatusFlag: return .ServerError
        case .ResponseIsNil: return .ServerError
        case .NoJson: return .ServerError
        case .ServerNotReachable: return .ServerNotReachable
        case .UnknownServerCommunicationError: return .UnknownServerCommunicationError
        case .InternalServerError: return .ServerError
        case .BadRequest: return .ServerInvalidParamsError
        case .UnsupportedMediaType: return .ServerError
        case .ClientParamsParsingError: return .Unknown
        }
    }
}