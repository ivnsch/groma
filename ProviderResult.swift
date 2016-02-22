//
//  ProviderStatusCodes.swift
//  shoppin
//
//  Created by ischuetz on 27/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

// Status codes relevant to the user
enum ProviderStatusCode: Int {
    case Success = 1
    // Remote related
    case NotAuthenticated = 3
    case AlreadyExists = 4
    case NotFound = 5
    case InvalidCredentials = 6
    case ServerError = 101 // Generic server error - invalid json, etc.
    case ServerNotReachable = 102 // This is currently both server is down and no internet connection (detected when doing the request, opposed to .NoConnection).
    case UnknownServerCommunicationError = 103
    case ServerInvalidParamsError = 104 // Generic server error - invalid json, etc.
    case SocialLoginError = 105
    case SocialLoginCancelled = 106
    case SocialAlreadyExists = 107
    case NoConnection = 108 // Used when we detect in advance that there's no connectivity and don't proceed making the request. When this is not used, the execution of a request without a connection results in .ServerNotReachable
    
    // DB related
    case DatabaseUnknown = 1000
    case DatabaseSavingError = 1001

    // Other
    case Unknown = 2000 // Note: This represents unknown client error. Unknown server error is mapped to .ServerError
    case DateCalculationError = 2001
}

public class ProviderResult<T>: CustomDebugStringConvertible {
    let status: ProviderStatusCode
    let sucessResult: T?
    let error: RemoteInvalidParametersResult? // if we have more errors later, make this more generic - don't couple with remote (map it) and also not with validation
    
    var success: Bool {
        return self.status == .Success
    }
    
    convenience init(status: ProviderStatusCode, sucessResult: T) {
        self.init(status: status, sucessResult: sucessResult, error: nil)
    }
    
    convenience init(status: ProviderStatusCode, error: RemoteInvalidParametersResult?) {
        self.init(status: status, sucessResult: nil, error: error)
    }
    
    convenience init(status: ProviderStatusCode) {
        self.init(status: status, sucessResult: nil, error: nil)
    }
    
    private init(status: ProviderStatusCode, sucessResult: T?, error: RemoteInvalidParametersResult?) {
        self.status = status
        self.sucessResult = sucessResult
        self.error = error
    }
    
    public var debugDescription: String {
        return "{\(self.dynamicType) status: \(status), model: \(sucessResult), error: \(error)}"
    }
}


struct DefaultRemoteResultMapper {
    static func toProviderStatus(remoteStatus: RemoteStatusCode) -> ProviderStatusCode {
        switch remoteStatus {
        case .AlreadyExists: return .AlreadyExists
        case .InvalidParameters: return .ServerInvalidParamsError
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
        case .ActionNotFound: return .ServerError
        case .InternalServerError: return .ServerError
        case .BadRequest: return .ServerError
        case .UnsupportedMediaType: return .ServerError
        case .ClientParamsParsingError: return .Unknown
        case .NoConnection: return .NoConnection
        case .NotLoggedIn: return .NotAuthenticated // for provider layer it doesn't matter if not authenticated status was determined in client or server, so we map both to .NotAuthenticated
        }
    }
}

struct DefaultRemoteErrorHandler {
    
    /**
    * Invoques handler if there's an error different than no connection or not logged in.
    * With this we can use the app offline or without account - the error handler, which triggers the error alert is not called on connection error.
    */
    static func handle<T, U>(remoteResult: RemoteResult<T>, errorMsg: String? = nil, handler: ProviderResult<U> -> ()) {
        guard remoteResult.status != .Success else {return} // if it's a success response, there's nothing to do here. Handler will not be called.
        
        switch remoteResult.status {
        case .NoConnection, .NotLoggedIn, .NotAuthenticated
            // WARN: enable this only for testing (when using the moch user provider). In normal use, server not reachable should be shown. But:
            // TODO!!!! check priorities are correct during normal use: this error should appear ONLY when there's a connection AND user is logged in
            ,.ServerNotReachable
            :
            return
        case _:
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
            let errorText = errorMsg.map{"\($0)::"} ?? ""
            QL4("\(errorText)\(remoteResult)")
            handler(ProviderResult(status: providerStatus, error: remoteResult.error)) // TODO when remote fails somehow trigger a revert of local updates
        }
    }
}