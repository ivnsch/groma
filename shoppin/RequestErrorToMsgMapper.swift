//
//  RequestErrorToMsgMapper.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct RequestErrorToMsgMapper {
    
    static func message(_ status: ProviderStatusCode) -> String {
        switch status {
            case .notAuthenticated: return trans("error_not_authenticated")
            case .alreadyExists: return trans("error_already_exists")
            case .notFound: return trans("error_not_found")
            case .invalidCredentials: return trans("error_invalid_credentials")
            case .blacklisted: return trans("error_blacklisted")

            // TODO!! probably we should show the same error here as invalid credentials? to not give too much information to the users - what if it's a 3d person trying to find out if the user has a facebook profile with a certain email?. "Authentication error: Apparently you have signed in already with a different provider. Please use this provider to sign in or delete the associated account. Contact support if you need help."
            // --> Solution: Probably the best is to avoid that this error appears at all, by using the providerKey(maybe + providerId to guarantee uniqueness) to identify users instead of the email. This would also require that we use the user's name instead of the email in the app's labels like shared users or history items.
            case .registeredWithOtherProvider: return  trans("error_registered_another_provider")
            
            case .sizeLimit: return trans("size_limit_exceeded")
            case .serverError: return trans("error_server_generic")
            case .serverNotReachable: return trans("error_server_not_reachable")
            case .unknownServerCommunicationError: return trans("error_server_communication_unknown")
            case .serverInvalidParamsError: return trans("error_server_invalid_params")
            case .databaseUnknown: return trans("error_unknown_database")
            case .databaseSavingError: return trans("error_unknown_database")
            case .unknown: return trans("error_unknown")
            case .dateCalculationError: return trans("error_unknown")
            case .socialLoginCancelled: return trans("social_login_cancelled") // this is not used (not an error) but we need exhaustive switch (without default case)
            case .socialLoginError: return trans("social_login_error")
            case .socialAlreadyExists: return trans("social_already_exists")
            case .success: return trans("success") // this is not used (not an error) but we need exhaustive switch (without default case)
            case .noConnection: return trans("error_no_internet_connection")
            case .syncFailed: return trans("sync_failed")
            
            case .userAlreadyExists: return trans("error_user_already_exists")
            
            // There statuses are internal and not meant to be shown to the client. We don't want to add yet another layer for this so we handle them like normal provider status. We provide not empty strings just in case they accidentally appear to the client, to know where they come from.
            case .isNewDeviceLoginAndDeclinedOverwrite: return trans("Error invalid")
            case .cancelledLoginWithDifferentAccount: return trans("Cancelled")
            case .mustUpdateApp: return trans("Invalid service. Please update the app to continue using your user account.") // App delegate shows a different popup for this, see comment processing response in AlamofireHelper
            case .isEmpty: return trans("Empty")
        }
    }
}
