//
//  AlamofireExtensions.swift
//  shoppin
//
//  Created by ischuetz on 22/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire

enum RemoteStatusCode: Int {
    case Success = 1
    case AlreadyExists = 4
    case Unknown = 100
    case ParsingError = 101
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
        self.sucessResult = sucessResult
        self.errorMsg = errorMsg
    }
    
    public var debugDescription: String {
        return "{\(self.dynamicType) status: \(self.status), model: \(self.sucessResult), errorMsg: \(self.errorMsg)}"
    }
}


extension Alamofire.Request {

    public func responseMyObject<T: ResponseObjectSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, RemoteResult<T>, NSError?) -> Void) -> Self {
        let serializer: Serializer = { (request, response, data) in
            
            println("response: \(response)")
            
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
            
            println("JSON: \(JSON)")
            
            if response != nil && JSON != nil {
                
                let statusInt = JSON!.valueForKeyPath("status") as! Int
                if let status = RemoteStatusCode(rawValue: statusInt) {
                    if status == .Success {
                        
                        if let data: AnyObject = JSON!.valueForKeyPath("data") {
                            
                            if let sucessResult = T(response: response!, representation: data) {
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
                    let remoteResult = RemoteResult<T>(status: .Unknown)
                    return (remoteResult, nil)
                }
                
            } else {
                println("Error: wrong reponse format: \(response)")
                let remoteResult = RemoteResult<T>(status: .Unknown)
                return (remoteResult, nil)
            }
        }
        
        return response(serializer: serializer, completionHandler: { (request, response, object, error) in
            completionHandler(request, response, object as! RemoteResult<T>, error)
        })
    }

    
    public func responseObject<T: ResponseObjectSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, T?, NSError?) -> Void) -> Self {
        let serializer: Serializer = { (request, response, data) in
            
            println("response: \(response)")
            
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
            
            println("JSON: \(JSON)")
            
            if response != nil && JSON != nil {
                return (T(response: response!, representation: JSON!), nil)
            } else {
                return (nil, serializationError)
            }
        }
        
        return response(serializer: serializer, completionHandler: { (request, response, object, error) in
            completionHandler(request, response, object as? T, error)
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