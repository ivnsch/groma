//
//  MyWebSocket.swift
//  shoppin
//
//  Created by ischuetz on 22/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Starscream


private class Keys {
    
    // send    
    static let deviceId = "did"
    static let fooParam = "f" // workarond for a server issue
    static let lists = "lists"
    static let inventories = "inventories"
    
    static let action = "a"
    static let data = "d"
    
    static let subscribe = "sub"
    static let unsubscribe = "unsub"
    
    // receive
    static let cn = "cn"
    static let subscribed = "sub"
    static let unsubscribed = "unsub"
    static let verb = "verb"
    static let category = "category"
    static let topic = "topic"
    static let sender = "sender"
    static let message = "message"
}

class MyWebSocket: WebSocketDelegate {
    
    fileprivate var socket: WebSocket?
    
    fileprivate var reconnectDelayK: Double = 1
    fileprivate var maxReconnectDelay: Double = 30 // seconds
    
    var isConnected: Bool {
        return socket?.isConnected ?? false
    }
    
    init() {
        if ConnectionProvider.connected {
            if let token = AccessTokenHelper.loadToken() {
                socket = WebSocket(url: URL(string: "ws://\(Urls.hostIPPort)/ws")!)
                socket?.delegate = self
                socket?.headers["X-Auth-Token"] = token
                socket?.headers["Content-Type"] = "application/json"
                logger.d("Websocket: Initialised, connecting...")
                socket?.connect()
                
            } else {
                logger.v("No login token - can't initialise websocket ")
            }

        } else {
            logger.v("No internet connection - can't initialise websocket ")
        }
    }
    
    // Unsubscribes if the user is logged in. After the server acks the socket connection is disconnected.
    func disconnect() {
        
        
        
        logger.d("Websocket: Disconnecting...")
        if let deviceId: String = PreferencesManager.loadPreference(PreferencesManagerKey.deviceId) {
            sendMaybeMsg(unsubscribeMsg(deviceId)) // TODO!!!! we should send the list of the items we are subscribed to, to not make server traverse whole subscriber map looking for our device id
        } else {
            logger.e("Websocket: Can't unsubcribe websocket without device id. Not disconnecting.") // TODO if wen can't unsubscribe maybe we should disconnect anyway? But how does the server remove our not used entries from the subscriber map?
        }
    }
    
    fileprivate func sendMaybeMsg(_ msg: String?) {
        if let msg = msg {
            if isConnected {
                logger.v("Websocket: Sending msg: \(msg)")
                socket?.write(string: msg)
            } else {
                logger.w("Websocket: Trying to send a message: \(msg), but socket is not connected or initialised: \(String(describing: socket?.isConnected))")
            }
        } else {
            logger.e("Websocke: Trying to send nil. Not sending anything.")
        }
    }
    
    fileprivate func msgDict(_ action: String, payload: [String: AnyObject]) -> [String: AnyObject] {
        return [Keys.action: action as AnyObject, Keys.data: payload as AnyObject]
    }
    
    fileprivate func subscribeDict(_ listsUuids: [String], inventoriesUuids: [String], deviceId: String) -> [String: AnyObject] {
        let payload: [String: AnyObject] = [Keys.lists: listsUuids as AnyObject, Keys.inventories: inventoriesUuids as AnyObject, Keys.deviceId: deviceId as AnyObject]
        return msgDict(Keys.subscribe, payload: payload)
    }
    
// TODO!!!! we should send the list of the items we are subscribed to, to not make server traverse whole subscriber map looking for our device id (repeated todo)
//    private func unsubscribeDict(listsUuids: [String], inventoriesUuids: [String], deviceId: String) -> [String: AnyObject] {
//        let payload: [String: AnyObject] = [Keys.lists: listsUuids, Keys.inventories: inventoriesUuids, Keys.deviceId: deviceId]
//        return msgDict(Keys.unsubscribe, payload: payload)
//    }

    fileprivate func unsubscribeDict(_ deviceId: String) -> [String: AnyObject] {
        let payload: [String: AnyObject] = [Keys.deviceId: deviceId as AnyObject, Keys.fooParam: "" as AnyObject]
        return msgDict(Keys.unsubscribe, payload: payload)
    }
    
