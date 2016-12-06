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
    
    /// RestaurantManager for the widget TODO: only use restaurants that are (near my location/Selected in app/Near selected location in app) 
    private var restaurantManager: RestaurantManager?
    
    /// Previous table height UserDefaults key
    private let tableRowHeightKey = "previousWidgetTableHeight"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.restaurantManager = RestaurantManager(delegate: self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Load cells from nib
        let cell: RestaurantTableViewCell = tableView.dequeueReusableCell(withIdentifier: "RestaurantCell") as! RestaurantTableViewCell
        
        // TODO: remove fixed stuff / Garching location 48.264465, 11.670897
        // Retrieve restaurant
        let restaurant = self.restaurantManager?.getRestaurantsNearestTo(latitude: 48.264465, longditude: 11.670897, amount: 5)[indexPath.row]
        cell.restaurantNameLabel?.text = restaurant?.shortHandName
        
        // Add all the dishes
        cell.add(dishes: getNextApplicableDishesFor(restaurant: restaurant!))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getRestaurantsToDisplay().count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable dynamic cell row heights
        self.tableView?.rowHeight = UITableViewAutomaticDimension;
        
        // try to load row height from userdefaults
        if let previousRowHeight = UserDefaults(suiteName: "group.tum")?.float(forKey: tableRowHeightKey) {
            self.tableView?.estimatedRowHeight = CGFloat(previousRowHeight)
        } else {
            self.tableView?.estimatedRowHeight = 300
        }
        
        // Boot state
        self.messageLabel?.isHidden = false
        self.messageLabel?.text = "Ich lade Daten aus dem Internetz 👾"
        self.tableView?.isHidden = true
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
        // Refresh backend TODO: since this is called on boot, restaurantManager will refresh twice...
        // self.restaurantManager.asyncRefreshBackend()
        
        // call completion handler
        completionHandler(NCUpdateResult.newData)
    }
    
    // Returns a list of applicable dishes (could be todays dishes or the next ones available during weekend)
    private func getNextApplicableDishesFor(restaurant: Restaurant) -> [Dish] {
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "de_DE")
//        dateFormatter.dateFormat = "dd.MM.yyyy"
//        let date = dateFormatter.date(from: "28.11.2016")!

        // TODO: intelligently select monday on saturday and sunday!
        return restaurant.getDishesFor(date: Date())
    }
    
    /// Counts and returns all restaurants that have applicable dishes
    private func getRestaurantsToDisplay() -> [Restaurant] {
        // TODO: remove fixed stuff / Garching location 48.264465, 11.670897
        return (self.restaurantManager?.getRestaurantsNearestTo(latitude: 48.264465, longditude: 11.670897, amount: 3))!
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
        print("New Data has arrived!")

        DispatchQueue.main.async() {
            print("Reloading tableView Data")
            // Refresh table view
            self.tableView?.reloadData()
            print("Done executing reloadData() method on current thread")
        
            // Hacky way to achieve this but there is no official api! :(... This works because tableView.reloadData() will schedule tasks on the main thread, making it busy. By the time this async{} block is exectuted tableView's reload code will have finished. Hence this "detects" when the reload is done...
            DispatchQueue.main.async {
                print("Updating stuff after reloading tableView")

                // Get tableView height
                let tableViewHeight = (self.tableView?.contentSize.height)!
                
                // Reset preferred content size for self
                self.preferredContentSize = CGSize(width: 0, height: Double(tableViewHeight))

                // Restaurant count
                let validRestaurantCount = self.getRestaurantsToDisplay().count

                // Store in user defaults for next boot
                if validRestaurantCount > 0 {
                    let rowHeight = tableViewHeight / CGFloat(validRestaurantCount)
                    self.tableView?.estimatedRowHeight = rowHeight
                    UserDefaults(suiteName: "group.tum")?.set(rowHeight, forKey: self.tableRowHeightKey)
                }
                
                // Change display depending on valid restaurant count
                if validRestaurantCount == 0 {
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
}
