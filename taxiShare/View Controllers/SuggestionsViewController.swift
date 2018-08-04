import UIKit
import CoreLocation
import DshareFramework

struct UserData {
    var user: [String: Any]?
    var image: UIImage?
}

struct SuggestionData {
    var userId: String
    var search: SearchSchema
    var distance: Double
}

class SuggestionTableViewCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var data: UILabel!
    @IBOutlet weak var suggestionImage: UIImageView!
    
    var user: [String: Any]?
    var search: SearchSchema?
}

class SuggestionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SuggestionsProtocol {
    let MAX_KM_DISTANCE_DESTINATION:Double = 10
    let MAX_KM_DISTANCE_STARTING_POINT:Double = 5
    
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()
    
    var search: SearchSchema!
    var usersData = [String : UserData]()
    var suggestions = [String : SuggestionData]()
    var sortedSuggestions:[SuggestionData]?
    
    var suggestionUpdateObserverId:Any?
    var searchUpdateObserverId:Any?
    
    @IBOutlet weak var chat: UIButton!
    @IBOutlet weak var table: UITableView!
    
    /*************** Life cycle *****************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = false
        
        Utils.instance.initActivityIndicator(activityIndicator: activityIndicator, controller: self)
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        table.delegate = self
        table.dataSource = self
        
        _enabledChatBtn(false)
        _getSuggestions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        suggestionUpdateObserverId = ModelNotification.SuggestionsUpdate.observe(callback: self._suggestionsChanged)
        
        searchUpdateObserverId = ModelNotification.SearchUpdate.observe(callback: { (suggestionsId, params) in
            Utils.instance.displayOpenChatAlert(suggestionsId: suggestionsId!, searchId: params as! String, controller: self)
        })
        
        Model.instance.startObserveCurrentUserSearches(type: SearchSchema.self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        _clear()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func stopAnimatingActivityIndicator() {
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    // Once chat btn is pressed, go to chat view after changing user and suggestions selected searches in DB
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChatFromSuggestions" {
            var usersFcmTokens:[String] = []
            var users:[String] = []
            var searches:[SearchSchema] = []
            
            if let nextViewController = segue.destination as? ChatViewController {
                // Get selected suggestions
                if table.indexPathsForSelectedRows != nil {
                    for rowIndex in table.indexPathsForSelectedRows! {
                        let cell = table.cellForRow(at: rowIndex) as! SuggestionTableViewCell
                        let userId = cell.user!["id"] as! String
                        
                        searches.append(cell.search!)
                        users.append(userId)
                        
                        if ((self.usersData[userId] != nil) && (self.usersData[userId]?.user != nil)
                            && ((self.usersData[userId]!.user?["fcmToken"]) != nil)){
                            usersFcmTokens.append(self.usersData[userId]!.user!["fcmToken"]! as! String)
                        }
                    }
                }
                
                // Init chat parameters - users (participates) and user who trigger the chat
                let cuurentUserId = Model.instance.getCurrentUserId()
                nextViewController.users = users
                nextViewController.senderId = cuurentUserId
                nextViewController.usersFcmTokens = usersFcmTokens
                
                // Update all participates search in DB
                self._clear()
                Model.instance.updateSearch(searchId: self.search.id, value: ["foundSuggestion": true])
                
                users.append(cuurentUserId)
                for i in 0...searches.count - 1 {
                    let s = searches[i]
                    Model.instance.updateSearch(searchId: s.id, value: ["foundSuggestion": true, "suggestionsId": users.filter({ (user) -> Bool in
                        user != s.userId
                    })])
                }
            }
        }
    }
    
    /*************** Table *****************/
    
