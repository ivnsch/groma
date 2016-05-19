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
            case .NotAuthenticated: return trans("error_not_authenticated")
            case .AlreadyExists: return trans("error_already_exists")
            case .NotFound: return trans("error_not_found")
            case .InvalidCredentials: return trans("error_invalid_credentials")
            case .Blacklisted: return trans("error_blacklisted")

            // TODO!! probably we should show the same error here as invalid credentials? to not give too much information to the users - what if it's a 3d person trying to find out if the user has a facebook profile with a certain email?. "Authentication error: Apparently you have signed in already with a different provider. Please use this provider to sign in or delete the associated account. Contact support if you need help."
            // --> Solution: Probably the best is to avoid that this error appears at all, by using the providerKey(maybe + providerId to guarantee uniqueness) to identify users instead of the email. This would also require that we use the user's name instead of the email in the app's labels like shared users or history items.
            case .RegisteredWithOtherProvider: return  trans("error_registered_another_provider")
            
            case .SizeLimit: return trans("size_limit_exceeded")
            case .ServerError: return trans("error_server_generic")
            case .ServerNotReachable: return trans("error_server_not_reachable")
            case .UnknownServerCommunicationError: return trans("error_server_communication_unknown")
            case .ServerInvalidParamsError: return trans("error_server_invalid_params")
            case .DatabaseUnknown: return trans("error_unknown_database")
            case .DatabaseSavingError: return trans("error_unknown_database")
            case .Unknown: return trans("error_unknown")
            case .DateCalculationError: return trans("error_unknown")
            case .SocialLoginCancelled: return trans("social_login_cancelled") // this is not used (not an error) but we need exhaustive switch (without default case)
            case .SocialLoginError: return trans("social_login_error")
            case .SocialAlreadyExists: return trans("social_already_exists")
            case .Success: return trans("success") // this is not used (not an error) but we need exhaustive switch (without default case)
            case .NoConnection: return trans("error_no_internet_connection")
            case .SyncFailed: return trans("sync_failed")
            
            // There statuses are internal and not meant to be shown to the client. We don't want to add yet another layer for this so we handle them like normal provider status. We provide not empty strings just in case they accidentally appear to the client, to know where they come from.
            case .IsNewDeviceLoginAndDeclinedOverwrite: return trans("Error invalid")
            case .CancelledLoginWithDifferentAccount: return trans("Cancelled")
            case .MustUpdateApp: return trans("Invalid service. Please update the app to continue using your user account.") // App delegate shows a different popup for this, see comment processing response in AlamofireHelper
        }
    }
}
