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
    case BadRequest = 415 // e.g. post request without payload
    case InternalServerError = 500
    
    // Client generated
    case ParsingError = 10001
    case NotRecognizedStatusFlag = 10002
    case NoJson = 10003
    case NotHandledHTTPStatusCode = 10004
    case ResponseIsNil = 10005
    case ServerNotReachable = 10006 // This is currently both server is down and no internet connection
    case UnknownServerCommunicationError = 10007 // Communication errors other than .ServerNotReachable
    
}

extension RemoteStatusCode : Printable {
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

@objc public protocol ResponseObjectSerializable {
    init?(response: NSHTTPURLResponse, representation: AnyObject)
}

// dummy object to be able to use responseMyObject when there's no returned data
public class NoOpSerializable: ResponseObjectSerializable {
    @objc required public init?(response: NSHTTPURLResponse, representation: AnyObject) {}
}


public class RemoteResult<T>: DebugPrintable {
    
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
        
        var mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        mutableURLRequest.HTTPMethod = method.rawValue
        
        if let token = maybeToken {
            mutableURLRequest.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
        // TODO: server: when encoding is not supported the response is nil! It should send a valid response. Happened testing listItems (GET) with JSON encoding
        let encoding = method == .GET ? Alamofire.ParameterEncoding.URL : Alamofire.ParameterEncoding.JSON
            
        let request: NSURLRequest = encoding.encode(mutableURLRequest, parameters: parameters).0
        
        return Alamofire.request(request)
    }
}

extension Alamofire.Request {

    public func responseMyArray<T: ResponseObjectSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, RemoteResult<[T]>, NSError?) -> Void) -> Self {

        let dataParser: (AnyObject, NSHTTPURLResponse) -> ([T]?) = {data, response in
            var objs = [T]()
            for obj in data as! [AnyObject] {
                if let obj = T(response: response, representation: obj) {
                    objs.append(obj)
                    
                } else {
                    println("Error parsing obj: \(obj)")
                    return nil
                }
            }
            return objs
        }
        
        return self.responseHandler(dataParser, completionHandler: completionHandler)
    }
    
    
    public func responseMyObject<T: ResponseObjectSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, RemoteResult<T>, NSError?) -> Void) -> Self {
        
        let dataParser: (AnyObject, NSHTTPURLResponse) -> (T?) = {data, response in
            return T(response: response, representation: data)
        }
        
        return self.responseHandler(dataParser, completionHandler: completionHandler)
    }
    
    
    // Common method to parse json object and array
    private func responseHandler<T>(dataParser: (AnyObject, NSHTTPURLResponse) -> (T?), completionHandler: (NSURLRequest, NSHTTPURLResponse?, RemoteResult<T>, NSError?) -> Void) -> Self {

        let serializer: Serializer = { (request, responseMaybe, data) in
            
            println("method: \(request.HTTPMethod), response: \(responseMaybe)")
            
            if let response = responseMaybe {
                
                let statusCode = response.statusCode
                
                if statusCode >= 200 && statusCode < 300 {
                    let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
                    let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
                    
                    println("request: \(request), JSON: \(JSON)")
                    
                    if JSON != nil {
                        
                        let statusInt = JSON!.valueForKeyPath("status") as! Int
                        if let status = RemoteStatusCode(rawValue: statusInt) {
                            if status == .Success {
                                
                                if let data: AnyObject = JSON!.valueForKeyPath("data") {
                                    
                                    if let sucessResult = dataParser(data, response) {
                                        let remoteResult = RemoteResult(status: status, sucessResult: sucessResult)
                                        return (remoteResult, nil)
                                        
                                    } else {
                                        println("Error parsing success object: \(response)")
                                        
                                        
                                        let remoteResult = RemoteResult<T>(status: .ParsingError)
                                        return (remoteResult, nil)
                                    }
                                    
                                } else { // the result has no data
                                    let remoteResult = RemoteResult<T>(status: status)
                                    return (remoteResult, nil)
                                }
                                
                                
                            } else {
                                let remoteResult = RemoteResult<T>(status: status)
                                return (remoteResult, nil)
                            }
                            
                        } else {
                            println("Error parsing response: status flag not recognized: \(statusInt)")
                            let remoteResult = RemoteResult<T>(status: .NotRecognizedStatusFlag)
                            return (remoteResult, nil)
                        }
                        
                    } else {
                        println("Error: wrong reponse format: \(response)")
                        let remoteResult = RemoteResult<T>(status: .NoJson)
                        return (remoteResult, nil)
                    }
                    
                    
                    
                } else if statusCode == 401 {
                    println("Unauthorized")
                    let remoteResult = RemoteResult<T>(status: .NotAuthenticated)
                    return (remoteResult, nil)
                    
                } else if statusCode == 415 {
                    println("Bad request")
                    let remoteResult = RemoteResult<T>(status: .NotAuthenticated)
                    return (remoteResult, nil)
                    
                } else if statusCode == 500 {
                    println("Internal server error: \(response)")
                    let remoteResult = RemoteResult<T>(status: .InternalServerError)
                    return (remoteResult, nil)
                    
                } else {
                    println("Error: Not handled status code: \(statusCode)")
                    let remoteResult = RemoteResult<T>(status: .NotHandledHTTPStatusCode)
                    return (remoteResult, nil)
                }
                
            } else { // So far this happened only when the server was not reachable but now we are catching the error before using the serializable, so it's unexpected that this will be used
                println("Error: response == nil")
                let remoteResult = RemoteResult<T>(status: .ResponseIsNil)
                return (remoteResult, nil)
            }
        }
        
        return response(serializer: serializer, completionHandler: { (request, response, object, error) in
            
            let result: RemoteResult<T> = {
                
                if let e = error {
                    println("Error calling remote service: \(e)")
                    if e.code == -1004 {  // iOS returns -1004 when server is down/url not reachable and when client doesn't have an internet connection. Needs maybe internet connection check to differentiate.
                        return RemoteResult<T>(status: .ServerNotReachable)
                    } else {
                        return RemoteResult<T>(status: .UnknownServerCommunicationError)
                    }
                    
                } else {
                    return object as! RemoteResult<T>
                }
            }()
            
            completionHandler(request, response, result, error)
        })
        
        
    }
}


@objc public protocol ResponseCollectionSerializable {
    static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [Self]
}

extension Alamofire.Request {
    public func responseCollection<T: ResponseCollectionSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, [T]?, NSError?) -> Void) -> Self {
        let serializer: Serializer = { (request, response, data) in
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
            if response != nil && JSON != nil {
                return (T.collection(response: response!, representation: JSON!), nil)
            } else {
                return (nil, serializationError)
            }
        }
        
        return response(serializer: serializer, completionHandler: { (request, response, object, error) in
            completionHandler(request, response, object as? [T], error)
        })
    }
}