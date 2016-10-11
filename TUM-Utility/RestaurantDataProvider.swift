//
//  PDFHandlerProtocol.swift
//  TUM-Utility
//
//  Created by Dominik Horn on 13.10.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import Foundation

/// Protocol used by RestaurantManager. It delegates loading restaurants' data from the web to it's RestaurantDataProviders
protocol RestaurantDataProvider {
    /// Syncs remote files with local cache
    func refreshData(completionHandler: @escaping ([Restaurant]) -> ())
    
    /// Force clears local cache
    func clearCache()
    
    /// Force data provider to invalidate data and load again
    func invalidate()
    
    /// Returns whether or not the data source is up to date
    func isUpToDate() -> Bool
}
