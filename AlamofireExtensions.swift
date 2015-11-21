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
    case Unknown = 100 // Note that, like above cases this also is sent as status by the server - don't change raw value
 
    // HTTP
    case NotAuthenticated = 401
    case BadRequest = 400 // e.g. post request with wrong json
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

//////////////////
// json

public protocol ResponseObjectSerializable {
    init?(response: NSHTTPURLResponse, representation: AnyObject)
}

// dummy object to be able to use responseMyObject when there's no returned data
public class NoOpSerializable: ResponseObjectSerializable {
    @objc required public init?(response: NSHTTPURLResponse, representation: AnyObject) {}
}


public class RemoteResult<T>: CustomDebugStringConvertible {
    
    let status: RemoteStatusCode
    
    // Callers can assume that if successResult != nil, status == .Success. If the reponse's status is != .Success no data will be parsed and subsequently successResult not set.
    let successResult: T?
    
    let errorMsg: String?
    
    var success: Bool {
        return self.status == .Success
    }
    
    convenience init(status: RemoteStatusCode, sucessResult: T) {
        self.init(status: status, sucessResult: sucessResult, errorMsg: nil)
    }
    
    convenience init(status: RemoteStatusCode, errorMsg: String?) {
        self.init(status: status, sucessResult: nil, errorMsg: errorMsg)
    }
    
    convenience init(status: RemoteStatusCode) {
        self.init(status: status, sucessResult: nil, errorMsg: nil)
    }
    
    private init(status: RemoteStatusCode, sucessResult: T?, errorMsg: String?) {
        self.status = status
        self.successResult = sucessResult
        self.errorMsg = errorMsg
    }
    
    public var debugDescription: String {
        return "{\(self.dynamicType) status: \(self.status), model: \(self.successResult), errorMsg: \(self.errorMsg)}"
    }
}

// This would have been an extension if "Alamofire" wasn't only a namespace...
// The idea was to be called like Alamofire.request
struct AlamofireHelper {
    
    static func authenticatedRequest(method: Alamofire.Method, _ url: String, _ parameters: [String: AnyObject]? = nil) -> Request {
     
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        
        let maybeToken = valet?.stringForKey(KeychainKeys.token)
        
        let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        mutableURLRequest.HTTPMethod = method.rawValue
        
        if let token = maybeToken {
            mutableURLRequest.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
        // TODO: server: when encoding is not supported the response is nil! It should send a valid response. Happened testing listItems (GET) with JSON encoding
        let encoding = method == .GET ? Alamofire.ParameterEncoding.URL : Alamofire.ParameterEncoding.JSON
            
        let request: NSURLRequest = encoding.encode(mutableURLRequest, parameters: parameters).0
        
        return Alamofire.request(request)
    }
    
    static func authenticatedRequest(method: Alamofire.Method, _ url: String, _ parameters: [[String: AnyObject]]) -> Request {
        
        // this is handled differently because the parameters are an array and default request in alamofire doesn't support this (the difference is the request.HTTPBody line)
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        
        let maybeToken = valet?.stringForKey(KeychainKeys.token)
        
        if let token = maybeToken {
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
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
                if let obj = T(response: response, representation: obj) {
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
            return T(response: response, representation: data)
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
                            if status == .Success {
                                
                                if let data: AnyObject = dataObj.valueForKeyPath("data") {
                                    
                                    if let sucessResult = dataParser(data, response) {
                                        let remoteResult = RemoteResult(status: status, sucessResult: sucessResult)
                                        return Result.Success(remoteResult)
                                        
                                    } else {
                                        print("Error parsing result object")
                                        return Result.Success(RemoteResult<T>(status: .ParsingError))
                                    }
                                    
                                } else { // the result has no data
                                    return Result.Success(RemoteResult<T>(status: status))
                                }
                                
                                
                            } else { // status != success
                                return Result.Success(RemoteResult<T>(status: status))
                            }
                            
                        } else {
                            print("Error: response: status flag not recognized: \(statusInt)")
                            return Result.Success(RemoteResult<T>(status: .NotRecognizedStatusFlag))
                        }
                        
                    case .Failure(let error):
                        print("Error serializing response: \(response), request: \(request), data: \(data), serializationError: \(error)")
                        return Result.Success(RemoteResult<T>(status: .ParsingError))
                    }
                    
                } else if statusCode == 401 {
                    print("Unauthorized")
                    return Result.Success(RemoteResult<T>(status: .NotAuthenticated))
                    
                } else if statusCode == 400 {
                    print("Bad request")
                    return Result.Success(RemoteResult<T>(status: .BadRequest))
                    
                } else if statusCode == 415 {
                    print("Unsupported media type")
                    return Result.Success(RemoteResult<T>(status: .UnsupportedMediaType))
                    
                } else if statusCode == 500 {
                    print("Internal server error: \(response)")
                    return Result.Success(RemoteResult<T>(status: .InternalServerError))
                    
                } else {
                    print("Error: Not handled status code: \(statusCode)")
                    return Result.Success(RemoteResult<T>(status: .NotHandledHTTPStatusCode))
                }
                
            } else { // So far this happened when the server was not reachable. This will be executed but the error is handled in the completionHandler block (Alamofire passes us a .Failure in this case). We return here .ResponseIsNil only as result of the serialization.
                print("Error: response == nil")
                return Result.Success(RemoteResult<T>(status: .ResponseIsNil))
            }
        }

//        return response(responseSerializer: responseSerializer, completionHandler: { (response: Response<T, NSError>) in
        return response(responseSerializer: responseSerializer, completionHandler: { response in
//        return response(responseSerializer: responseSerializer, completionHandler: { (request: NSURLRequest?, response: NSHTTPURLResponse?, object: Result<RemoteResult<T>, NSError>) in

            let remoteResult: RemoteResult<T> = {
                switch response.result {
                    
                case .Success(let remoteResult):
                    return remoteResult
                    
                case .Failure(let error):
                    print("Error calling remote service, error: \(error)")
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
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [Self]
}