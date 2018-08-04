import UIKit
import DshareFramework
 
 class RegisterViewController: UIViewController,UIPickerViewDataSource, UIPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate {
    var pickerDataSource = ["Male", "Female"]
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x:0, y:100, width:50, height:50))
    var userImage:UIImage?
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var rePassword: UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var gender: UIPickerView!
    @IBOutlet weak var image: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gender.dataSource = self
        self.gender.delegate = self
        
        Utils.instance.initActivityIndicator(activityIndicator: activityIndicator, controller: self)
        
        //Dismiss keyboard when touching anywhere outside text field
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tap(gesture:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func tap(gesture: UITapGestureRecognizer) {
        email.resignFirstResponder()
        password.resignFirstResponder()
        rePassword.resignFirstResponder()
        firstName.resignFirstResponder()
        lastName.resignFirstResponder()
        phoneNumber.resignFirstResponder()
    }
    
    func stopAnimatingActivityIndicator() {
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let attributedString = NSAttributedString(string: pickerDataSource[row], attributes: [NSAttributedStringKey.foregroundColor : UIColor.white])
        return attributedString
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        userImage = info["UIImagePickerControllerOriginalImage"] as? UIImage
        self.image.image = userImage
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onAddPhoto(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) || UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let controller = UIImagePickerController()
            controller.delegate = self
            present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func onCreateUser(_ sender: UIButton) {
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Model.instance.addNewUser(email:email.text, password:password.text, rePassword: rePassword.text ,fName:firstName.text, lName:lastName.text, phoneNum:phoneNumber.text, gender:gender.selectedRow(inComponent: 0).description, userImage:userImage) { (userId, err) in
            self.stopAnimatingActivityIndicator()
            if err != nil {
                Utils.instance.displayAlertMessage(messageToDisplay:(err?.domain)!, controller:self)
            } else {
                self.performSegue(withIdentifier: "toSearchFromRegister", sender: self)
            }
        }
    }
 }
 
