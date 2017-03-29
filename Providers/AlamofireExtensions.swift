//
//  AlamofireExtensions.swift
//  shoppin
//
//  Created by ischuetz on 22/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire
import QorumLogs

// Representation of status code related with remote responses
// Can represent a HTTP status code sent by the server, a status flag in the JSON response, or a client-side error related with the processing of the remote response
// 
// Not handled JSON as well as HTTP status (different than 200) should be mapped to .Unknown
//
// Note that this doesn't contain any success HTTP status codes as this is currently not necessary, either it's an error, or if not, we have a JSON object where we can query the JSON status flag which is sent in all JSON responses. Improvement: TODO: use HTTP status codes instead of JSON flag wherever possible - e.g. use 204 to indicate a success response with no content. So we don't have to parse the JSON. Currently this is being sent using JSON status flag "NotFound" (which represents -maybe unexpectedly- empty result, no 404).
enum RemoteStatusCode: Int {
    
    // JSON Flag
    case success = 1
    case invalidParameters = 2

    case alreadyExists = 4
    case notFound = 5
    case invalidCredentials = 6
    case sizeLimit = 7
    case registeredWithOtherProvider = 8
    case blacklisted = 10
    case unknown = 100 // Note that, like above cases this also is sent as status by the server - don't change raw value
 
    // HTTP
    case notAuthenticated = 401
    case badRequest = 400 // e.g. post request with wrong json
    case actionNotFound = 404
    case unsupportedMediaType = 415
    case internalServerError = 500
    
    // Client generated
    case parsingError = 10001
    case notRecognizedStatusFlag = 10002
    case noJson = 10003
    case notHandledHTTPStatusCode = 10004
    case responseIsNil = 10005
    case serverNotReachable = 10006 // This is currently both server is down and no internet connection (detected when doing the request, opposed to .NoConnection).
    case unknownServerCommunicationError = 10007 // Communication errors other than .ServerNotReachable
    case clientParamsParsingError = 10008 // This should really not happen, but the serialization for some requests needs do catch so for overall consistency in catch we return this error
    case noConnection = 10009 // Used when we detect in advance that there's no connectivity and don't proceed making the request. When this is not used, the execution of a request without a connection results in .ServerNotReachable
    case notLoggedIn = 10010 // Returned when there's no login token stored. For caller normally same meaning as .NotAuthenticated - difference is that .NotAuthenticated is determined by the server
    
    case mustUpdateApp = 10011 // Must update app, service response except status and app version info was not processed.
}

extension RemoteStatusCode: CustomStringConvertible {
    var description: String { get {
        switch self {
        default: return "\(self.rawValue)"
        }
    }}
}


extension Request {
    public func debugLog() -> Self {
        #if DEBUG
            debugPrint(self)
        #endif
        return self
    }
}


public final class RemoteValidationError: CustomDebugStringConvertible {
    public let msg: String
    public let args: [String]

    public init?(json: AnyObject) {
        msg = json.value(forKeyPath: "message") as! String
        args = json.value(forKeyPath: "args") as! [String]
    }
    
    public var debugDescription: String {
        return "[msg: \(msg), args: \(args)]"
    }
}

public final class RemotePathValidationError: CustomDebugStringConvertible {
    public let path: String
    public let validationErrors: [RemoteValidationError]
    
    public init?(json: AnyObject) {
        path = json.value(forKeyPath: "path") as! String
        
        let validationErrorsObjs = json.value(forKeyPath: "validationErrors") as! [AnyObject]
        var validationErrors: [RemoteValidationError] = []
        for json in validationErrorsObjs {
            if let validationError = RemoteValidationError(json: json) {
                validationErrors.append(validationError)
            } else {
                self.validationErrors = [] // swift compiler requires to have initialised all stored properties before returning nil from initialiser
                return nil // don't return anything if parsing of one error fails. Note that our model objects are not programmed for failure though, if structure is wrong it will crash in most cases (forced casting). This should be improved in the future.
            }
        }
        self.validationErrors = validationErrors
    }
    
