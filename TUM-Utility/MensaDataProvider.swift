//
//  MensaDataProvider.swift
//  TUM-Utility
//
//  Created by Dominik Horn on 12.11.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import Foundation

class MensaDataProvider : RestaurantDataProvider {
    /// Current callback that needs to be called after the refresh. Also used to make sure that we only refresh once at a time
    private var currentCallback: (([Restaurant]?, RestaurantDataProvider) -> ())?
    
    // Buffer for restaurants
    private var restaurantsBuffer: [Restaurant] = []
    
    func refreshData(completionHandler: @escaping ([Restaurant]?, RestaurantDataProvider) -> ()) {
        // Make sure we're only proceeding when we're not currently refreshing
        guard self.currentCallback == nil else {
            return
        }
        
        // safe callback
        self.currentCallback = completionHandler
        
        // Trigger background refresh by initializing restaurants and retrieving mensa locations
        requestMensaLocationData()
    }
    
    func clearCache() {
        // Nothing to do here since we don't keep a local cash (yet: TODO!)
    }
    
    private func requestMensaData() {
        // URLRequest for fetching actual mensa data
        let request = NSMutableURLRequest(url: URL(string: "http://lu32kap.typo3.lrz.de/mensaapp/exportDB.php?mensa_id=all")!)
        request.httpMethod = "GET"
        
        // Request task to obtain actual data
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            // Catch errors
            if let error = error {
                // Print error
                print("Error: \(error)")
                
                // Trigger callback early
                self.currentCallback?(nil, self)
                
                // Clear current callback to be able to refresh in the future
                self.currentCallback = nil
                
                // Return early
                return
            } else {
                // Convert response to json dic
                do {
                    // TODO: implement properly for all mensen
                    // Stucafe Boltzmannstr 527
                    // Stucafe Mensa Garching 524
                    // Mensa Garching 422
                    //
                    // Architecture:
                    // "mensa_mensen" : Array // Don't need
                    //      -> anschrift
                    //      -> id
                    //      -> name
                    // "mensa_beilagen" : Array // Ignore for now
                    //      -> date
                    //      -> "mensa_id"
                    //      -> name
                    //      -> "type_long"
                    //      -> "type_short"
                    // "mensa_preise" : Array // wtf?!
                    //   EMPTY (?)
                    // "mensa_menu" // Look at this data
                    //      -> date ("yyyy-mm-dd")
                    //      -> id (= random number?!)
                    //      -> "mensa_id" (= mensa_mensen.id)
                    //      -> name (= Dish name)
                    //      -> "type_long"
                    //      -> "type_nr"
                    //      -> "type_short"
                    
                    guard let jsonObject = try JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any] else {
                        print("Could not fetch json data for mensa")
                        return // TODO: throw propper error
                    }
                    
                    guard let mensaMenu = jsonObject["mensa_menu"] as? [[String : String]] else {
                        print("Could not fetch mensa_menu data")
                        return // TODO: throw propper error
                    }
                    
                    // Iterate over every dic and append dish to correct restaurant
                    for dic in mensaMenu {
                        // Data available at this point
                        // "mensa_menu" // Look at this data
                        //      -> date ("yyyy-mm-dd")
                        //      -> id (= random number?!)
                        //      -> "mensa_id" (= mensa_mensen.id)
                        //      -> name (= Dish name)
                        //      -> "type_long"
                        //      -> "type_nr"
                        //      -> "type_short"
                        
                        let restaurantCandidates = self.restaurantsBuffer.filter({$0.id == Int(dic["mensa_id"]!)!})
                        guard restaurantCandidates.count > 0 else {
                            print("No restaurant found for dish: \(dic["mensa_id"]!)")
                            continue
                        }
                        
                        // TODO: parse all available information!
                        let restaurant = restaurantCandidates[0]
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "de_DE")
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let date = dateFormatter.date(from: dic["date"]!)!
                        let price = self.getPriceFor(typeShort: dic["type_short"]!, typeNr: Int(dic["type_nr"]!)!)
                        let dish = Dish(descriptionText: dic["name"]!, price: price)
                        restaurant.add(dishes: [dish], date: date)
                    }
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
                
                // Trigger callback to ensure that the widget/main app does not lock
                self.currentCallback?(self.restaurantsBuffer, self)
                
                // Set callback to nil to allow future refreshes
                self.currentCallback = nil
            }
        }
        
        // Execute task
        task.resume()
    }
    
    /// Returns dish price based on hard coded table.
    /// TODO: students/employees etc pay different prices -> account for that
    /// TODO: account for beilagen etc
    private func getPriceFor(typeShort: String, typeNr: Int) -> Double {
        switch typeShort {
        case "tg":
            switch typeNr {
            case 1:
                return 1.00
            case 2:
                return 1.55
            case 3:
                return 1.90
            case 4:
                return 2.40
            default:
                break
            }
            break
        case "ae", "bg":
            switch typeNr {
            case 1:
                return 1.55
            case 2:
                return 1.90
            case 3:
                return 2.40
            case 4:
                return 2.60
            case 5:
                return 2.80
            case 6:
                return 3.00
            case 7:
                return 3.20
            case 8:
                return 3.50
            case 9:
                return 4.00
            case 10:
                return 4.50
            default:
                break
            }
            break
        default:
            print("Error: Unknown MensaDishTypeShort: \(typeShort)")
            break
        }
        
        return -1
    }
    
    private func requestMensaLocationData() {
        // Generate random device id TODO: be nice and use a unique id per device
        let randomDeviceID = Int(arc4random_uniform(999999999))
        
        // Formulate Request to hardcoded api
        let request = NSMutableURLRequest(url: URL(string: "https://tumcabe.in.tum.de/Api/mensen")!)
        request.httpMethod = "GET"
        request.setValue("\(randomDeviceID)", forHTTPHeaderField: "X-DEVICE-ID")
        
        // UrlSession data Task
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            // Return if there was an error
            if let error = error {
                // Print error
                print("Error: \(error)")
                
                // Trigger callback
                self.currentCallback?(nil, self)
                
                // Clear current callback to be able to refresh in the future
                self.currentCallback = nil
                
                // return
                return
            } else {
                // Convert response to json dic
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data!, options: []) as? [[String : String]] {
                        // Get value by key
                        for mensaData in jsonObject {
                            // Find shorthand name
                            let words: [String] = (mensaData["name"]?.characters.split{ $0 == " " }.map(String.init))!
                            var shorthandName = ""
                            for word in words {
                                shorthandName += "\(word.substring(to: word.index(word.startIndex, offsetBy: 3)))\n"
                            }
                            print("Shorthand: " + shorthandName)
                            
                            self.restaurantsBuffer.append(Restaurant(name: mensaData["name"]!, shortHandName: shorthandName, longditude: Double(mensaData["longitude"]!)!, latitude: Double(mensaData["latitude"]!)!, address: mensaData["address"]!, id: Int(mensaData["id"]!)!))
                        }
                    }
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
                
                // Trigger next method in chain to ensure that the widget/main app does not lock and eventually resumes doing normal tasks
                self.requestMensaData()
            }
        }
        
        // Execute Task
        task.resume()
    }
}
