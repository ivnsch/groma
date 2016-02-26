//
//  AlamofireExtensions.swift
//  shoppin
//
//  Created by ischuetz on 22/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire
import Valet
import QorumLogs

// Representation of status code related with remote responses
// Can represent a HTTP status code sent by the server, a status flag in the JSON response, or a client-side error related with the processing of the remote response
// 
// Not handled JSON as well as HTTP status (different than 200) should be mapped to .Unknown
//
// Note that this doesn't contain any success HTTP status codes as this is currently not necessary, either it's an error, or if not, we have a JSON object where we can query the JSON status flag which is sent in all JSON responses. Improvement: TODO: use HTTP status codes instead of JSON flag wherever possible - e.g. use 204 to indicate a success response with no content. So we don't have to parse the JSON. Currently this is being sent using JSON status flag "NotFound" (which represents -maybe unexpectedly- empty result, no 404).
enum RemoteStatusCode: Int {
    
    // JSON FLAG
    case Success = 1
    case InvalidParameters = 2

    case AlreadyExists = 4
    case NotFound = 5
    case InvalidCredentials = 6
    case SizeLimit = 7
    case Unknown = 100 // Note that, like above cases this also is sent as status by the server - don't change raw value
 
    // HTTP
    case NotAuthenticated = 401
    case BadRequest = 400 // e.g. post request with wrong json
    case ActionNotFound = 404
    case UnsupportedMediaType = 415
    case InternalServerError = 500
    
    // Client generated
    case ParsingError = 10001
    case NotRecognizedStatusFlag = 10002
    case NoJson = 10003
    case NotHandledHTTPStatusCode = 10004
    case ResponseIsNil = 10005
    case ServerNotReachable = 10006 // This is currently both server is down and no internet connection (detected when doing the request, opposed to .NoConnection).
    case UnknownServerCommunicationError = 10007 // Communication errors other than .ServerNotReachable
    case ClientParamsParsingError = 10008 // This should really not happen, but the serialization for some requests needs do catch so for overall consistency in catch we return this error
    case NoConnection = 10009 // Used when we detect in advance that there's no connectivity and don't proceed making the request. When this is not used, the execution of a request without a connection results in .ServerNotReachable
    case NotLoggedIn = 10010 // Normally same meaning as .NotAuthenticated - difference is that .NotAuthenticated is determined by the server
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


final class RemoteValidationError: CustomDebugStringConvertible {
    let msg: String
    let args: [String]

    init?(json: AnyObject) {
        msg = json.valueForKeyPath("message") as! String
        args = json.valueForKeyPath("args") as! [String]
    }
    
    var debugDescription: String {
        return "[msg: \(msg), args: \(args)]"
    }
}

final class RemotePathValidationError: CustomDebugStringConvertible {
    let path: String
    let validationErrors: [RemoteValidationError]
    
