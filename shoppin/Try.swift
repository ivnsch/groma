//
//  Try.swift
//  shoppin
//
//  Created by ischuetz on 12/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

enum Try<T, U> {
    case Success(T)
    case Error(U)
}
