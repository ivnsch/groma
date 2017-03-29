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
public enum ProviderStatusCode: Int {
    case success = 1
    // Remote related
    case notAuthenticated = 3
    case alreadyExists = 4
    case notFound = 5
    case invalidCredentials = 6
    case sizeLimit = 7
    case registeredWithOtherProvider = 8
    case blacklisted = 10
    case serverError = 101 // Generic server error - invalid json, etc.
    case serverNotReachable = 102 // This is currently both server is down and no internet connection (detected when doing the request, opposed to .NoConnection).
    case unknownServerCommunicationError = 103 // e.g. request timed out
    case serverInvalidParamsError = 104 // Generic server error - invalid json, etc.
    case socialLoginError = 105
    case socialLoginCancelled = 106
    case socialAlreadyExists = 107
    case noConnection = 108 // Used when we detect in advance that there's no connectivity and don't proceed making the request. When this is not used, the execution of a request without a connection results in .ServerNotReachable
    case syncFailed = 109 // Generic status code for a failed sync - for whatever reason - note this is client generated, the server status code that leads to this can be anything.
    case mustUpdateApp = 111
    case iCloudLoginError = 123
    
    
    // DB related
    case databaseUnknown = 1000
    case databaseSavingError = 1001
    case databaseCriticalInitError = 1002
    
    // Other
    case unknown = 2000 // Note: This represents unknown client error. Unknown server error is mapped to .ServerError
    case dateCalculationError = 2001
    case cancelledLoginWithDifferentAccount = 2002
    case isEmpty = 2003 // Generic status to indicate that something is empty and requires special handling
    case userAlreadyExists = 2004 // Client generated, the server sends only AlreadyExists
    
    // Not strictly an error
    case isNewDeviceLoginAndDeclinedOverwrite = 3000
}

public class ProviderResult<T>: CustomDebugStringConvertible {
    public let status: ProviderStatusCode
    public let sucessResult: T?
    public let error: RemoteInvalidParametersResult? // TODO if we have more errors later, make this more generic - don't couple with remote (map it) and also not with validation
    public let errorObj: Any? // TODO type safe error object, see also TODO of error above
    
    public var success: Bool {
        return self.status == .success
    }
    
    public convenience init(status: ProviderStatusCode, sucessResult: T?) {
        self.init(status: status, sucessResult: sucessResult, error: nil, errorObj: nil)
    }
    
    public convenience init(status: ProviderStatusCode, error: RemoteInvalidParametersResult?) {
        self.init(status: status, sucessResult: nil, error: error, errorObj: nil)
    }
    
    public convenience init(status: ProviderStatusCode, errorObj: Any?) {
        self.init(status: status, sucessResult: nil, error: nil, errorObj: errorObj)
    }
    
    public convenience init(status: ProviderStatusCode) {
        self.init(status: status, sucessResult: nil, error: nil, errorObj: nil)
    }
    
    public init(status: ProviderStatusCode, sucessResult: T?, error: RemoteInvalidParametersResult?, errorObj: Any?) {
        self.status = status
        self.sucessResult = sucessResult
        self.error = error
        self.errorObj = errorObj
    }
    
    open var debugDescription: String {
        return "{\(type(of: self)) status: \(status), model: \(String(describing: sucessResult)), error: \(String(describing: error)), errorObj: \(String(describing: error))}"
    }
}


