//
//  RemoteProvider.swift
//  shoppin
//
//  Created by ischuetz on 28/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Valet
import Alamofire
import Reachability

class RemoteProvider {

    class func request<T: ResponseObjectSerializable>(method: Alamofire.Method, _ url: String, _ params: [String: AnyObject]? = nil, handler: RemoteResult<T> -> ()) {
        onConnectedOrError(handler) {
            Alamofire.request(method, url, parameters: params, encoding: .JSON).responseMyObject {(request, _, result: RemoteResult<T>) in
                handler(result)
            }
        }
    }
    
    class func authenticatedRequest<T: ResponseObjectSerializable>(method: Alamofire.Method, _ url: String, _ params: [String: AnyObject]? = nil, handler: RemoteResult<T> -> ()) {
        onConnectedOrError(handler) {
            AlamofireHelper.authenticatedRequest(method, url, params).responseMyObject {(request, _, result: RemoteResult<T>) in
                handler(result)
            }
        }
    }
    
    class func authenticatedRequestArray<T: ResponseObjectSerializable>(method: Alamofire.Method, _ url: String, _ params: [String: AnyObject]? = nil, handler: RemoteResult<[T]> -> ()) {
        onConnectedOrError(handler) {
            AlamofireHelper.authenticatedRequest(method, url, params).responseMyArray {(request, _, result: RemoteResult<[T]>) in
                handler(result)
            }
        }
    }
    
    class func authenticatedRequest<T: ResponseObjectSerializable>(method: Alamofire.Method, _ url: String, _ params: [[String: AnyObject]], handler: RemoteResult<T> -> ()) {

        onConnectedOrError(handler) {
            
            // Alamofire's short version currently doesn't support array parameter, so we need this
            
            let request = NSMutableURLRequest(URL: NSURL(string: Urls.listItems)!)
            request.HTTPMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
            
            let maybeToken = valet?.stringForKey(KeychainKeys.token)
            
            if let token = maybeToken {
                request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
            } // TODO if there's no token return status code to direct to login controller or something
            
            do {
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
                
                Alamofire.request(request).responseMyObject {(request, _, result: RemoteResult<T>) in
                    handler(result)
                }
                
            } catch _ as NSError {
                handler(RemoteResult(status: .ClientParamsParsingError))
            } catch _ {
                print("RemoteProvider.authenticatedRequest: Not handled error, returning .Unknown")
                handler(RemoteResult(status: .Unknown))
            }
        }
    }
    
    private class func onConnectedOrError<T: Any>(handler: RemoteResult<T> -> (), onConnected: VoidFunction) {
        if connected {
            onConnected()
        } else {
            handler(RemoteResult(status: .NoConnection))
        }
    }
    
    private class var connected: Bool {
        let reachability = Reachability.reachabilityForInternetConnection()
        let internetStatus = reachability.currentReachabilityStatus()
        return internetStatus != .NotReachable
    }
}