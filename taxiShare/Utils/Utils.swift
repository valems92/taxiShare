import Foundation
import UIKit
import UserNotifications
import DshareFramework

class Utils {
    static let instance = Utils();
    public let defaultIconUrl = "https://firebasestorage.googleapis.com/v0/b/dsharefinalproject.appspot.com/o/defaultIcon.png?alt=media&token=0c2f430f-0b38-4ff0-8853-736c96f357db"
    
    func initActivityIndicator(activityIndicator:UIActivityIndicatorView, controller:UIViewController) {
        activityIndicator.center = controller.view.center;
        activityIndicator.backgroundColor = UIColor(red: 191.0/255.0, green:191.0/255.0, blue:191.0/255.0, alpha:1.0)
        activityIndicator.layer.cornerRadius = 10
        activityIndicator.hidesWhenStopped = true;
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.white;
        controller.view.addSubview(activityIndicator);
    }
    
    func displayAlertMessage(messageToDisplay:String, controller:UIViewController){
        let alertController = UIAlertController(title:"Error", message:messageToDisplay, preferredStyle:.alert);
        let OKAction = UIAlertAction(title:"OK", style:.default) { (action:UIAlertAction!) in
            print("OK tapped");
        }
        alertController.addAction(OKAction);
        controller.present(alertController, animated:true, completion:nil);
    }
    
    func displayMessageToUser(messageToDisplay:String, controller:UIViewController){
        let alertController = UIAlertController(title:"", message:messageToDisplay, preferredStyle:.alert);
        let OKAction = UIAlertAction(title:"OK", style:.default) { (action:UIAlertAction!) in
            print("OK tapped");
        }
        alertController.addAction(OKAction);
        controller.present(alertController, animated:true, completion:nil);
    }
    
    func displayOpenChatAlert(suggestionsId:[String], searchId:String, controller:UIViewController) {
        let alertController = UIAlertController(title:"Message", message:"A match was found for one of your searches!", preferredStyle:.alert);
        
        let OKAction = UIAlertAction(title:"Open Chat", style:.default) { (action:UIAlertAction!) in
            let storyBoard = UIStoryboard(name: "Main", bundle: nil);
            let viewController = storyBoard.instantiateViewController(withIdentifier: "ChatPage") as! ChatViewController;
            
            viewController.users = suggestionsId
            viewController.senderId = Model.instance.getCurrentUserId()
            
            Model.instance.removeValueFromSearch(searchId: searchId, key: "suggestionsId")
            
            controller.navigationController!.pushViewController(viewController, animated: true)
        }
        
        alertController.addAction(OKAction)
        controller.present(alertController, animated:true, completion:nil)
    }
}
