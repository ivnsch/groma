//
//  ProvResult.swift
//  Providers
//
//  Created by Ivan Schuetz on 24/01/2017.
//
//

import Foundation

public enum DatabaseError: Int {
    case unknown
}

enum ProvResult<T, V> {
    case ok(T)
    case err(V)
    
    @discardableResult func onOk(_ f: (T) -> Void) -> ProvResult<T, V> {
        switch self {
        case .ok(let result): f(result)
            fallthrough
        default: return self
        }
    }
    
    @discardableResult func onErr(_ f: (V) -> Void) -> ProvResult<T, V> {
        switch self {
        case .err(let error): f(error)
            fallthrough
        default: return self
        }
    }
    
    func map<U>(_ f: (T) -> U) -> ProvResult<U, V> {
        switch self {
        case .ok(let result): return .ok(f(result))
        case .err(let error): return .err(error)
        }
    }
    
    func flatMap<U>(_ f: (T) -> ProvResult<U, V>) -> ProvResult<U, V> {
        switch self {
        case .ok(let result): return f(result)
        case .err(let error): return .err(error)
        }
    }
    
    @discardableResult func always(_ f: () -> Void) -> ProvResult<T, V> {
        f()
        return self
    }
    
    func getOk() -> T? {
        switch self {
        case .ok(let result): return result
        default: return nil
        }
    }
    
    func getErr() -> V? {
        switch self {
        case .err(let error): return error
        default: return nil
        }
    }
    
    func join<Y>(result: ProvResult<Y, V>) -> ProvResult<(T, Y), V> {
        return flatMap {selfSuccessResult in
            let resultResult = result.map({resultSuccessResult in
                (selfSuccessResult, resultSuccessResult)
            })
            return resultResult
        }
    }
    
    static func seq<T, U>(results: [ProvResult<T, U>]) -> ProvResult<[T], U>{

        var oks: [T] = []
        
        for result in results {
            if let ok = result.getOk() {
                oks.append(ok)
            } else {
                return .err(result.getErr()!)
            }
        }
        return .ok(oks)
    }
}
