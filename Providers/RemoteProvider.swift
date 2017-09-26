//
//  RemoteProvider.swift
//  shoppin
//
//  Created by ischuetz on 28/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire
import Reachability


class RemoteProvider {

    /**
     * Not authenticated request with parameter dictionary, object response.
     */
    class func request<T: ResponseObjectSerializable>(_ method: HTTPMethod, _ url: String, _ params: [String: AnyObject]? = nil, handler: @escaping (RemoteResult<T>) -> ()) {
        onConnected(handler) {
            _ = Alamofire.request(url, method: method, parameters: params, encoding: JSONEncoding.default).responseMyObject {(request, _, result: RemoteResult<T>) in
                handler(result)
            }
        }
    }
    
    /**
     * Authenticated request with parameter dictionary, object response
     */
    class func authenticatedRequest<T: ResponseObjectSerializable>(_ method: HTTPMethod, _ url: String, _ params: [String: AnyObject]? = nil, handler: @escaping (RemoteResult<T>) -> ()) {
        onConnectedAndLoggedIn(handler) {
            _ = AlamofireHelper.authenticatedRequest(method, url, params).responseMyObject {(request, _, result: RemoteResult<T>) in
                handler(result)
            }
        }
    }

    /**
     * Authenticated request with parameter dictionary, object array response
     */
    class func authenticatedRequestArray<T: ResponseObjectSerializable>(_ method: HTTPMethod, _ url: String, _ params: [String: AnyObject]? = nil, handler: @escaping (RemoteResult<[T]>) -> ()) {
        onConnectedAndLoggedIn(handler) {
            _ = AlamofireHelper.authenticatedRequest(method, url, params).responseMyArray {(request, _, result: RemoteResult<[T]>) in
                handler(result)
            }
        }
    }
    
    /**
     * Authenticated request with parameter dictionary, timestamp response
     */
    class func authenticatedRequestTimestamp(_ method: HTTPMethod, _ url: String, _ params: [String: AnyObject]? = nil, handler: @escaping (RemoteResult<Int64>) -> ()) {
        onConnectedAndLoggedIn(handler) {
            _ = AlamofireHelper.authenticatedRequest(method, url, params).responseMyTimestamp {(request, _, result: RemoteResult<Int64>) in
                handler(result)
            }
        }
    }

    /**
     * Authenticated request with parameter array, timestamp response
     */
    class func authenticatedRequestArrayParamsTimestamp(_ method: HTTPMethod, _ url: String, _ params: [[String: AnyObject]], handler: @escaping (RemoteResult<Int64>) -> Void) {
        onConnectedAndLoggedIn(handler) {
            var request = buildRequest(method, url: url)
            do {
                // Alamofhire's short version currently doesn't support array parameter, so we need this
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
                _ = Alamofire.request(request).responseMyTimestamp {(request, _, result: RemoteResult<Int64>) in
                    handler(result)
                }
            } catch _ as NSError {
                handler(RemoteResult(status: .clientParamsParsingError))
            } catch _ {
                logger.e("Not handled error, returning .Unknown")
                handler(RemoteResult(status: .unknown))
            }
        }
    }
    
    /**
     * Authenticated request with parameter array, object array response
     */
    class func authenticatedRequestArray<T: ResponseObjectSerializable>(_ method: HTTPMethod, _ url: String, _ params: [[String: AnyObject]], handler: @escaping (RemoteResult<[T]>) -> Void) {
        onConnectedAndLoggedIn(handler) {
            var request = buildRequest(method, url: url)
            do {
                // Alamofire's short version currently doesn't support array parameter, so we need this
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
                _ = Alamofire.request(request).responseMyArray {(request, _, result: RemoteResult<[T]>) in
                    handler(result)
                }
            } catch _ as NSError {
                handler(RemoteResult(status: .clientParamsParsingError))
            } catch _ {
                logger.e("Not handled error, returning .Unknown")
                handler(RemoteResult(status: .unknown))
            }
        }
    }
    
    /**
     * Authenticated request with parameter array, object response
     */
    class func authenticatedRequest<T: ResponseObjectSerializable>(_ method: HTTPMethod, _ url: String, _ params: [[String: AnyObject]], handler: @escaping (RemoteResult<T>) -> Void) {
        onConnectedAndLoggedIn(handler) {
            var request = buildRequest(method, url: url)
            do {
                // Alamofire's short version currently doesn't support array parameter, so we need this
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
                _ = Alamofire.request(request).responseMyObject {(request, _, result: RemoteResult<T>) in
                    handler(result)
                }
            } catch _ as NSError {
                handler(RemoteResult(status: .clientParamsParsingError))
            } catch _ {
                logger.e("Not handled error, returning .Unknown")
                handler(RemoteResult(status: .unknown))
            }
        }
    }
    
    /**
    * Creates a request with passed method an url, with headers: json content type, auth token if existent, did if existent.
    * TODO! refactor with the request builders in AlamofireHelper - we should have only 1 method at least setting the headers.
    */
    fileprivate class func buildRequest(_ method: HTTPMethod, url: String) -> URLRequest {

        logger.v("\(method) \(url), parameters: TODO refactor this") // see todo in method signature

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AccessTokenHelper.loadToken() {
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
        if let deviceId: String = PreferencesManager.loadPreference(PreferencesManagerKey.deviceId) {
            request.setValue(deviceId, forHTTPHeaderField: "did")
        }
        return request as URLRequest
    }

    /**
    * Calls onConnected if user has an internet connection. Otherwise calls elseHandler with corresponding status.
    */
    fileprivate class func onConnected<T: Any>(_ elseHandler: (RemoteResult<T>) -> (), onConnected: VoidFunction) {
        if ConnectionProvider.connected {
            logger.v("Is connected")
            onConnected()
        } else {
            logger.v("Is not connected")
            elseHandler(RemoteResult(status: .noConnection))
        }
    }
    
    /**
    * Calls onConnectedAndLoggedIn if user has an internet connection and is logged in. Otherwise calls elseHandler with corresponding status.
    */
    fileprivate class func onConnectedAndLoggedIn<T: Any>(_ elseHandler: (RemoteResult<T>) -> (), onConnectedAndLoggedIn: VoidFunction) {
        onConnected(elseHandler) {
            if Prov.userProvider.hasLoginToken {
                logger.v("Has login token")
                onConnectedAndLoggedIn()
            } else {
                logger.v("Has no login token")
                elseHandler(RemoteResult(status: .notLoggedIn))
            }
        }
    }
}
