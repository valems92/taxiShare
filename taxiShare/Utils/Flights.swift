import Foundation

class Flights {
    static let instance = Flights();
    
    let APP_ID:String = "65ab1d46"
    let APP_KEY:String = "3129f0fbc7754049d797043b2e0bff6f"
    let API_URL = "https://api.flightstats.com/flex/flightstatus/rest/v2/json/flight/status"
    
    func validateFlightNumber(airlineCode:String?, flightNumber:String?, timePickerDate:Date, completionHandler: @escaping (_ valid: Bool) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let date = dateFormatter.string(from: timePickerDate)
        
        let baseUrl = "\(API_URL)/\(airlineCode!)/\(flightNumber!)/arr/\(date)?appId=\(APP_ID)&appKey=\(APP_KEY)&utc=false"
        
        getFlightData(baseUrl: baseUrl) { (res) in
            if let data = res {
                let flightsArray:NSArray = data["flightStatuses"] as! NSArray
                if flightsArray.count == 0 {
                    completionHandler(false)
                } else {
                    let flightData = flightsArray[0] as? NSDictionary
                    
                    let flightId = flightData!["flightId"] as? Int
                    let operationalTimes = flightData!["operationalTimes"] as? NSDictionary
                    let estimatedRunwayArrival = operationalTimes!["estimatedRunwayArrival"] as? NSDictionary
                    let dateLocal = (estimatedRunwayArrival!["dateLocal"] as? String)!
                    
                    // TODO: Convert dateLocal to Date
                    /*let df = DateFormatter()
                     df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                     guard let flightDate = df.date(from: dateLocal) else {
                     completionHandler(false)
                     return
                     }
                     self.flightArrivalDate = flightDate*/
                    completionHandler(true)
                }
            } else {
                completionHandler(false)
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
