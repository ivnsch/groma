//
//  AsyncUtils.swift
//  shoppin
//
//  Created by ischuetz on 17/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

func background<T>(_ background: @escaping (Void) -> T, onFinish: @escaping (T) -> Void) {
    DispatchQueue.global(qos: .background).async {
        let t: T = background()
        mainQueue {
            onFinish(t)
        }
    }
}

func mainQueue(_ f: @escaping VoidFunction) {
    DispatchQueue.main.async(execute: {
        f()
    })
}
