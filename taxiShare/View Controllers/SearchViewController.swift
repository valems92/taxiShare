 import UIKit
 import GooglePlaces
 import DshareFramework
 import Foundation
 
 class SearchViewController: UIViewController, CLLocationManagerDelegate {
    let LEAVE_NOW_CONSTANT:CGFloat = 75
    let LEAVE_LATER_FLIGHT_CONSTANT:CGFloat = 365
    let LEAVE_LATER_NO_FLIGHT_CONSTANT:CGFloat = 250
    
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x:0, y:100, width:50, height:50))
    
    @IBOutlet weak var startingPoint: UITextField!
    @IBOutlet weak var destination: UITextField!
    @IBOutlet weak var passangers: UITextField!
    @IBOutlet weak var baggage: UITextField!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var airlineCode: UITextField!
    @IBOutlet weak var flightNumber: UITextField!
    @IBOutlet weak var waitingTime: UITextField!
    @IBOutlet weak var searchBtn: UIButton!
    
    @IBOutlet weak var searchTopConstraint: NSLayoutConstraint!
    
    var nowDate:Date!
    var leaveNow:Bool = true
    var isStaringPointChanged:Bool!
    var startingPointPlace: GMSPlace!
    var destinationPlace: GMSPlace!
    var flightId:Int?
    var flightArrivalDate:Date?
    var search: SearchSchema!
    
    var searchUpdateObserverId:Any?
    
    /*************** Life cycle *****************/
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        Utils.instance.initActivityIndicator(activityIndicator: activityIndicator, controller: self)
        
        searchTopConstraint.constant = LEAVE_NOW_CONSTANT
        _setCurrentPlace()
        
        startingPoint.addTarget(self, action: #selector(onChangeStartingPoint), for: .editingDidBegin)
        destination.addTarget(self, action: #selector(onChangeDestination), for: .editingDidBegin)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tap(gesture:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func tap(gesture: UITapGestureRecognizer) {
        airlineCode.resignFirstResponder()
        flightNumber.resignFirstResponder()
        waitingTime.resignFirstResponder()
        passangers.resignFirstResponder()
        baggage.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        _initTimePicker()
        
        searchUpdateObserverId = ModelNotification.SearchUpdate.observe(callback: { (suggestionsId, params) in
            Utils.instance.displayOpenChatAlert(suggestionsId: suggestionsId!, searchId: params as! String, controller: self)
        })
        
        Model.instance.startObserveCurrentUserSearches(type: SearchSchema.self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if searchUpdateObserverId != nil {
            ModelNotification.removeObserver(observer: searchUpdateObserverId!)
            searchUpdateObserverId = nil
        }
        
        Model.instance.clear()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSuggestionsFromSearch" {
            if let nextViewController = segue.destination as? SuggestionsViewController {
                nextViewController.search = self.search;
            }
        }
    }
    
    /**************** Google Auto Complete *****************/
    
    @objc func onChangeStartingPoint() {
        self.isStaringPointChanged = true
        presentAutoCompleteView()
    }
    
    @objc func onChangeDestination() {
        self.isStaringPointChanged = false
        presentAutoCompleteView()
    }
    
    func presentAutoCompleteView() {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    /**************** events *****************/
    
    @IBAction func onChangeLeavingTime(_ sender: UISegmentedControl) {
        leaveNow = (sender.selectedSegmentIndex == 0) ? true : false
        
        _showSelectFlight(place: startingPointPlace)
        
        waitingTime.isHidden = !leaveNow
        timePicker.isHidden = leaveNow
    }
    
    @IBAction func onChangeDatePicker(_ sender: UIDatePicker) {
        self._showSelectFlight(place: self.startingPointPlace)
    }
    
    @IBAction func onSearch(_ sender: UIButton) {
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        _validateSearch { (valid) in
            if valid {
                self.search = self._createSearch()
                Model.instance.addNewSearch(search: self.search, completionBlock: { (error) in
                    if error == nil {
                        self.performSegue(withIdentifier: "toSuggestionsFromSearch", sender: self)
                    } else {
                        Utils.instance.displayAlertMessage(messageToDisplay:(error?.domain)!, controller:self)
                    }
                })
            }
        }
    }
    
    /**************** Help functions *****************/
    
    func _initTimePicker() {
        nowDate = Date()
        timePicker.minimumDate = nowDate
        var oneWeekfromNow: Date { return (Calendar.current as NSCalendar).date(byAdding: .day, value: 7, to: timePicker.minimumDate!, options: [])! }
        timePicker.maximumDate = oneWeekfromNow
        timePicker.date = timePicker.minimumDate!
        timePicker.setValue(UIColor.white, forKeyPath: "textColor")
    }
    
    func _setCurrentPlace() {
        let placesClient: GMSPlacesClient! = GMSPlacesClient.shared()
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let placeLikelihoodList = placeLikelihoodList {
                for likelihood in placeLikelihoodList.likelihoods {
                    let place = likelihood.place
                    self._setStartingPoint(place: place)
                }
            }
        })
    }
    
    func _setStartingPoint(place: GMSPlace) {
        self.startingPoint.text = place.name
        self.startingPointPlace = place
        self._showSelectFlight(place: place)
    }
    
    func _setDestinationPoint(place: GMSPlace) {
        self.destination.text = place.name
        self.destinationPlace = place
    }
    
    func _showSelectFlight(place:GMSPlace) {
        var isAirport:Bool = false
        for type in place.types {
            if(type == "airport") {
                isAirport = true
                break;
            }
        }
        
        if isAirport {
            flightNumber.isHidden = leaveNow
            airlineCode.isHidden = leaveNow
            timePicker.datePickerMode = UIDatePickerMode.date
            searchTopConstraint.constant = (!leaveNow) ? LEAVE_LATER_FLIGHT_CONSTANT: LEAVE_NOW_CONSTANT;
        } else {
            flightNumber.isHidden = true
            airlineCode.isHidden = true
            timePicker.datePickerMode = UIDatePickerMode.dateAndTime
            searchTopConstraint.constant = LEAVE_LATER_NO_FLIGHT_CONSTANT
        }
    }
    
    func _createSearch() -> SearchSchema {
        let userId = Model.instance.getCurrentUserId()
        var lt:Date
        var wt:Int? = nil
        
        if (leaveNow) {
            lt = nowDate
            wt = Int(waitingTime.text!)!
        } else {
            lt = ((flightArrivalDate) != nil) ? flightArrivalDate! : timePicker.date;
        }
        
        return SearchSchema(userId: userId, startingPointCoordinate: startingPointPlace.coordinate, startingPointAddress: startingPointPlace.formattedAddress!, destinationCoordinate: destinationPlace.coordinate, destinationAddress: destinationPlace.formattedAddress!, passengers: Int(passangers.text!)!, baggage: Int(baggage.text!)!, leavingTime: lt, waitingTime: wt, flightId: flightId)
    }
    
    func _validateSearch(completionHandler: @escaping (_ valid: Bool) -> Void) {
        // Validate starting point, destination, passangers and baggage are not empty
        if ((startingPoint.text?.isEmpty)! || (destination.text?.isEmpty)! || (passangers.text?.isEmpty)!  || (baggage.text?.isEmpty)! || (leaveNow && (waitingTime.text?.isEmpty)!) || Int((passangers.text)!)! <= 0) {
            Utils.instance.displayAlertMessage(messageToDisplay:"Please fill out the mandatory fields to proceed", controller: self)
            completionHandler(false)
            
            // Validate the passangrs number
        } else if (Int((passangers.text)!)! > 3 ) {
            Utils.instance.displayAlertMessage(messageToDisplay:"The maximun number of the passangers for sharing one taxi is 4", controller: self)
            completionHandler(false)
        }
            
            // Validate flight number if needed
        else if (flightNumber.isHidden == false) {
            if ((flightNumber.text?.isEmpty)! || (airlineCode.text?.isEmpty)!) {
                Utils.instance.displayAlertMessage(messageToDisplay:"Please fill out the airline code and flight number", controller: self)
                completionHandler(false)
            } else {
                /* Flights.instance.validateFlightNumber(airlineCode: self.airlineCode.text, flightNumber: self.flightNumber.text, timePickerDate: self.timePicker.date) { (isValid) in
                    if !isValid {
                        Utils.instance.displayAlertMessage(messageToDisplay:"Invalid Flight", controller: self)
                    }
                    
                    completionHandler(isValid)
                }
                return */
            }
        }
        
        completionHandler(true)
    }
 }
 
 extension SearchViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        if(self.isStaringPointChanged) {
            self._setStartingPoint(place: place)
        } else {
            self._setDestinationPoint(place: place)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
 }
