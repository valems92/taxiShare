import UIKit
import DshareFramework

class ChangePasswordViewController: UIViewController {
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x:0, y:100, width:50, height:50))
    
    @IBOutlet weak var currentPassword: UITextField!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var reNewPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Utils.instance.initActivityIndicator(activityIndicator: activityIndicator, controller: self)
    }
    
    @IBAction func onChangePassowrd(_ sender: UIButton) {
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Model.instance.updatePassword(oldPassword: self.currentPassword.text, newPassword: self.newPassword.text, reNewPassword: self.reNewPassword.text) { (error) in
            self.stopAnimatingActivityIndicator()
            
            if error != nil {
                Utils.instance.displayAlertMessage(messageToDisplay: (error?.domain)!, controller: self)
            } else {
                Utils.instance.displayMessageToUser(messageToDisplay: "Password changed successfully", controller: self)
            }
        }
    }
    
    func stopAnimatingActivityIndicator() {
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
}
