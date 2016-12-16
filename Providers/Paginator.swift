//
//  Paginator.swift
//  shoppin
//
//  Created by ischuetz on 27/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class Paginator {
    public let pageSize: Int
    fileprivate var currentIndex = 0
    
    public var reachedEnd = false
    
    public var isFirstPage: Bool {
        return currentIndex == 0
    }
    
    public init(pageSize: Int) {
        self.pageSize = pageSize
    }
    
    public var currentPage: NSRange {
        return NSRange(location: currentIndex * pageSize, length: pageSize)
    }

    public func advance() {
        self.currentIndex += 1
    }
    
    public func update(_ resultCount: Int) {
        if resultCount < pageSize || resultCount == 0 {
            reachedEnd = true
        } else {
            advance()
        }
    }
    
    public func reset() {
        currentIndex = 0
        reachedEnd = false
    }
}
