//
//  EventManager.swift
//  kiteXGroundControl
//
//  Created by Andreas Okholm on 22/02/2017.
//  Copyright © 2017 Andreas Okholm. All rights reserved.
//

import Foundation
import Mavlink

class EventManager {
    static let shared = EventManager()
    
    public var NEDObserver: LocalPositionNEDObserver?
    
}

protocol LocalPositionNEDObserver {
    
    func newPosition(event: mavlink_local_position_ned_t)
}
