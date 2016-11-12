//
//  RestaurantManager.swift
//  TUM-Utility
//

//  Created by Dominik Horn on 14.10.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import Foundation
import NotificationCenter

/// Manager of restaurant data (stores all restaurants, retrieves those from datasources)
class RestaurantManager {
    /// List of all the restaurants
    private(set) var restaurants: [Restaurant]
    
    /// UserDefaults keys
    private let restaurantsKey = "restaurants"

    /// Buffer used durnig async refresh
    private var newRestaurantDataBuffer: [Restaurant]?
    
    /// Data sources
    private var datasources: [RestaurantDataProvider]
    
    /// Delegate
    private var delegate: RestaurantManagerDelegate
    
    /// Initialize empty RestaurantManager (not to be invoked. Use shared instance instead)
    init(delegate: RestaurantManagerDelegate) {
        // Set attributes
        self.restaurants = []
        self.datasources = []
        self.delegate = delegate
        
        // Add all data sources that we need
        self.datasources.append(BetriebsDataProvider())
        
        // Load data (quickload from userdefaults, async refresh in background)
        self.loadData()
    }
    
    /// Asynchronously refresh backend
    func asyncRefreshBackend() {
        // Refresh must already be ongoing if this is not nil
        guard self.newRestaurantDataBuffer == nil else {
            return
        }
        
        // Reset newRestaurantDataBuffer
        self.newRestaurantDataBuffer = []
        
        // Refresh in background
        DispatchQueue.global(qos: .userInteractive).async {
            // Notify delegate
            self.delegate.asyncRefreshStarted?()
            
            // refresh each data source individually
            self.datasources.forEach() {(dataSource) in
                // Invalidate data source
                dataSource.invalidate()
                
                // Asynchronously refresh in background
                DispatchQueue.global(qos: .userInteractive).async {
                    dataSource.refreshData(completionHandler: self.dataSourceRefreshed)
                }
            }
        }
    }
    
    /// Sets restaurants and writes to user defaults
    private func update(restaurants: [Restaurant]) {
        self.restaurants = restaurants
        
        // Write changes to self.restaurant to defaults
        UserDefaults(suiteName: "group.tum")?.setValue(NSKeyedArchiver.archivedData(withRootObject: self.restaurants), forKey:restaurantsKey)
    }
    
    /// Loads data
    private func loadData() {
        // Fetch data from userdefaults (check for nil -> asyncRefresh if nil)
        guard let data = UserDefaults(suiteName: "group.tum")?.object(forKey: self.restaurantsKey) as? Data else {
            self.asyncRefreshBackend()
            return
        }
        
        // We have to load data synchronously
        if let restaurants = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Restaurant] {
            // Use dequeued data, don't refresh in background
            self.restaurants = restaurants
        }
        
        // Notify delegate
        self.delegate.newDataArrived?()
        
        // Refresh asynchronously in the background to make sure we're up to date
        self.asyncRefreshBackend()
    }
    
    // TODO: is this thread safe?!
    /// Called when a dataSource was successfully refreshed (Ugly code but necessary)
    private func dataSourceRefreshed(restaurants: [Restaurant]) {
        // Error prevention
        guard self.newRestaurantDataBuffer != nil else {
            print("NewRestaurantDataBuffer unexpectedly nil!")
            return
        }
        
        // Start synchronized
        synchronized(self.delegate) {
            // Append data to restaurantBuffer
            restaurants.forEach() {
                // TODO: may we add to restaurantsBuffer instead?!
                self.newRestaurantDataBuffer?.append($0)
            }
            
            // Filter for every data source that is not up to date.
            if self.datasources.filter({ !$0.isUpToDate() }).count == 0 {
                // Data refresh has finished -> notify delegate
                self.delegate.asyncRefreshFinished?()
                
                // Copy Data
                self.update(restaurants: self.newRestaurantDataBuffer!)
                self.newRestaurantDataBuffer = nil
                
                // TODO: only invoke when data has actually changed!
                // All datasources are up to date -> notify by calling callback
                self.delegate.newDataArrived?()
            }
        }
    }
}