    fileprivate func subscribeMsg(_ listsUuids: [String], inventoriesUuids: [String], deviceId: String) -> String? {
        let dict = subscribeDict(listsUuids, inventoriesUuids: inventoriesUuids, deviceId: deviceId)
        return toMsgStr(dict)
    }
    
    fileprivate func unsubscribeMsg(_ deviceId: String) -> String? {
        let dict = unsubscribeDict(deviceId)
        return toMsgStr(dict)
    }
    
    fileprivate func toMsgStr(_ dict: [String: AnyObject]) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions())
            return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
        } catch let e as NSError {
            logger.e("Error serializing json: \(e). dict: \(dict)")
            return nil
        }
    }
    
    fileprivate var websocketDeviceId: String {
        if let websocketUuid: String = PreferencesManager.loadPreference(PreferencesManagerKey.websocketUuid) {
            return websocketUuid
        } else {
            let websocketUuid: String = UUID().uuidString
            PreferencesManager.savePreference(PreferencesManagerKey.websocketUuid, value: NSString(string: websocketUuid))
            return websocketUuid
        }
    }
    
    func websocketDidConnect(socket: WebSocket) {
        
        let deviceId = websocketDeviceId
        
        logger.d("Websocket: Connected. Device id: \(deviceId). Will send subscribe...")
        
        Prov.listProvider.lists(false) {listsResult in
            
            if let lists = listsResult.sucessResult {
                
                Prov.inventoryProvider.inventories(false) {[weak self] inventoriesResult in
                    
                    guard let weakSelf = self else {return}
                    
                    if let inventories = inventoriesResult.sucessResult {
                        
                        // TODO! new services that fetch only uuids from db
                        let listsUuids = Array(lists.map{$0.uuid})
                        let inventoriesUuids = inventories.toArray().map{$0.uuid}

                        weakSelf.sendMaybeMsg(weakSelf.subscribeMsg(listsUuids, inventoriesUuids: inventoriesUuids, deviceId: deviceId))
                        PreferencesManager.savePreference(PreferencesManagerKey.deviceId, value: NSString(string: deviceId))

                    } else {
                        logger.e("Couldn't retrieve inventories: \(inventoriesResult)")
                    }
                }
            } else {
                logger.e("Couldn't retrieve lists: \(listsResult)")
            }
        }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let error = error {
            switch error.code {
            case 401:
                logger.w("Not authorized, removing login token \(error) TODO show login screen")
                Prov.userProvider.removeLoginToken()
            case 1000:
                // Called when we close the connection explicitly with disconnect()
                logger.d("Websocket: Closed connection")
                // ! sometimes this was called when the server was down also, so we try to reconnect here also, if there's a login token. If the user just logged out this does nothing as logout removes the login token.
                if !WebsocketHelper.userDisabledWebsocket() {
                    tryReconnectIfLoggedIn()
                }
            case 61:
                // "Connection refused" - Called e.g. when trying to connect while the server is down. Here we don't check for login token because we should have checked for login token in the call that originated this reponse. This is only used for retry. If we are here, it means a connection attempt just was done, which means there is a login token stored.
                logger.w("Websocket: Connection refused")

                tryReconnectAndIncrementDelay()
                notifyConnected(false)
                
            case 57:
                logger.w("Trying to reconnect socket after: \(error)")
                // Got this sometimes on device, no apparent reason, server wasn't down or anything. Only thing is that it was on the device and the app was in the background 20 mins or so (using twitter while testing with the simulator)
                // Error Domain=NSPOSIXErrorDomain Code=57 "The operation couldn’t be completed. Socket is not connected"[;
                // For now we handle as closed connection and try to reconnect
                tryReconnectIfLoggedIn()
                
            default:
                logger.e("Unknown websocket connection error: \(error)")
            }
        } else {
            // Called when the server is stopped (e.g. restarted) NOTE we assume for now this is the only reason, there may be other(?) TODO: review. We should only try to reconnect when the server was down or general connection error, not when client intentionally disconnects.
            // EDIT: Apparently called also when the user logs out - first we see "Websocket: Closed connection[;" in log (case 1000 above) and immediately after "Websocket: Server closed the connection[;" which means we are being notified 2x. So now we check here if user has a login token (this is removed when the user logs out), so we don't try to reconnect or sent the notification to show the "websocket disconnected" message in this case. 
            // The responses seem to be a bit inconsistent, so we call now tryReconnectIfLoggedIn both on 1000 and here and check for login token in both cases. >> in server down case anyway only 1 of them is called, not both at the same time, so we will not have the situation of running the retry timier 2x (even if, it will just access the timer 2x)
            logger.d("Websocket: Server closed the connection")
            tryReconnectIfLoggedIn()
        }
    }
    
    fileprivate func tryReconnectIfLoggedIn() {
        if Prov.userProvider.hasLoginToken {
            notifyConnected(false)
            tryReconnectAndIncrementDelay()
        }
    }

    fileprivate func tryReconnectAndIncrementDelay() {
        
        /** 
         Calculate delays using exponential backoff algorithm
         1. For k attempts, generate a random interval of time between 0 and 2^k - 1.
         2. If you are able to reconnect, reset k to 1
         3. If reconnection fails, k increases by 1 and the process restarts at step 1.
         4. To truncate the max interval, when a certain number of attempts k has been reached, k stops increasing after each attempt.
         src: http://blog.johnryding.com/post/78544969349/how-to-reconnect-web-sockets-in-a-realtime-web-app
         (logic slightly modified we stop increasing after max delay upper reached (which is derived from k) not directly max k)
         */
        func calculateDelay() -> (Double, Double) {
            let delayUpper = (pow(2, reconnectDelayK) - 1) // the upper limit to calculate the random delay
            let delay = delayUpper.randomFrom0()
//            logger.v("reconnectDelayK: \(reconnectDelayK) delayUpper: \(delayUpper) random: \(delay)")
            return (delayUpper, min(delay, maxReconnectDelay))
        }
        
        let (delayUpper, delay) = calculateDelay()
        logger.d("Will try to connect after delay: \(delay)")
        connectAfterDelay(delay)
        
        
        if delayUpper < maxReconnectDelay {
            reconnectDelayK = reconnectDelayK + 1
        }
    }
    
    fileprivate func notifyConnected(_ connected: Bool) {
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: WSNotificationName.Connection.rawValue), object: nil, userInfo: ["value": connected])
    }
    
    fileprivate func connectAfterDelay(_ delaySecs: Double) {
        delay(delaySecs) {[weak self] in
            
            guard let weakSelf = self else {return}
            
            if !weakSelf.isConnected {
                
                logger.d("Trying to connect websocket again after delay: \(Int(delaySecs))")
                self?.socket?.connect()
            }
        }
    }
    
    fileprivate func onSubscribed() {
        notifyConnected(true)
        reconnectDelayK = 1
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        logger.v("Websocket: Received text: \(text)")

        if let data = (text as NSString).data(using: String.Encoding.utf8.rawValue) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
                if let dict =  json as? Dictionary<String, AnyObject> {
                    
                    // TODO unsubscribe ack - do we need this, if yes implement (this snippet is from old code when parsing was done in this class)
                    if let connectionMsg = dict[Keys.cn] as? String {
                        switch connectionMsg {
                            case Keys.subscribed:
                                logger.d("Websocket: Received subscribed ack")
                                onSubscribed()
                            
                            case Keys.unsubscribed:
                                logger.d("Websocket: Received unsubscribed ack")
                                socket.disconnect()
                                PreferencesManager.clearPreference(key: PreferencesManagerKey.deviceId)
                            
                            default:
                                logger.e("Websocket: Received unexpected connection msg: \(connectionMsg)")
                        }
                        
                    } else {
                        // If the dictionary has no action key we expected it to be a standard message
                        if let verb = dict[Keys.verb] as? String, let category = dict[Keys.category] as? String, let topic = dict[Keys.topic] as? String, let sender = dict[Keys.sender] as? String, let data = dict[Keys.message] {
                            logger.v("Websocket: Verb: \(verb), category: \(category), topic: \(topic), sender: \(sender), data: \(data)")
                            MyWebsocketDispatcher.processCategory(category, verb: verb, topic: topic, sender: sender, data: data)
                        } else {
                            logger.e("Websocket: Dictionary has not expected contents: \(dict)")
                        }
                    }

                } else {
                    logger.e("Websocket: Couldn't cast json obj to dict: \(json)")
                }
                
            } catch let e as NSError {
                logger.e("Websocket: Error deserializing json: \(e)")
            }
            
        } else {
            logger.e("Websocket: Couldn't get data from text: \(text)")
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        logger.v("Websocket: Received data: \(data.count)")
    }
}
