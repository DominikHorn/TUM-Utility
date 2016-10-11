//
//  TodayViewController.swift
//  TUM-Hunger
//
//  Created by Dominik Horn on 17.10.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDelegate, UITableViewDataSource, RestaurantManagerDelegate {
    /// Table view displaying restaurant data
    @IBOutlet weak var tableView: UITableView?
    
    /// Label used to display messages like "No restaurants could be found, launch host app ... -> TODO: Instead of using the host app to download and refresh data, use widget and share with shared documents directory. (Or set refresh timer in host app?!"
    @IBOutlet weak var messageLabel: UILabel?
    
    /// View used to display that we're background refreshing
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    
    /// RestaurantManager for the widget
    private lazy var restaurantManager: RestaurantManager = RestaurantManager(delegate: self)
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Load cells from nib
        let cell: RestaurantTableViewCell = tableView.dequeueReusableCell(withIdentifier: "RestaurantCell") as! RestaurantTableViewCell
        
        // Retrieve restaurant
        let restaurant = self.restaurantManager.restaurants[indexPath.row]
        cell.restaurantNameLabel?.text = restaurant.name
        
        // Add all the dishes
        cell.add(dishes: getNextApplicableDishesFor(restaurant: restaurant))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getValidRestaurantCount()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable dynamic cell row heights
        self.tableView?.rowHeight = UITableViewAutomaticDimension;
        self.tableView?.estimatedRowHeight = 3 * 35.0;
        
        // Call initially on boot
        newDataArrived()
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        //Show more/less button event TODO: do we even need this method? Just set "self.preferredContentSize" to fixed value?! -> No backwards compatibility needed
        if activeDisplayMode == .compact {
            self.preferredContentSize = maxSize
        } else {
            self.preferredContentSize = CGSize(width: 0, height: Double((tableView?.contentSize.height)!))
        }
    }
    
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        // Refresh backend
        self.restaurantManager.asyncRefreshBackend()
        
        // call completion handler
        completionHandler(NCUpdateResult.newData)
    }
    
    // Returns a list of applicable dishes (could be todays dishes or the next ones available during weekend)
    private func getNextApplicableDishesFor(restaurant: Restaurant) -> [Dish] {
        /// TODO: change this to choose current date
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "de_DE")
//        dateFormatter.dateFormat = "dd.MM.yyyy"
//        let date = dateFormatter.date(from: "4.11.2016")
        
        // TODO: intelligently select monday on saturday and sunday!
        return restaurant.getDishesFor(date: Date())
    }
    
    /// Counts and returns all restaurants that have applicable dishes
    private func getValidRestaurantCount() -> Int {
        // Count all restaurants that have dishes
        var counter = 0
        for restaurant in self.restaurantManager.restaurants {
            if getNextApplicableDishesFor(restaurant: restaurant).count > 0 {
                counter += 1
            }
        }
        
        return counter
    }
    
    func asyncRefreshStarted() {
        DispatchQueue.main.sync() {
            self.activityIndicator?.startAnimating()
            self.activityIndicator?.isHidden = false
        }
    }
    
    func asyncRefreshFinished() {
        DispatchQueue.main.sync() {
            self.activityIndicator?.stopAnimating()
            self.activityIndicator?.isHidden = true
        }
    }
    
    func newDataArrived() {
        DispatchQueue.main.async() {
            self.tableView?.reloadData()
            
            // Change display depending on valid restaurant count
            if self.getValidRestaurantCount() == 0 {
                // Hide "Show more/less" button
                self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
                
                // Hide/Show appropriate views
                self.tableView?.isHidden = true
                self.messageLabel?.text = "Heute gibt es anscheinend\nnichts zu essen 😧"
                self.messageLabel?.isHidden = false
            } else {
                // Default state
                self.messageLabel?.isHidden = true
                self.tableView?.isHidden = false
                
                // Display "Show more/less" button
                self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
            }
        }
    }
}