public struct DefaultRemoteResultMapper {
    static func toProviderStatus(_ remoteStatus: RemoteStatusCode) -> ProviderStatusCode {
        switch remoteStatus {
        case .alreadyExists: return .alreadyExists
        case .invalidParameters: return .serverInvalidParamsError
        case .notAuthenticated: return .notAuthenticated
        case .notFound: return .notFound
        case .parsingError: return .serverError
        case .invalidCredentials: return .invalidCredentials
        case .registeredWithOtherProvider: return .registeredWithOtherProvider
        case .blacklisted: return .blacklisted
        case .sizeLimit: return .sizeLimit
        case .success: return .success
        case .unknown: return .serverError
        case .notHandledHTTPStatusCode: return .serverError
        case .notRecognizedStatusFlag: return .serverError
        case .responseIsNil: return .serverError
        case .noJson: return .serverError
        case .serverNotReachable: return .serverNotReachable
        case .unknownServerCommunicationError: return .unknownServerCommunicationError
        case .actionNotFound: return .serverError
        case .internalServerError: return .serverError
        case .badRequest: return .serverError
        case .unsupportedMediaType: return .serverError
        case .clientParamsParsingError: return .unknown
        case .noConnection: return .noConnection
        case .notLoggedIn: return .notAuthenticated // for provider layer it doesn't matter if not authenticated status was determined in client or server, so we map both to .NotAuthenticated
        case .mustUpdateApp: return .mustUpdateApp
        }
    }
}

public struct DefaultRemoteErrorHandler {
    
    /**
    * Invoques handler if there's an error different than no connection or not logged in.
    * With this we can use the app offline or without account - the error handler, which triggers the error alert is not called on connection error.
    */
    static func handle<T, U>(_ remoteResult: RemoteResult<T>, errorMsg: String? = nil, handler: (ProviderResult<U>) -> ()) {
//        guard remoteResult.status != .Success else {return} // if it's a success response, there's nothing to do here. Handler will not be called.
        
        switch remoteResult.status {
        case .noConnection, .notLoggedIn
            // WARN: enable this only for testing (when using the moch user provider). In normal use, server not reachable should be shown. But:
            // TODO!!!! check priorities are correct during normal use: this error should appear ONLY when there's a connection AND user is logged in
            ,.serverNotReachable
            :
            QL1("Remote result status: \(remoteResult.status)")
            return
        case _:
            handleError(remoteResult, errorMsg: errorMsg, handler: handler)
        }
    }
    
    /**
    * Handles error for service that is remote-only (opposed to background sync). The user is most likely seeing a progress indicator and waiting for the response.
    * The difference in this case is that we don't ignore errors - unauthorized etc. is handled like a normal error, i.e. the handler is called, such that the user can get feedback and e.g. the progress indicator hidden.
    * Examples for calls where this should be used: login, register, pull
    */
    static func handleRemoteOnlyCall<T, U>(_ remoteResult: RemoteResult<T>, errorMsg: String? = nil, handler: (ProviderResult<U>) -> ()) {
        handleError(remoteResult, errorMsg: errorMsg, handler: handler)
    }
    
    fileprivate static func handleError<T, U>(_ remoteResult: RemoteResult<T>, errorMsg: String? = nil, handler: (ProviderResult<U>) -> ()) {
        
        // NotAuthenticated: special handling to show a login modal.
        // NotAuthenticated happens when we send a token to the server but the server rejects it. When we don't have a token, the remove provider returns .NotLoggedIn before doing the request, so if everything is implemented correctly, it should not be possible to try to do requests without a login token, which means .NotAuthenticated can happen only when the token is invalid/expired, which meeans on .NotAuthenticated results we should show the login modal.
        // On NotAuthenticated we also don't call the handler, we assume this is always used to call the default controller error handler which shows an error popup - since with the login modal we are already informing the user, the error popup is not necessary.
        // Note that when user does create/update/delete with an expired token, the operation first stays as usual in the local database, and is sent to server via the sync that is done immediately after login.
        if remoteResult.status == RemoteStatusCode.notAuthenticated {
            Notification.send(Notification.LoginTokenExpired)
            
        } else {
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
            let errorText = errorMsg.map{"\($0)::"} ?? ""
            QL4("\(errorText)\(remoteResult)")
            handler(ProviderResult(status: providerStatus, sucessResult: nil, error: remoteResult.error, errorObj: remoteResult.errorObj)) // TODO when remote fails somehow trigger a revert of local updates
        }
    }
    
}
