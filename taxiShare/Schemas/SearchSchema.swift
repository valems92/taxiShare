import Foundation
import CoreLocation
import DshareFramework

class SearchSchema : SchemaProtocol {
    var id:String
    var userId:String
    var startingPointCoordinate:CLLocationCoordinate2D
    var startingPointAddress:String
    var destinationCoordinate:CLLocationCoordinate2D
    var destinationAddress:String
    var passengers:Int
    var baggage:Int
    var leavingTime:Date
    var foundSuggestion:Bool
    var suggestionsId:[String]?
    var waitingTime:Int?
    var flightId:Int?
    var createdOn:Date?
    
    init(userId:String, startingPointCoordinate:CLLocationCoordinate2D, startingPointAddress:String, destinationCoordinate:CLLocationCoordinate2D, destinationAddress:String, passengers:Int, baggage:Int, leavingTime:Date, waitingTime:Int?, flightId:Int?) {
        self.id = UUID().uuidString
        self.userId = userId
        self.startingPointCoordinate = startingPointCoordinate
        self.startingPointAddress = startingPointAddress
        self.destinationCoordinate = destinationCoordinate
        self.destinationAddress = destinationAddress
        self.passengers = passengers
        self.baggage = baggage
        self.leavingTime = leavingTime
        self.foundSuggestion = false
        
        if waitingTime != nil {
            self.waitingTime = waitingTime!
        }
        
        if flightId != nil {
            self.flightId = flightId!
        }
    }
    
    required init(fromJson:[String:Any]){
        id = fromJson["id"] as! String
        userId = fromJson["userId"] as! String
        
        let spLat = fromJson["startingPointLat"] as! CLLocationDegrees
        let spLong = fromJson["startingPointLong"] as! CLLocationDegrees
        startingPointCoordinate = CLLocationCoordinate2D(latitude: spLat, longitude: spLong)
        startingPointAddress = fromJson["startingPointAddress"] as! String
        
        let desLat = fromJson["destinationLat"] as! CLLocationDegrees
        let desLong = fromJson["destinationLong"] as! CLLocationDegrees
        destinationCoordinate = CLLocationCoordinate2D(latitude: desLat, longitude: desLong)
        destinationAddress = fromJson["destinationAddress"] as! String
        
        passengers = fromJson["passengers"] as! Int
        baggage = fromJson["baggage"] as! Int
        leavingTime = Date.fromFirebase(fromJson["leavingTime"] as! Double)
        
        foundSuggestion = fromJson["foundSuggestion"] as! Bool
        
        if let si = fromJson["suggestionsId"] as? [String] {
            suggestionsId = si
        }
        
        if let wt = fromJson["waitingTime"] as? Int {
            waitingTime = wt
        }
        
        if let fId = fromJson["flightId"] as? Int {
            flightId = fId
        }
        
        if let ts = fromJson["createdOn"] as? Double {
            createdOn = Date.fromFirebase(ts)
        }
    }
    
    func toJson()->[String:Any] {
        var json = [String:Any]()
        
        json["id"] = id
        json["userId"] = userId
        json["startingPointLat"] = startingPointCoordinate.latitude
        json["startingPointLong"] = startingPointCoordinate.longitude
        json["startingPointAddress"] = startingPointAddress
        json["destinationLat"] = destinationCoordinate.latitude
        json["destinationLong"] = destinationCoordinate.longitude
        json["destinationAddress"] = destinationAddress
        json["passengers"] = passengers
        json["baggage"] = baggage
        json["leavingTime"] = leavingTime.toFirebase()
        json["foundSuggestion"] = foundSuggestion
        
        if suggestionsId != nil {
            json["suggestionsId"] = suggestionsId
        }
        
        if waitingTime != nil {
            json["waitingTime"] = waitingTime
        }
        
        if flightId != nil {
            json["flightId"] = flightId
        }
        
        json["createdOn"] = ServerValue.timestamp()
        
        return json
    }
}
