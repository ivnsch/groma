//
//  remoteResultHandler.swift
//  shoppin
//
//  Created by ischuetz on 27/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

// Maps remote result to provider result and prints an error message if remote result is not success
// TODO rename empty response handler or something, this doesn't handle success with data
func remoteResultHandler<T, U>(providerResultHandler: (ProviderResult<T>) -> ())(remoteResult: RemoteResult<U>) {
    let remoteStatus = remoteResult.status
    
    if !remoteResult.success {
        print("Response error, status: \(remoteResult.status), message: \(remoteResult.errorMsg)")
    }
    
    let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteStatus)
    providerResultHandler(ProviderResult(status: providerStatus))
}

//// possible funtion to map remote provider to provider result + data (model) object. Not sure if it makes sense
//func remoteResultWithDataHandler<T, U>(providerResultHandler: (ProviderResult<T>) -> ())(remoteResult: RemoteResult<U>) {
//    let remoteStatus = remoteResult.status
//
//    let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteStatus)
//    
//    if !remoteResult.success {
//        println("Response error, status: \(remoteResult.status), message: \(remoteResult.errorMsg)")
//        providerResultHandler(ProviderResult(status: providerStatus))
//        
//    } else {
//        let providerSuccessObj =
//        
//        
//        providerResultHandler(ProviderResult(status: providerStatus))
//    }
//    
//
//    
//    
//}
