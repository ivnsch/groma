//
//  RequestErrorToMsgMapper.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct RequestErrorToMsgMapper {
    
    static func message(status: ProviderStatusCode) -> String {
        switch status {
            case .NotAuthenticated: return "error_not_authenticated"
            case .AlreadyExists: return "error_already_exists"
            case .NotFound: return "error_not_found"
            case .InvalidCredentials: return "error_invalid_credentials"
            case .ServerError: return "error_server_generic"
            case .ServerNotReachable: return "error_server_not_reachable"
            case .UnknownServerCommunicationError: return "error_server_communication_unknown"
            case .ServerInvalidParamsError: return "error_server_invalid_params"
            case .DatabaseUnknown: return "error_unknown_database"
            case .DatabaseSavingError: return "error_unknown_database"
            case .Unknown: return "error_unknown"
            case .DateCalculationError: return "error_unknown"
            case .Success: return "success" // this is not used but we want exhaustive switch (without default case)
        }
    }
}
