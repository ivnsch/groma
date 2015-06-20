//
//  Try.swift
//  shoppin
//
//  Created by ischuetz on 12/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

// TODO use this in swift 2
//enum Try<T> {
//    case Success(T)
//    case Error(NSError)
//}
import Foundation

final public class Try<T> {
    public let success: T?
    public let error: NSError?

    var isSuccess: Bool {
        return self.success != nil && self.error == nil
    }
    
    public convenience init(_ success: T) {
        self.init(success: success, error: nil)
    }

    public convenience init(_ error: NSError?) {
        self.init(success: nil, error: error)
    }
    
    private init(success: T?, error: NSError?) {
        self.success = success
        self.error = error
    }
}