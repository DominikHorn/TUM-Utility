//
//  RestaurantManagerDelegate.swift
//  TUM-Utility
//
//  Created by Dominik Horn on 06.11.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import Foundation

/// Delegate pattern used as notification interface between RestaurantManager and non library code
@objc protocol RestaurantManagerDelegate : class {
    /// Notifies delegate that an asynchronous refresh has started
    @objc optional func asyncRefreshStarted()
    
    /// Notifies delegate that an asynchronous refresh has finished
    @objc optional func asyncRefreshFinished()
    
    /// Notifies delegate that new data has arrived
    @objc optional func newDataArrived()
}
