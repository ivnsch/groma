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
    
    func login(loginData: LoginData, handler: RemoteResult<NoOpSerializable> -> ()) {
        
        let parameters = [
            "email": loginData.email,
            "password": loginData.password
        ]
        
        Alamofire.request(.POST, Urls.register, parameters: parameters, encoding: .JSON).responseMyObject { (request, _, remoteResult: RemoteResult<NoOpSerializable>, error) in
            handler(remoteResult)
        }
    }
    
    
    func register(user: User, handler: RemoteResult<NoOpSerializable> -> ()) {
        
        let parameters = self.toRequestParams(user)
        
        Alamofire.request(.POST, Urls.register, parameters: parameters, encoding: .JSON).responseMyObject { (request, _, remoteResult: RemoteResult<NoOpSerializable>, error) in
            handler(remoteResult)
        }
    }
    
    func logout(handler: RemoteResult<NoOpSerializable> -> ()) {
        Alamofire.request(.POST, Urls.register, encoding: .JSON).responseMyObject { (request, _, remoteResult: RemoteResult<NoOpSerializable>, error) in
            handler(remoteResult)
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
