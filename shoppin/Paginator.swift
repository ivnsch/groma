//
//  Paginator.swift
//  shoppin
//
//  Created by ischuetz on 27/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class Paginator {
    let pageSize: Int
    private var currentIndex = 0
    
    var reachedEnd = false
    
    var isFirstPage: Bool {
        return currentIndex == 0
    }
    
    init(pageSize: Int) {
        self.pageSize = pageSize
    }
    
    var currentPage: NSRange {
        return NSRange(location: currentIndex * pageSize, length: pageSize)
    }

    func advance() {
        self.currentIndex += 1
    }
    
    func update(resultCount: Int) {
        if resultCount < pageSize || resultCount == 0 {
            reachedEnd = true
        } else {
            advance()
        }
    }
    
    func reset() {
        currentIndex = 0
        reachedEnd = false
    }
}