//
//  MyWebSocket.swift
//  shoppin
//
//  Created by ischuetz on 22/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Starscream
import Valet

class MyWebSocket: WebSocketDelegate {
    
    private let socket: WebSocket
    
    init() {
        socket = WebSocket(url: NSURL(string: "ws://\(Urls.hostIPPort)/ws")!)
        socket.delegate = self
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        let maybeToken = valet?.stringForKey(KeychainKeys.token)
        if let token = maybeToken {
            socket.headers["X-Auth-Token"] = token
        }
        socket.headers["Content-Type"] = "application/json"

        socket.connect()
    }
    
    func websocketDidConnect(socket: WebSocket) {
        print("Websocket: Connected")
        
        Providers.listProvider.lists {listsResult in
            
            if let lists = listsResult.sucessResult {
                
                Providers.inventoryProvider.inventories {inventoriesResult in
                    
                    if let inventories = inventoriesResult.sucessResult {
                        
                        // TODO new services that fetch only uuids from db
                        let listsUuids = lists.map{$0.uuid}
                        let inventoriesUuids = inventories.map{$0.uuid}
                        
                        do {
                            let dict = ["lists": listsUuids, "inventories": inventoriesUuids]
                            let data = try NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions())
                            if let str = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                                
                                print("Websocket: Sending string: \(str)")
                                socket.writeString(str)
                                
                            } else {
                                print("Error: MyWebSocket.websocketDidConnect: invalid serialization result: dict: \(dict), data: \(data)")
                            }
                        } catch let e as NSError {
                            print("Error: MyWebSocket.websocketDidConnect: serializing json: \(e)")
                        }
                        
                    } else {
                        print("Error: MyWebSocket.websocketDidConnect: couldn't retrieve inventories: \(inventoriesResult)")
                    }
                }
            } else {
                print("Error: MyWebSocket.websocketDidConnect: couldn't retrieve lists: \(listsResult)")
            }
        }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let error = error {
            if error.code == 401 {
                print("Not authorized")
            } else {
                print("Unknown websocket connection error: \(error)")
            }
        } else {
            print("Websocket: Disconnected")
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("Websocket: Received text: \(text)")

        if let data = (text as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                if let dict =  json as? Dictionary<String, AnyObject>  {
                    
                    print("Websocket: Parsed dictionary: \(dict)")
                    
                    let verb = dict["verb"]
                    let topic = dict["topic"]
                    let data = dict["message"]
                    
                    print("Websocket: Verb: \(verb), topic: \(topic), data: \(data)")
                    // TODO notification payload
                    NSNotificationCenter.defaultCenter().postNotificationName("NotificationIdentifier", object: nil)

                }
            } catch let e as NSError {
                print("Error: MyWebSocket.websocketDidReceiveMessage: deserializing json: \(e)")
            }
        } else {
            print("Error: MyWebSocket.websocketDidReceiveMessage: couldn't get data from text: \(text)")
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("Websocket: Received data: \(data.length)")
    }
}