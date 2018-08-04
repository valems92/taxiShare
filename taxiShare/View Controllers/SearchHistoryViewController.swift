import UIKit
import DshareFramework

class SearchesViewCell: UITableViewCell {
    @IBOutlet weak var destination: UILabel!
    @IBOutlet weak var startPoint: UILabel!
    @IBOutlet weak var icon: UIImageView!
    
    var search: SearchSchema?
}

class SearchHistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x:0, y:100, width:50, height:50))
    
    @IBOutlet weak var table: UITableView!
    var searches: [SearchSchema]?
    var selectedSearch: SearchSchema?
    
    var searchUpdateObserverId:Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Utils.instance.initActivityIndicator(activityIndicator: activityIndicator, controller: self)
        
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        table.delegate = self
        table.dataSource = self
        
        Model.instance.getCurrentUserSearches(type: SearchSchema.self) {(searches) in
            self.searches = searches
            self.table.reloadData()
            
            self.stopAnimatingActivityIndicator()
            
            if self.searches?.count == 0 {
                self.table.alpha = 0
                self._alertNoSearches()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func _alertNoSearches(){
        let alertController = UIAlertController(title:"", message: "Oops! There are no recent searches to show", preferredStyle:.alert)
        let OKAction = UIAlertAction(title:"OK", style:.default) { (action:UIAlertAction!) in
            self.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated:true, completion:nil)
    }
    
    func stopAnimatingActivityIndicator() {
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searches != nil {
            return (searches?.count)!
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searches != nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "specialCell", for: indexPath) as! SearchesViewCell
            let search = searches?[indexPath.row]
            
            cell.destination.text = search!.destinationAddress
            cell.startPoint.text = search!.startingPointAddress
            cell.search = search
            
            if search?.foundSuggestion == false {
                cell.icon?.image = UIImage(named: "x")
            } else {
                cell.icon?.image = UIImage(named: "v")
            }
            
            return cell
        }
        
        return UITableViewCell.init()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedSearch = searches?[indexPath.row]
        if self.selectedSearch?.foundSuggestion == false {
            self.performSegue(withIdentifier: "toSuggestionsFromSearchHistory", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSuggestionsFromSearchHistory" {
            if let nextViewController = segue.destination as? SuggestionsViewController {
                nextViewController.search = self.selectedSearch;
            }
        }
    }
}

