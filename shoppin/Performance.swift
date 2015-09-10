//
//  Performance.swift
//  shoppin
//
//  Created by ischuetz on 10/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

func measure(title: String, block: (() -> ()) -> ()) {
    
    let startTime = CFAbsoluteTimeGetCurrent()
    
    block {
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("\(title):: Time: \(timeElapsed)")
    }
}