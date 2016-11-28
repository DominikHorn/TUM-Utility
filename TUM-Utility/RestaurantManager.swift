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
    
    /// Data sources (DataProvider : (true -> refreshed)
    private var datasources: [RestaurantDataProvider]
    
    /// Used to keep track of what has already been refreshed. TODO: refactor
    private var refreshingSourcesCounter = 0
    
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
        self.datasources.append(MensaDataProvider())
        
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
        
        // Reset refreshing sources counter
        self.refreshingSourcesCounter = self.datasources.count
        
        // Refresh in background
        DispatchQueue.global(qos: .userInteractive).async {
            // Notify delegate
            self.delegate.asyncRefreshStarted?()
            
            // refresh each data source individually
            self.datasources.forEach() {(dataSource) in
                // Asynchronously refresh in background
                DispatchQueue.global(qos: .userInteractive).async {
                    dataSource.refreshData(completionHandler: self.dataSourceRefreshed)
                }
            }
        }
    }
    
    /// Retrieves "amount" of restaurants nearest to location
    func getRestaurantsNearestTo(latitude: Double, longditude: Double, amount: Int) -> [Restaurant] {
        // if we don't have any restaurants, just return an empty array
        guard self.restaurants.count > 0 else {
            return []
        }

        // TODO: implement better
        var nearestRestaurants = [Restaurant]()
        
        for _ in 0..<amount {
            var minDistance = 90000000.0 // Assume that no distance greater than 90000 km exists on earth -> TODO: come up with better way!
            var closestRestaurant: Restaurant? = nil
            for restaurant in self.restaurants {
                guard nearestRestaurants.filter({$0 === restaurant}).count == 0 else {
                    continue
                }
                
                // Distance to restaurant
                let distance = Utility.haversineDistance(latitude1: latitude, longditude1: longditude, latitude2: restaurant.latitude, longditude2: restaurant.longditude)
                
                // is it closer than minDistance?
                if distance < minDistance {
                    minDistance = distance
                    closestRestaurant = restaurant
                }
            }
            
            // TODO: remove force unwrap since it's obviously not safe
            nearestRestaurants.append(closestRestaurant!)
        }
        
        return nearestRestaurants
    }
    
    /// Sets restaurants and writes to user defaults
    private func update(restaurants: [Restaurant]) {
        self.restaurants = restaurants
        
        // Write changes to self.restaurant to defaults
        UserDefaults(suiteName: "group.tum")?.setValue(NSKeyedArchiver.archivedData(withRootObject: self.restaurants), forKey:restaurantsKey)
    }
    
    /// Loads data
    private func loadData() {
        // Fetch data from userdefaults (check for nil -> asyncRefresh immediately if nil)
        guard let data = UserDefaults(suiteName: "group.tum")?.object(forKey: self.restaurantsKey) as? Data else {
            self.asyncRefreshBackend()
            return
        }
        
        // Unarchive user defaults data
        if let restaurants = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Restaurant] {
            // Use dequeued data for now. Refresh in background anyways
            self.restaurants = restaurants
        }
        
        // Notify delegate that we have data
        self.delegate.newDataArrived?()
        
        // Refresh asynchronously in the background to make sure we're up to date
        self.asyncRefreshBackend()
    }
    
    // TODO: is this thread safe?!
    /// Called when a dataSource was successfully refreshed (Ugly code but necessary)
    private func dataSourceRefreshed(restaurants: [Restaurant]?, caller: RestaurantDataProvider) {
        // Error prevention
        guard self.newRestaurantDataBuffer != nil else {
            print("NewRestaurantDataBuffer unexpectedly nil!")
            return
        }
        
        
        // Start synchronized
        synchronized(self.delegate) {
            // Unwrap and add to restaurants if needed
            if let restaurants = restaurants {
                // Append data to restaurantBuffer
                restaurants.forEach() {
                    // TODO: may we add to restaurantsBuffer instead?!
                    self.newRestaurantDataBuffer?.append($0)
                }
            }
            
            // Decrement counter
            self.refreshingSourcesCounter -= 1
            
            // TODO: Keep a record of which datasource called back and use that instead of this bullshit method!
            if self.refreshingSourcesCounter == 0 {
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
