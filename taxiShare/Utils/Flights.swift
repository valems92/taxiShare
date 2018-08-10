import Foundation

class Flights {
    static let instance = Flights();
    
    let APP_ID:String = "476a9eaa"
    let APP_KEY:String = "6e1b7f377bc951faf6b82b6dc90c15f7"
    let API_URL = "https://api.flightstats.com/flex/flightstatus/rest/v2/json/flight/status"
    
    func validateFlightNumber(airlineCode:String?, flightNumber:String?, timePickerDate:Date, completionHandler: @escaping (_ valid: Bool, _ date: Date?) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let date = dateFormatter.string(from: timePickerDate)
        
        let baseUrl = "\(API_URL)/\(airlineCode!)/\(flightNumber!)/arr/\(date)?appId=\(APP_ID)&appKey=\(APP_KEY)&utc=false"
        
        getFlightData(baseUrl: baseUrl) { (res) in
            if let data = res {
                let flightsArray:NSArray = data["flightStatuses"] as! NSArray
                if flightsArray.count == 0 {
                    completionHandler(false, nil)
                } else {
                    let flightData = flightsArray[0] as? NSDictionary
                    
                    let operationalTimes = flightData!["operationalTimes"] as? NSDictionary
                    let estimatedRunwayArrival = operationalTimes!["estimatedRunwayArrival"] as? NSDictionary
                    
                    let dateLocal:String
                    if estimatedRunwayArrival == nil {
                        let publishedArrival = operationalTimes!["publishedArrival"] as? NSDictionary
                        dateLocal = (publishedArrival!["dateLocal"] as? String)!
                    } else {
                        dateLocal = (estimatedRunwayArrival!["dateLocal"] as? String)!
                    }
                
                    // TODO: Convert dateLocal to Date
                    let formatter = Foundation.DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                    let flightDate = formatter.date(from: dateLocal)
                    
                    completionHandler(true, flightDate)
                }
            } else {
                completionHandler(false, nil)
            }
        }
    }
    
    private func getFlightData(baseUrl:String, completionHandler: @escaping (_ data: NSDictionary?) -> Void) {
        guard let endpoint = URL(string: baseUrl) else {
            completionHandler(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: endpoint) { (data, response, error) in
            do {
                guard let data = data else {
                    completionHandler(nil)
                    return
                }
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary else {
                    completionHandler(nil)
                    return
                }
                completionHandler(json)
            } catch _ as NSError {
                completionHandler(nil)
                return
            }
        }
        
        task.resume()
    }
}