    // Enable chat btn when a suggestion is selected
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _enabledChatBtn(true)
    }
    
    // Disable chat btn when there is no suggestion selected
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.indexPathsForSelectedRows == nil {
            _enabledChatBtn(false)
        }
    }
    
    // Design cell in table
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.backgroundColor = (indexPath.row % 2 == 0) ? UIColor(red: 1, green: 0.9608, blue: 0.9569, alpha: 1.0) : UIColor.white
    }
    
    // Returns number of suggestions
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    // Returns a cell with the name, distance, passangers number and baggage of each suggestion
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SuggestionTableViewCell
        
        let suggestion = sortedSuggestions![indexPath.row]
        let suggUserData = self.usersData[suggestion.userId]
        
        cell.name.text = (suggUserData!.user!["fName"] as! String) + " " + (suggUserData!.user!["lName"] as! String)
        cell.data.text = "Distance: " + String(format: "%.2f", suggestion.distance) + " km, Passangers: " + String(suggestion.search.passengers) + ", Baggage: " + String(suggestion.search.baggage)
        
        cell.user = suggUserData!.user!
        cell.search = suggestion.search
        
        if let image = suggUserData!.image {
            cell.suggestionImage?.image = image
        } else {
            Model.instance.getImage(urlStr: suggUserData!.user!["imagePath"] as! String, callback: { (image) in
                cell.suggestionImage?.image = image
                self.usersData[suggestion.userId]!.image = image
            })
        }
        
        return cell
    }
    
    /**************** SuggestionsProtocol *****************/
    
    func filterSuggestion(_ suggestion: SchemaProtocol) -> Bool {
        if let sg = suggestion as? SearchSchema {
            if sg.userId == search.userId ||  sg.foundSuggestion {
                return true
            }
            
            let destDistance = self._calcDistance(search.destinationCoordinate, sg.destinationCoordinate)
            let stDistance = self._calcDistance(search.startingPointCoordinate, sg.startingPointCoordinate)
            if (destDistance > self.MAX_KM_DISTANCE_DESTINATION || stDistance > self.MAX_KM_DISTANCE_STARTING_POINT) {
                return true
            }
            
            if ((sg.passengers + self.search.passengers) >= 5) {
                return true
            }
        }
        
        return false
    }
    
    /**************** Help functions *****************/
    
    private func _suggestionsChanged(search:SchemaProtocol?, params:Any?) -> Void {
        if let s = search as? SearchSchema {
            if let status = params as? String {
                switch (status) {
                case "Added":
                    if suggestions[s.id] == nil {
                        self._addSuggestionOnListening(s)
                    }
                    break;
                case "Removed":
                    if self.suggestions[s.id] != nil {
                        self._removeSuggestionOnListening(s)
                    }
                    break;
                default:
                    if suggestions[s.id] != nil && s.foundSuggestion {
                        self._removeSuggestionOnListening(s)
                    } else if suggestions[s.id] == nil && s.foundSuggestion == false {
                        self._addSuggestionOnListening(s)
                    }
                    break;
                }
            }
        }
    }
    
    private func _removeSuggestionOnListening(_ search:SearchSchema) {
        self.suggestions.removeValue(forKey: search.id)
        self._orderSuggestions()
        self.table.reloadData()
    }
    
    private func _addSuggestionOnListening(_ search:SearchSchema) {
        self._addSuggestion(suggestion: search)
        self._orderSuggestions()
        self.table.reloadData()
    }
    
    private func _calcDistance(_ searchCoordinate:CLLocationCoordinate2D ,_ coordinate:CLLocationCoordinate2D)->Double {
        let searchLocation = CLLocation(latitude: searchCoordinate.latitude, longitude: searchCoordinate.longitude)
        let suggestionLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return (searchLocation.distance(from: suggestionLocation) / 1000)
    }
    
    private func _enabledChatBtn(_ isEnabled:Bool) {
        chat.isEnabled = isEnabled
        chat.alpha = (isEnabled) ? 1 : 0.5
    }
    
    private func _getSuggestions() {
        Model.instance.FilterSuggestions(type: SearchSchema.self, observe: true, suggClass: self) { (suggestions, usersData)  in
            for sg in suggestions {
                let distance = self._calcDistance(self.search.destinationCoordinate, sg.destinationCoordinate)
                self.suggestions[sg.id] = SuggestionData(userId: sg.userId, search: sg, distance: distance)
            }
            
            for (userId, data) in usersData {
                self.usersData[userId] = UserData()
                self.usersData[userId]?.user = data
            }
            
            self._orderSuggestions()
            self.table.reloadData()
            
            self.stopAnimatingActivityIndicator()
            
            if self.suggestions.count == 0 {
                self.table.alpha = 0
                self._alertNoSuggestions()
            }
        }
    }
    
    private func _addSuggestion(suggestion:SearchSchema) {
        let distance = self._calcDistance(self.search.destinationCoordinate, suggestion.destinationCoordinate)
        self.suggestions[suggestion.id] = SuggestionData(userId: suggestion.userId, search: suggestion, distance: distance)
        
        if usersData[suggestion.userId] == nil {
           Model.instance.getUserById(id: suggestion.userId) { (json) in
                self.usersData[suggestion.userId] = UserData()
                self.usersData[suggestion.userId]!.user = json
            }
        }
    }
    
    func _alertNoSuggestions(){
        let alertController = UIAlertController(title:"", message: "Oops! there are no suggestions for you right now. Please try again later", preferredStyle:.alert)
        let OKAction = UIAlertAction(title:"OK", style:.default) { (action:UIAlertAction!) in
            self.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated:true, completion:nil)
    }
    
    private func _orderSuggestions() {
        sortedSuggestions = Array(suggestions.values).sorted { (first, second) -> Bool in
            first.distance < second.distance
        }
    }
    
    func _clear() {
        if suggestionUpdateObserverId != nil {
            ModelNotification.removeObserver(observer: suggestionUpdateObserverId!)
            suggestionUpdateObserverId = nil
        }
        
        if searchUpdateObserverId != nil {
            ModelNotification.removeObserver(observer: searchUpdateObserverId!)
            searchUpdateObserverId = nil
        }
        
        Model.instance.clear()
    }
}
