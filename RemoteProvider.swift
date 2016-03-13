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
import QorumLogs

class RemoteProvider {

    /**
     * Not authenticated request with parameter dictionary, object response.
     */
    class func request<T: ResponseObjectSerializable>(method: Alamofire.Method, _ url: String, _ params: [String: AnyObject]? = nil, handler: RemoteResult<T> -> ()) {
        onConnected(handler) {
            Alamofire.request(method, url, parameters: params, encoding: .JSON).responseMyObject {(request, _, result: RemoteResult<T>) in
                handler(result)
            }
        }
    }
    
    /**
     * Authenticated request with parameter dictionary, object response
     */
    class func authenticatedRequest<T: ResponseObjectSerializable>(method: Alamofire.Method, _ url: String, _ params: [String: AnyObject]? = nil, handler: RemoteResult<T> -> ()) {
        onConnectedAndLoggedIn(handler) {
            AlamofireHelper.authenticatedRequest(method, url, params).responseMyObject {(request, _, result: RemoteResult<T>) in
                handler(result)
            }
        }
    }

    /**
     * Authenticated request with parameter dictionary, object array response
     */
    class func authenticatedRequestArray<T: ResponseObjectSerializable>(method: Alamofire.Method, _ url: String, _ params: [String: AnyObject]? = nil, handler: RemoteResult<[T]> -> ()) {
        onConnectedAndLoggedIn(handler) {
            AlamofireHelper.authenticatedRequest(method, url, params).responseMyArray {(request, _, result: RemoteResult<[T]>) in
                handler(result)
            }
        }
    }
    
    /**
     * Authenticated request with parameter dictionary, timestamp response
     */
    class func authenticatedRequestTimestamp(method: Alamofire.Method, _ url: String, _ params: [String: AnyObject]? = nil, handler: RemoteResult<NSDate> -> ()) {
        onConnectedAndLoggedIn(handler) {
            AlamofireHelper.authenticatedRequest(method, url, params).responseMyTimestamp {(request, _, result: RemoteResult<NSDate>) in
                handler(result)
            }
        }
    }

    /**
     * Authenticated request with parameter array, timestamp response
     */
    class func authenticatedRequestArrayParamsTimestamp(method: Alamofire.Method, _ url: String, _ params: [[String: AnyObject]], handler: RemoteResult<NSDate> -> Void) {
        onConnectedAndLoggedIn(handler) {
            let request = buildRequest(method, url: url)
            do {
                // Alamofire's short version currently doesn't support array parameter, so we need this
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
                Alamofire.request(request).responseMyTimestamp {(request, _, result: RemoteResult<NSDate>) in
                    handler(result)
                }
            } catch _ as NSError {
                handler(RemoteResult(status: .ClientParamsParsingError))
            } catch _ {
                QL4("Not handled error, returning .Unknown")
                handler(RemoteResult(status: .Unknown))
            }
        }
    }
    
    /**
     * Authenticated request with parameter array, object array response
     */
    class func authenticatedRequestArray<T: ResponseObjectSerializable>(method: Alamofire.Method, _ url: String, _ params: [[String: AnyObject]], handler: RemoteResult<[T]> -> Void) {
        onConnectedAndLoggedIn(handler) {
            let request = buildRequest(method, url: url)
            do {
                // Alamofire's short version currently doesn't support array parameter, so we need this
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
                Alamofire.request(request).responseMyArray {(request, _, result: RemoteResult<[T]>) in
                    handler(result)
                }
            } catch _ as NSError {
                handler(RemoteResult(status: .ClientParamsParsingError))
            } catch _ {
                QL4("Not handled error, returning .Unknown")
                handler(RemoteResult(status: .Unknown))
            }
        }
    }
    
    /**
     * Authenticated request with parameter array, object response
     */
    class func authenticatedRequest<T: ResponseObjectSerializable>(method: Alamofire.Method, _ url: String, _ params: [[String: AnyObject]], handler: RemoteResult<T> -> Void) {
        onConnectedAndLoggedIn(handler) {
            let request = buildRequest(method, url: url)
            do {
                // Alamofire's short version currently doesn't support array parameter, so we need this
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
                Alamofire.request(request).responseMyObject {(request, _, result: RemoteResult<T>) in
                    handler(result)
                }
            } catch _ as NSError {
                handler(RemoteResult(status: .ClientParamsParsingError))
            } catch _ {
                QL4("Not handled error, returning .Unknown")
                handler(RemoteResult(status: .Unknown))
            }
        }
    }
    
    /**
    * Creates a request with passed method an url, with headers: json content type, auth token if existent, did if existent.
    * TODO! refactor with the request builders in AlamofireHelper - we should have only 1 method at least setting the headers.
    */
    private class func buildRequest(method: Alamofire.Method, url: String) -> NSMutableURLRequest {
        
        if QorumLogs.minimumLogLevelShown == 1 {
            QL1("\(method) \(url), parameters: TODO refactor this") // see todo in method signature
        }
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        
        let maybeToken = valet?.stringForKey(KeychainKeys.token)
        
        if let token = maybeToken {
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
        if let deviceId: String = PreferencesManager.loadPreference(PreferencesManagerKey.deviceId) {
            request.setValue(deviceId, forHTTPHeaderField: "did")
        }
        return request
    }

    /**
    * Calls onConnected if user has an internet connection. Otherwise calls elseHandler with corresponding status.
    */
    private class func onConnected<T: Any>(elseHandler: RemoteResult<T> -> (), onConnected: VoidFunction) {
        if ConnectionProvider.connected {
            QL1("Is connected")
            onConnected()
        } else {
            QL1("Is not connected")
            elseHandler(RemoteResult(status: .NoConnection))
        }
    }
    
    /**
    * Calls onConnectedAndLoggedIn if user has an internet connection and is logged in. Otherwise calls elseHandler with corresponding status.
    */
    private class func onConnectedAndLoggedIn<T: Any>(elseHandler: RemoteResult<T> -> (), onConnectedAndLoggedIn: VoidFunction) {
        onConnected(elseHandler) {
            if Providers.userProvider.hasLoginToken {
                QL1("Has login token")
                onConnectedAndLoggedIn()
            } else {
                QL1("Has no login token")
                elseHandler(RemoteResult(status: .NotLoggedIn))
            }
        }
    }
}