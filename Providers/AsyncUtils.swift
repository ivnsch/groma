//
//  AsyncUtils.swift
//  shoppin
//
//  Created by ischuetz on 17/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public func background<T>(_ background: @escaping () -> T, onFinish: @escaping (T) -> Void) {
    DispatchQueue.global(qos: .background).async {
        let t: T = background()
        mainQueue {
            onFinish(t)
        }
    }
}

public func mainQueue(_ f: @escaping VoidFunction) {
    DispatchQueue.main.async(execute: {
        f()
    })
}
