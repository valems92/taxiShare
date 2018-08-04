import UIKit
import CoreLocation
import DshareFramework

class RootViewController: UIViewController, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Initialization.instance.requestLocationAuthorization(delegate: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        Model.instance.isLoggedIn { (isLoggedIn) in
            if isLoggedIn {
                self.performSegue(withIdentifier: "toSearchFromHome", sender: self)
            }
        }
    }
    
}

