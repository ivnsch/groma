//
//  WebsocketHelper.swift
//  shoppin
//
//  Created by ischuetz on 29/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


public struct WebsocketHelper {

    // Returns if client tries to open a connection. NOTE only this, we don't know if there's a connection as the server hasn't answered when we return from this method. Also websocket client-init can fail (we don't return anything here, only logs). In most cases it shouldn't though since we check for connection and login status in advance and this is the only reason because of which this can fail.
    public static func tryConnectWebsocket() -> Bool {
        if ConnectionProvider.connectedAndLoggedIn {
            if userDisabledWebsocket() {
                logger.d("User diabled websocket, not connecting")
                return false
            } else {
                logger.d("Connecting websocket...")
                Prov.userProvider.connectWebsocketIfLoggedIn()
                return true
            }
        } else {
            logger.d("Not connected or logged in - can't open websocket connection")
            return false
        }
    }
    
    public static func userDisabledWebsocket() -> Bool {
        return PreferencesManager.loadPreference(PreferencesManagerKey.userDisabledWebsocket) ?? false
    }
    
    public static func saveWebsocketDisabled(_ disabled: Bool) {
        // this if else is a quick fix because passing directly disabled doesn't compile TODO proper fix
        if disabled {
            PreferencesManager.savePreference(PreferencesManagerKey.userDisabledWebsocket, value: true)
        } else {
            PreferencesManager.savePreference(PreferencesManagerKey.userDisabledWebsocket, value: false)
        }
    }
}
