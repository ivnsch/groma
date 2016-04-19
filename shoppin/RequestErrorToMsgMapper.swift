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
            
            // TODO!! probably we should show the same error here as invalid credentials? to not give too much information to the users - what if it's a 3d person trying to find out if the user has a facebook profile with a certain email?. "Authentication error: Apparently you have signed in already with a different provider. Please use this provider to sign in or delete the associated account. Contact support if you need help."
            // --> Solution: Probably the best is to avoid that this error appears at all, by using the providerKey(maybe + providerId to guarantee uniqueness) to identify users instead of the email. This would also require that we use the user's name instead of the email in the app's labels like shared users or history items.
            case .RegisteredWithOtherProvider: return "error_registered_another_provider"
            
            case .SizeLimit: return "size_limit_exceeded"
            case .ServerError: return "error_server_generic"
            case .ServerNotReachable: return "error_server_not_reachable"
            case .UnknownServerCommunicationError: return "error_server_communication_unknown"
            case .ServerInvalidParamsError: return "error_server_invalid_params"
            case .DatabaseUnknown: return "error_unknown_database"
            case .DatabaseSavingError: return "error_unknown_database"
            case .Unknown: return "error_unknown"
            case .DateCalculationError: return "error_unknown"
            case .SocialLoginCancelled: return "social_login_cancelled" // this is not used (not an error) but we need exhaustive switch (without default case)
            case .SocialLoginError: return "social_login_error"
            case .SocialAlreadyExists: return "social_already_exists"
            case .Success: return "success" // this is not used (not an error) but we need exhaustive switch (without default case)
            case .NoConnection: return "error_no_internet_connection"
            
            case .IsNewDeviceLoginAndDeclinedOverwrite: return "Error invalid" // this is a special status and is not mean to be shown to the client. Return some text anyway, if something goes wrong at least we know where the popup comes from.
        }
    }
}