    init?(json: AnyObject) {
        path = json.valueForKeyPath("path") as! String
        
        let validationErrorsObjs = json.valueForKeyPath("validationErrors") as! [AnyObject]
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
    
    var debugDescription: String {
        return "[path: \(path), errors: \(validationErrors)]"
    }
}

final class RemoteInvalidParametersResult
//: CustomDebugStringConvertible for some reason this causes a compiler error in other classes so for now commented, no time to investigate
{
    let pathErrors: [RemotePathValidationError]

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
public class NoOpSerializable: ResponseObjectSerializable {
    @objc required public init?(representation: AnyObject) {}
}


public class RemoteResult<T>: CustomDebugStringConvertible {
    
    let status: RemoteStatusCode
    
    // Callers can assume that if successResult != nil, status == .Success. If the reponse's status is != .Success no data will be parsed and subsequently successResult not set.
    let successResult: T?
    
    let error: RemoteInvalidParametersResult? // TODO more generic error field, maybe together with errorObj
    
    let errorObj: Any? // TODO type safe error object, see also TODO of error above
    
    var success: Bool {
        return self.status == .Success
    }
    
    convenience init(status: RemoteStatusCode, sucessResult: T) {
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
    
    private init(status: RemoteStatusCode, sucessResult: T?, error: RemoteInvalidParametersResult?, errorObj: Any?) {
        self.status = status
        self.successResult = sucessResult
        self.error = error
        self.errorObj = errorObj
    }
    
    public var debugDescription: String {
        return "{\(self.dynamicType) status: \(status), model: \(successResult), error: \(error), errorObj: \(error)}"
    }
}

// This would have been an extension if "Alamofire" wasn't only a namespace...
// The idea was to be called like Alamofire.request
struct AlamofireHelper {
    
    static func authenticatedRequest(method: Alamofire.Method, _ url: String, _ parameters: [String: AnyObject]? = nil) -> Request {

//        QL1("method: \(method), url: \(url), parameters: \(parameters)")
        
//        if let pars = parameters {
//            let dataExample: NSData = NSKeyedArchiver.archivedDataWithRootObject(pars)
//            let mb = Float(dataExample.length) / Float(1024) / Float(1024)
//            QL1("size: \(mb)")
//            QL1("size dict: \(pars.count)")
//        }
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        
        let maybeToken = valet?.stringForKey(KeychainKeys.token)
        
        let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        mutableURLRequest.HTTPMethod = method.rawValue
        
        if let token = maybeToken {
//            QL1("Setting the token header: \(token)")
            mutableURLRequest.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
        if let deviceId: String = PreferencesManager.loadPreference(PreferencesManagerKey.deviceId) {
            mutableURLRequest.setValue(deviceId, forHTTPHeaderField: "did")
        }
        
        // TODO: server: when encoding is not supported the response is nil! It should send a valid response. Happened testing listItems (GET) with JSON encoding
        let encoding = method == .GET ? Alamofire.ParameterEncoding.URL : Alamofire.ParameterEncoding.JSON
            
        let request: NSURLRequest = encoding.encode(mutableURLRequest, parameters: parameters).0
        
        return Alamofire.request(request)
    }
    
    static func authenticatedRequest(method: Alamofire.Method, _ url: String, _ parameters: [[String: AnyObject]]) -> Request {
        
//        QL1("method: \(method), url: \(url), parameters: \(parameters)")
        
        // this is handled differently because the parameters are an array and default request in alamofire doesn't support this (the difference is the request.HTTPBody line)
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        
        let maybeToken = valet?.stringForKey(KeychainKeys.token)
        
        if let token = maybeToken {
//            QL1("Setting the token header: \(token)")
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
        if let deviceId: String = PreferencesManager.loadPreference(PreferencesManagerKey.deviceId) {
            request.setValue(deviceId, forHTTPHeaderField: "did")
        }
        
        // TODO review, force try parameter serialization. For now like this because there's no known reason why this would fail, and simplifies code significantly
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(parameters, options: [])
        return Alamofire.request(request)
    }
}


public protocol ResponseObjectSerializable2 {
    init?(response: NSHTTPURLResponse, representation: AnyObject)
}

extension Request {
    public func responseObject<T: ResponseObjectSerializable2>(completionHandler: Response<T, NSError> -> Void) -> Self {
        let responseSerializer = ResponseSerializer<T, NSError> { request, response, data, error in
            guard error == nil else { return .Failure(error!) }
            
            let JSONResponseSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let result = JSONResponseSerializer.serializeResponse(request, response, data, error)
            
            switch result {
            case .Success(let value):
                if let
                    response = response,
                    responseObject = T(response: response, representation: value)
                {
                    return .Success(responseObject)
                } else {
                    let failureReason = "JSON could not be serialized into response object: \(value)"
                    let error = Error.errorWithCode(.JSONSerializationFailed, failureReason: failureReason)
                    return .Failure(error)
                }
            case .Failure(let error):
                return .Failure(error)
            }
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}


extension Alamofire.Request {

    public func responseMyArray<T: ResponseObjectSerializable>(completionHandler: (NSURLRequest?, Response<RemoteResult<[T]>, NSError>?, RemoteResult<[T]>) -> Void) -> Self {

        let dataParser: (AnyObject, NSHTTPURLResponse) -> ([T]?) = {data, response in
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
    
    
    public func responseMyObject<T: ResponseObjectSerializable>(completionHandler: (NSURLRequest?, Response<RemoteResult<T>, NSError>?, RemoteResult<T>) -> Void) -> Self {
        
        let dataParser: (AnyObject, NSHTTPURLResponse) -> (T?) = {data, response in
            return T(representation: data)
        }
        
        return self.responseHandler(dataParser, completionHandler: completionHandler)
    }
    
    
    // Common method to parse json object and array
    private func responseHandler<T>(dataParser: (AnyObject, NSHTTPURLResponse) -> (T?), completionHandler: (NSURLRequest?, Response<RemoteResult<T>, NSError>?, RemoteResult<T>) -> Void) -> Self {

        let responseSerializer = ResponseSerializer<RemoteResult<T>, NSError> { request, responseMaybe, data, error in
            
//            print("method: \(request?.HTTPMethod), response: \(responseMaybe)")
            if let response = responseMaybe {
                
                let statusCode = response.statusCode
                
                if statusCode >= 200 && statusCode < 300 {
                    let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
                    let JSON = JSONSerializer.serializeResponse(request, response, data, error)
                    
                    switch JSON {
                    case .Success(let dataObj):
                        
//                        print("JSON (request \(request?.HTTPMethod), \(request?.URL): \(dataObj)")

                        let statusInt = dataObj.valueForKeyPath("status") as! Int
                        if let status = RemoteStatusCode(rawValue: statusInt) {
                            if status == .Success || status == .InvalidParameters || status == .SizeLimit {
                                
                                if status == .Success {
                                    if let data: AnyObject = dataObj.valueForKeyPath("data") {
                                        
                                        if let sucessResult = dataParser(data, response) {
                                            let remoteResult = RemoteResult(status: status, sucessResult: sucessResult)
                                            return Result.Success(remoteResult)
                                            
                                        } else {
                                            QL4("Error parsing result object")
                                            return Result.Success(RemoteResult<T>(status: .ParsingError))
                                        }
                                        
                                    } else { // the result has no data
                                        return Result.Success(RemoteResult<T>(status: status))
                                    }
                                } else if status == .InvalidParameters {
                                    if let data: AnyObject = dataObj.valueForKeyPath("data") {
                                        
                                        if let invalidParametersObj = RemoteInvalidParametersResult(json: data) {
                                            QL4("Invalid parameters: \(invalidParametersObj.debugDescription)")
                                            return Result.Success(RemoteResult<T>(status: .InvalidParameters, error: invalidParametersObj))
                                            
                                        } else {
                                            QL4("Error parsing result object in invalid parameters response")
                                            return Result.Success(RemoteResult<T>(status: .ParsingError))
                                        }
                                        
                                    } else { // the result has no data
                                        QL4("Error: AlamofireHelper.responseHandler: unexpected format in invalid parameters response")
                                        return Result.Success(RemoteResult<T>(status: .ParsingError))
                                    }
                                    
                                } else if status == .SizeLimit {
                                    if let error: AnyObject = dataObj.valueForKeyPath("error") { // TODO more generic implementation of error obj parsing? Maybe with other status too
                                        if let maxSize = error as? Int {
                                            return Result.Success(RemoteResult<T>(status: .SizeLimit, errorObj: maxSize))
                                            
                                        } else {
                                            QL4("Error parsing error object in size limit response")
                                            return Result.Success(RemoteResult<T>(status: .ParsingError))
                                        }
                                        
                                    } else { // the result has no data
                                        QL4("SizeLimit: unexpected format in invalid parameters response")
                                        return Result.Success(RemoteResult<T>(status: .ParsingError))
                                    }
                                    
                                } else {
                                    QL4("Forgot to handle a status in nested if: \(status)")
                                    return Result.Success(RemoteResult<T>(status: .Unknown))
                                }
                                
                            } else { // status != success
                                return Result.Success(RemoteResult<T>(status: status))
                            }
                            
                        } else {
                            QL4("Error: response: status flag not recognized: \(statusInt)")
                            return Result.Success(RemoteResult<T>(status: .NotRecognizedStatusFlag))
                        }
                        
                    case .Failure(let error):
                        QL4("Error serializing response: \(response), request: \(request), data: \(data), serializationError: \(error)")
                        return Result.Success(RemoteResult<T>(status: .ParsingError))
                    }
                    
                } else if statusCode == 401 {
                    QL4("Unauthorized")
                    Providers.userProvider.removeLoginToken()
                    return Result.Success(RemoteResult<T>(status: .NotAuthenticated))
                    
                } else if statusCode == 400 {
                    QL4("Bad request")
                    return Result.Success(RemoteResult<T>(status: .BadRequest))
                    
                } else if statusCode == 404 {
                    let str = request?.URL.map{$0} ?? ""
                    QL4("Action not found: \(request?.HTTPMethod) \(str)")
                    return Result.Success(RemoteResult<T>(status: .ActionNotFound))
                    
                } else if statusCode == 415 {
                    QL4("Unsupported media type")
                    return Result.Success(RemoteResult<T>(status: .UnsupportedMediaType))
                    
                } else if statusCode == 500 {
                    QL4("Internal server error: \(response)")
                    return Result.Success(RemoteResult<T>(status: .InternalServerError))
                    
                } else {
                    QL4("Error: Not handled status code: \(statusCode)")
                    return Result.Success(RemoteResult<T>(status: .NotHandledHTTPStatusCode))
                }
                
            } else { // So far this happened when the server was not reachable. This will be executed but the error is handled in the completionHandler block (Alamofire passes us a .Failure in this case). We return here .ResponseIsNil only as result of the serialization.
                QL4("Error: response == nil")
                if let error = error {
                    QL4("Error calling remote service, error: \(error)")
                    if error.code == -1004 {  // iOS returns -1004 both when server is down/url not reachable and when client doesn't have an internet connection. Needs maybe internet connection check to differentiate.
                            return Result.Success(RemoteResult<T>(status: .ServerNotReachable))
                    } else {
                        return Result.Success(RemoteResult<T>(status: .UnknownServerCommunicationError))
                    }
                } else {
                    return Result.Success(RemoteResult<T>(status: .ResponseIsNil))
                }
            }
        }

//        return response(responseSerializer: responseSerializer, completionHandler: { (response: Response<T, NSError>) in
        return response(responseSerializer: responseSerializer, completionHandler: { response in
//        return response(responseSerializer: responseSerializer, completionHandler: { (request: NSURLRequest?, response: NSHTTPURLResponse?, object: Result<RemoteResult<T>, NSError>) in

            let remoteResult: RemoteResult<T> = {
                switch response.result {
                    
                // TODO check if this error handling is still really necessary, after the alamo fire update, we had to put it in the parsing (above) so probably this is now never used.
                case .Success(let remoteResult):
                    return remoteResult
                case .Failure(let error):
                    QL4("Error calling remote service, error: \(error)")
                    if error.code == -1004 {  // iOS returns -1004 both when server is down/url not reachable and when client doesn't have an internet connection. Needs maybe internet connection check to differentiate.
                        return RemoteResult<T>(status: .ServerNotReachable)
                    } else {
                        return RemoteResult<T>(status: .UnknownServerCommunicationError)
                    }
                }
            }()
            
            completionHandler(self.request, response, remoteResult)
        })
    }
}

public protocol ResponseCollectionSerializable {
    static func collection(representation: AnyObject) -> [Self]?
}