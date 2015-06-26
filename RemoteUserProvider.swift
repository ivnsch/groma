//
//  RemoteUserProvider.swift
//  shoppin
//
//  Created by ischuetz on 22/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire

class RemoteUserProvider {
    
    // TODO refactor providers to return remoteresult. mapping to try and NSError seems nonsensical

    
    func login(loginData: LoginData, handler: Try<Bool> -> ()) {
        
        let parameters = [
            "email": loginData.email,
            "password": loginData.password
        ]
        
        Alamofire.request(.POST, Urls.register, parameters: parameters, encoding: .JSON).responseMyObject { (request, _, remoteResult: RemoteResult<NoOpSerializable>, error) in
            if remoteResult.success {
                handler(Try(true))
                
            } else {
                println("Response error, status: \(remoteResult.status), message: \(remoteResult.errorMsg)")
                handler(Try(remoteResult.error!))
            }
        }
    }
    
    
    func register(user: User, handler: Try<Bool> -> ()) {
        
        let parameters = self.toRequestParams(user)
        
        Alamofire.request(.POST, Urls.register, parameters: parameters, encoding: .JSON).responseMyObject { (request, _, remoteResult: RemoteResult<NoOpSerializable>, error) in
            if remoteResult.success {
                handler(Try(true))
                
            } else {
                println("Response error, status: \(remoteResult.status), message: \(remoteResult.errorMsg)")
                handler(Try(remoteResult.error!))
            }
        }
    }
    
    func logout(handler: Try<Bool> -> ()) {
        Alamofire.request(.POST, Urls.register, encoding: .JSON).responseMyObject { (request, _, remoteResult: RemoteResult<NoOpSerializable>, error) in
            if remoteResult.success {
                handler(Try(true))
                
            } else {
                println("Response error, status: \(remoteResult.status), message: \(remoteResult.errorMsg)")
                handler(Try(remoteResult.error!))
            }
        }
    }
    
    
    func toRequestParams(user: User) -> [String: AnyObject] {
        return [
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "password": user.password
        ]
    }

}
