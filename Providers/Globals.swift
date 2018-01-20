//
//  Globals.swift
//  shoppin
//
//  Created by ischuetz on 28/03/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public typealias VoidFunction = () -> ()

public typealias RealmToken = (token: NotificationToken, realm: Realm)

public typealias Insets = (left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat) // TODO this shouldn't be in providers. Add it to the iOS project

public enum Orientation { case vertical, horizontal }
public enum DirectionUpDown { case up, down }