    public var debugDescription: String {
        return "[path: \(path), errors: \(validationErrors)]"
    }
}

public final class RemoteInvalidParametersResult
//: CustomDebugStringConvertible for some reason this causes a compiler error in other classes so for now commented, no time to investigate
{
    public let pathErrors: [RemotePathValidationError]

    init?(json: AnyObject) {
        let jsonArray = json as! [AnyObject]
        var pathErrors: [RemotePathValidationError] = []
        for json in jsonArray {
            if let path = RemotePathValidationError(json: json) {
                pathErrors.append(path)
            } else {
                self.pathErrors = [] // swift compiler requires to have initialised all stored properties before returning nil from initialiser
                return nil // don't return anything if parsing of one error fails. Note that our model objects are not programmed for failure though, if structure is wrong it will crash in most cases (forced casting). This should be improved in the future.
            }
        }
        self.pathErrors = pathErrors
    }
    
    var debugDescription: String {
        return "[pathErrors: \(pathErrors)]"
    }
}

//////////////////
// json

public protocol ResponseObjectSerializable {
    init?(representation: AnyObject)
}

// dummy object to be able to use responseMyObject when there's no returned data
open class NoOpSerializable: ResponseObjectSerializable {
    @objc required public init?(representation: AnyObject) {}
}


open class RemoteResult<T>: CustomDebugStringConvertible {
    
    let status: RemoteStatusCode
    
    // Callers can assume that if successResult != nil, status == .Success. If the reponse's status is != .Success no data will be parsed and subsequently successResult not set.
    let successResult: T?
    
    let error: RemoteInvalidParametersResult? // TODO more generic error field, maybe together with errorObj
    
    let errorObj: Any? // TODO type safe error object, see also TODO of error above
    
    var success: Bool {
        return self.status == .success
    }
    
    convenience init(status: RemoteStatusCode, sucessResult: T?) {
        self.init(status: status, sucessResult: sucessResult, error: nil, errorObj: nil)
    }
    
    convenience init(status: RemoteStatusCode, error: RemoteInvalidParametersResult?) {
        self.init(status: status, sucessResult: nil, error: error, errorObj: nil)
    }
    
    convenience init(status: RemoteStatusCode, errorObj: Any?) {
        self.init(status: status, sucessResult: nil, error: nil, errorObj: errorObj)
    }
    
    convenience init(status: RemoteStatusCode) {
        self.init(status: status, sucessResult: nil, error: nil, errorObj: nil)
    }
    
    fileprivate init(status: RemoteStatusCode, sucessResult: T?, error: RemoteInvalidParametersResult?, errorObj: Any?) {
        self.status = status
        self.successResult = sucessResult
        self.error = error
        self.errorObj = errorObj
    }
    
    open var debugDescription: String {
        let errorText = error.map{$0.debugDescription} ?? ""
        return "{\(type(of: self)) status: \(status), model: \(String(describing: successResult)), error: \(errorText), errorObj: \(String(describing: errorObj))}"
    }
}

// This would have been an extension if "Alamofire" wasn't only a namespace...
// The idea was to be called like Alamofire.request
struct AlamofireHelper {
    
