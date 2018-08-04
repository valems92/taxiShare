import UIKit
import DshareFramework

class MyAccountViewController: UIViewController {
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x:0, y:100, width:50, height:50))
    
    @IBOutlet weak var userName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Model.instance.getCurrentUser() {(user) in
            let fName = user!["fName"] as! String
            let lName = user!["lName"] as! String
            
            self.userName.text = fName + " " + lName
        }
    }
    
    @IBAction func onLogOut(_ sender: UIButton) {
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Model.instance.signOutUser() { (error) in
            self.stopAnimatingActivityIndicator()
            if error != nil {
                Utils.instance.displayAlertMessage(messageToDisplay:(error?.localizedDescription)!, controller:self)
            }
            else{
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    func stopAnimatingActivityIndicator() {
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
}
