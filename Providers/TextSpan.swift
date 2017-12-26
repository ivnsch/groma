//
//  TextSpan.swift
//  Providers
//
//  Created by Ivan Schuetz on 26.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import Foundation

public enum TextAttribute: Int, Equatable {
    case bold = 0
//    , fontSize(CGFloat)

    public static func ==(lhs: TextAttribute, rhs: TextAttribute) -> Bool {
        switch (lhs, rhs) {
//        case (let .fontSize(size1), let .fontSize(size2)):
//            return size1 == size2
        case (.bold, .bold):
            return true
//        default:
//            return false
        }
    }
}

public struct TextSpan: Equatable {
    
    public let start: Int
    public let length: Int
    public let attribute: TextAttribute

    public var end: Int {
        return start + length
    }

    public init(range: NSRange, attribute: TextAttribute) {
        start = range.location
        length = range.length
        self.attribute = attribute
    }

    public init(start: Int, length: Int, attribute: TextAttribute) {
        self.start = start
        self.length = length
        self.attribute = attribute
    }

    public var nsRange: NSRange {
        return NSRange(location: start, length: length)
    }

    public func intersection(span: TextSpan) -> NSRange {
        return nsRange.myIntersection(range: span.nsRange)
    }

    public enum SubstractSubrangeResult {
        case one(NSRange), two(NSRange, NSRange),
        somethingWentWrong // TODO review code and reorganize such that this case is not necessary
    }

    public func substract(subrange: NSRange) -> SubstractSubrangeResult {

        let range = nsRange

        let intersection = range.myIntersection(range: subrange)

        // No intersection - return range
        if intersection.length <= 0 {
            return .one(range)
        }

        // subrange is bigger or equal to range
        if intersection.length == range.length {
            return .one(intersection)
        }

        // Get parts before and after intersection (note: assumes subrange is inside range (start/inside/end))
        let p1 = NSRange(location: range.location, length: subrange.location - range.location)
        let p2 = NSRange(location: subrange.end, length: range.end - subrange.end)

        let p1Length = p1.length
        let p2Length = p2.length

        // There's a part of range before subrange and another after
        if p1Length > 0 && p2Length > 0 {
            return .two(p1, p2)

            // There's a part of range before (subrange is at the end)
        } else if p1Length > 0 {
            return .one(p1)

            // There's a part of range after (subrange is at start)
        } else if p2Length > 0 {
            return .one(p2)

            // Shouldn't happen? if p1 and p2 length <= 0 it means intersection length == range.length which we catch at the start of this method
        } else {
            print("Invalid?: p1: \(p1), p2: \(p2)")
            return .somethingWentWrong
        }
    }

    public static func ==(lhs: TextSpan, rhs: TextSpan) -> Bool {
        return lhs.start == rhs.start && lhs.length == rhs.length && lhs.attribute == rhs.attribute
    }
}
