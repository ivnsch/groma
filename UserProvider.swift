//
//  UserProvider.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol UserProvider {
   
    func login(loginData: LoginData, handler: Try<Bool> -> ())
    
    func register(user: User, handler: Try<Bool> -> ())
}