    static func authenticatedRequest(_ method: HTTPMethod, _ url: String, _ parameters: [String: AnyObject]? = nil) -> DataRequest {

        if QorumLogs.minimumLogLevelShown == 1 {
            let unwrapedParams = parameters?.map{$0} ?? [:] // make more readable
            QL1("\(method) \(url), parameters: \(unwrapedParams)")
        }
        
//        if let pars = parameters {
//            let dataExample: NSData = NSKeyedArchiver.archivedDataWithRootObject(pars)
//            let mb = Float(dataExample.length) / Float(1024) / Float(1024)
//            QL1("size: \(mb)")
//            QL1("size dict: \(pars.count)")
//        }
        
        var mutableURLRequest = URLRequest(url: URL(string: url)!)
        mutableURLRequest.httpMethod = method.rawValue
        
        if let token = AccessTokenHelper.loadToken() {
//            QL1("Setting the token header: \(token)")
            mutableURLRequest.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
        if let deviceId: String = PreferencesManager.loadPreference(PreferencesManagerKey.deviceId) {
            mutableURLRequest.setValue(deviceId, forHTTPHeaderField: "did")
        }
        
        // TODO: server: when encoding is not supported the response is nil! It should send a valid response. Happened testing listItems (GET) with JSON encoding
//        let encoding = method == .get ? Alamofire.URLEncoding : Alamofire.JSONEncoding
        
        let request: URLRequest = {
            if method == .get {
                return try! Alamofire.URLEncoding.default.encode(mutableURLRequest, with: parameters)
            } else {
                return try! Alamofire.JSONEncoding.default.encode(mutableURLRequest, with: parameters)
            }
        }()
        
        return Alamofire.request(request)
    }
    
    static func authenticatedRequest(_ method: HTTPMethod, _ url: String, _ parameters: [[String: AnyObject]]) -> DataRequest {
        
        QL1("\(method) \(url), parameters: \(parameters)")
        
        // this is handled differently because the parameters are an array and default request in alamofire doesn't support this (the difference is the request.HTTPBody line)
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
        if let token = AccessTokenHelper.loadToken() {
//            QL1("Setting the token header: \(token)")
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
        if let deviceId: String = PreferencesManager.loadPreference(PreferencesManagerKey.deviceId) {
            request.setValue(deviceId, forHTTPHeaderField: "did")
        }
        
        // TODO!!!! review, force try parameter serialization. For now like this because there's no known reason why this would fail, and simplifies code significantly
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        return Alamofire.request(request)
    }
}


//public protocol ResponseObjectSerializable2 {
//    init?(response: HTTPURLResponse, representation: AnyObject)
//}
//
//extension DataRequest {
//    public func responseObject<T: ResponseObjectSerializable2>(_ completionHandler: (DataResponse<T>) -> Void) -> Self {
//        let responseSerializer = DataResponseSerializer<T> { request, response, data, error in
//            if let error = error {
//                return .failure(error)
//            }
//
//            let JSONResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
//            let result = JSONResponseSerializer.serializeResponse(request, response, data, error)
//            
//            switch result {
//            case .success(let value):
//                if let
//                    response = response,
//                    let responseObject = T(response: response, representation: value as AnyObject)
//                {
//                    return .success(responseObject)
//                } else {
//                    return .failure(NSError(domain: "com.groma.error", code: RemoteStatusCode.parsingError.rawValue, userInfo: ["reason": "JSON could not be serialized into response object: \(value)"]))
//                }
//            case .failure(let error):
//                return .failure(error)
//            }
//        }
//        
//        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
//    }
//}
//

extension DataRequest {

    public func responseMyArray<T: ResponseObjectSerializable>(_ completionHandler: @escaping (URLRequest?, DataResponse<RemoteResult<[T]>>?, RemoteResult<[T]>) -> Void) -> Self {

        let dataParser: (AnyObject, HTTPURLResponse) -> ([T]?) = {data, response in
            var objs = [T]()
            for obj in data as! [AnyObject] {
                if let obj = T(representation: obj) {
                    objs.append(obj)
                    
                } else {
                    print("Error parsing obj: \(obj)")
                    return nil
                }
            }
            return objs
        }
        
        return self.responseHandler(dataParser, completionHandler: completionHandler)
    }
    
    public func responseMyObject<T: ResponseObjectSerializable>(_ completionHandler: @escaping (URLRequest?, DataResponse<RemoteResult<T>>?, RemoteResult<T>) -> Void) -> Self {
        
        let dataParser: (AnyObject, HTTPURLResponse) -> (T?) = {data, response in
            return T(representation: data)
        }
        
        return self.responseHandler(dataParser, completionHandler: completionHandler)
    }

    public func responseMyTimestamp(_ completionHandler: @escaping (URLRequest?, DataResponse<RemoteResult<Int64>>?, RemoteResult<Int64>) -> Void) -> Self {
        
        let dataParser: (AnyObject, HTTPURLResponse) -> (Int64?) = {data, response in
            return (data as? Double).map{Int64($0)}
        }
        
        return self.responseHandler(dataParser, completionHandler: completionHandler)
    }
    
    // Common method to parse json object and array
    fileprivate func responseHandler<T>(_ dataParser: @escaping (AnyObject, HTTPURLResponse) -> (T?), completionHandler: @escaping (URLRequest?, DataResponse<RemoteResult<T>>?, RemoteResult<T>) -> Void) -> Self {

        let responseSerializer = DataResponseSerializer<RemoteResult<T>> { request, responseMaybe, data, error in
            
            // By default error is logged as error both in Qorum and server. We can also decide to output Qorum only as a warning and not report to server.
            func logRequesstWarningOrError(_ msg: String, isWarning: Bool, reportToServer: Bool) {

                guard (request?.url.map{$0.absoluteString != Urls.error}) ?? true else {return} // don't try to report error if an error report failed, to prevent infinite loop

                let requestStr: String = {
                    if let request = request {
                        let methodStr = request.httpMethod ?? "<Undefined HTTP method>"
                        return "Called: \(methodStr), url: \(String(describing: request.url))"
                    } else {
                        return "Undefined request"
                    }
                }()
                
                let fullStr = "\(requestStr): \(msg)"
                if isWarning {
                    QL3(fullStr)
                } else {
                    QL4(fullStr)
                }
                
                if reportToServer {
                    let errorReport = ErrorReport(title: ErrorReportTitle.request, body: fullStr)
                    Prov.errorProvider.reportError(errorReport)
                }
            }

            func logRequesstError(_ msg: String) {
                logRequesstWarningOrError(msg, isWarning: false, reportToServer: true)
            }
            
            func logRequesstWarning(_ msg: String) {
                logRequesstWarningOrError(msg, isWarning: true, reportToServer: false)
            }
            
            func logRequesstErrorNoServer(_ msg: String) {
                logRequesstWarningOrError(msg, isWarning: false, reportToServer: false)
            }
            
//            QL1("method: \(request?.HTTPMethod), response: \(responseMaybe)")
            if let response = responseMaybe {
                
                let statusCode = response.statusCode
                
                if statusCode >= 200 && statusCode < 300 {
                    let JSONSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
                    let JSON = JSONSerializer.serializeResponse(request, response, data, error)
                    
                    switch JSON {
                    case .success(let dataObjAny):
                        
                        let dataObj = dataObjAny as AnyObject
                        
//                        QL1("JSON (request \(request?.HTTPMethod), \(request?.URL): \(dataObj)")

                        let statusInt = dataObj.value(forKeyPath: "status") as! Int
                        if let status = RemoteStatusCode(rawValue: statusInt) {
                            
                            // App version check. Note that this doesn't affect processing the rest of the response, not even if the fields are missing. In the future we may prefer to trigger an .Unknown if the fields are missing and not continue processing response.
                            if let minRequiredAppVersion = dataObj.value(forKeyPath: "minr") as? Int, let minAdvisedAppVersion = dataObj.value(forKeyPath: "mina") as? Int {
                                if let appVersion = AppInfo.CFBundleVersion {
                                    QL1("Response app version, required: \(minRequiredAppVersion), min advised: \(minAdvisedAppVersion), app version: \(appVersion)")
                                    
                                    func isInvalidAppVersion() -> Bool {
                                       return appVersion < minRequiredAppVersion
                                    }

                                    // App delegate shows version popups. The reason we don't do this with default controller error handling is mainly .ShowShouldUpdateAppDialog - here we want to process the response normally. The popup is only a reminder, not related with success/error. So we would have to implement centralized functionality to process additional status besides success/errors in order to show this popup.
                                    // For .ShowMustUpdateAppDialog it's not really necessary to use the AppDelegate - this is practically an error and we could adjust the controller error handler to show the confirmation alert in this case, but we do it in AppDelegate just to be consistent with .ShowShouldUpdateAppDialog
                                    mainQueue {
                                        if isInvalidAppVersion() {
                                            Notification.send(Notification.ShowMustUpdateAppDialog)
                                        } else if appVersion < minAdvisedAppVersion {
                                            Notification.send(Notification.ShowShouldUpdateAppDialog)
                                        }
                                    }
                                    
                                    // On invalid version, we return error status. The controller doesn't show error popup for this status (alrady handled by AppDelegate).
                                    if isInvalidAppVersion() {
                                        // Log out - in case user taps on "Update" but comes back
                                        Prov.userProvider.removeLoginToken()
                                        return Result.success(RemoteResult<T>(status: .mustUpdateApp))
                                    }
                                    
                                } else {
                                    QL4("Can't check min version: App has no bundle version")
                                }
                            } else {
                                QL4("Server didn't send app minr and/or mina app version, data: \(dataObj)")
                            }

                            if status == .success || status == .invalidParameters || status == .sizeLimit || status == .blacklisted {
                                
                                if status == .success {
                                    if let dataAny = dataObj.value(forKeyPath: "data") {
                                        let data = dataAny as AnyObject
                                        
                                        if let sucessResult = dataParser(data, response) {
                                            let remoteResult = RemoteResult(status: status, sucessResult: sucessResult)
                                            return Result.success(remoteResult)
                                            
                                        } else {
                                            logRequesstError("Error parsing result object: \(data)")
                                            return Result.success(RemoteResult<T>(status: .parsingError))
                                        }
                                        
                                    } else { // the result has no data
                                        return Result.success(RemoteResult<T>(status: status))
                                    }
                                } else if status == .invalidParameters {
                                    if let dataAny = dataObj.value(forKeyPath: "data") {
                                        let data = dataAny as AnyObject
                                        
                                        if let invalidParametersObj = RemoteInvalidParametersResult(json: data) {
                                            logRequesstError("Invalid parameters: \(invalidParametersObj.debugDescription)")
                                            return Result.success(RemoteResult<T>(status: .invalidParameters, error: invalidParametersObj))
                                            
                                        } else {
                                            logRequesstError("Error parsing result object in invalid parameters response")
                                            return Result.success(RemoteResult<T>(status: .parsingError))
                                        }
                                        
                                    } else { // the result has no data
                                        logRequesstError("No data key: \(dataObj)")
                                        return Result.success(RemoteResult<T>(status: .parsingError))
                                    }
                                    
                                } else if status == .sizeLimit {
                                    if let errorAny = dataObj.value(forKeyPath: "error") { // TODO more generic implementation of error obj parsing? Maybe with other status too
                                        let error = errorAny as AnyObject
                                        
                                        if let maxSize = error as? Int {
                                            return Result.success(RemoteResult<T>(status: .sizeLimit, errorObj: maxSize))
                                            
                                        } else {
                                            logRequesstError("Error parsing error object in size limit response")
                                            return Result.success(RemoteResult<T>(status: .parsingError))
                                        }
                                        
                                    } else { // the result has no data
                                        logRequesstError("SizeLimit: unexpected format in invalid parameters response")
                                        return Result.success(RemoteResult<T>(status: .parsingError))
                                    }
                                    
                                } else if status == .blacklisted {
                                    logRequesstWarning("Blacklisted user")
                                    Prov.userProvider.removeLoginToken()
                                    mainQueue {
                                        Notification.send(Notification.LogoutUI)
                                    }
                                    return Result.success(RemoteResult<T>(status: status))
                                    
                                } else {
                                    logRequesstError("Forgot to handle a status in nested if: \(status)")
                                    return Result.success(RemoteResult<T>(status: .unknown))
                                }
                                
                            } else { // status != success
                                logRequesstWarning("Returned not success status: \(status)")
                                return Result.success(RemoteResult<T>(status: status))
                            }
                            
                        } else {
                            logRequesstError("Error: response: status flag not recognized: \(statusInt)")
                            return Result.success(RemoteResult<T>(status: .notRecognizedStatusFlag))
                        }
                        
                    case .failure(let error):
                        logRequesstError("Error serializing response: \(response), request: \(String(describing: request)), data: \(String(describing: data)), serializationError: \(error)")
                        return Result.success(RemoteResult<T>(status: .parsingError))
                    }
                    
                } else if statusCode == 401 {
                    logRequesstWarning("Unauthorized")
                    Prov.userProvider.removeLoginToken()
                    return Result.success(RemoteResult<T>(status: .notAuthenticated))
                    
                } else if statusCode == 400 {
                    logRequesstError("Bad request")
                    return Result.success(RemoteResult<T>(status: .badRequest))
                    
                } else if statusCode == 404 {
                    let str = request?.url.map{$0.absoluteString} ?? ""
                    logRequesstError("Action not found: \(String(describing: request?.httpMethod)) \(str)")
                    return Result.success(RemoteResult<T>(status: .actionNotFound))
                    
                } else if statusCode == 415 {
                    logRequesstError("Unsupported media type")
                    return Result.success(RemoteResult<T>(status: .unsupportedMediaType))
                    
                } else if statusCode == 500 {
                    logRequesstError("Internal server error: \(response)")
                    return Result.success(RemoteResult<T>(status: .internalServerError))
                    
                } else {
                    logRequesstError("Error: Not handled status code: \(statusCode)")
                    return Result.success(RemoteResult<T>(status: .notHandledHTTPStatusCode))
                }
                
            } else { // So far this happened when the server was not reachable. This will be executed but the error is handled in the completionHandler block (Alamofire passes us a .Failure in this case). We return here .ResponseIsNil only as result of the serialization.
                logRequesstErrorNoServer("Error: response == nil")
                
                if let error = error {
                    if error._code == -1004 {  // iOS returns -1004 both when server is down/url not reachable and when client doesn't have an internet connection. Needs maybe internet connection check to differentiate.
                        logRequesstErrorNoServer("Error calling remote service, error: \(error)")
                            return Result.success(RemoteResult<T>(status: .serverNotReachable))
                    } else {
                        logRequesstError("Error calling remote service, error: \(error)")
                        return Result.success(RemoteResult<T>(status: .unknownServerCommunicationError))
                    }
                } else {
                    return Result.success(RemoteResult<T>(status: .responseIsNil))
                }
            }
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: { response in

            let remoteResult: RemoteResult<T> = {
                switch response.result {
                    
                // TODO check if this error handling is still really necessary, after the alamo fire update, we had to put it in the parsing (above) so probably this is now never used.
                case .success(let remoteResult):
                    return remoteResult
                case .failure(let error):
                    QL4("Error calling remote service, error: \(error)")
                    if error._code == -1004 {  // iOS returns -1004 both when server is down/url not reachable and when client doesn't have an internet connection. Needs maybe internet connection check to differentiate.
                        return RemoteResult<T>(status: .serverNotReachable)
                    } else {
                        return RemoteResult<T>(status: .unknownServerCommunicationError)
                    }
                }
            }()
            
            completionHandler(self.request, response, remoteResult)
        })
    }
}

public protocol ResponseCollectionSerializable {
    static func collection(_ representation: [AnyObject]) -> [Self]?
}
