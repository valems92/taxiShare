import UIKit
import DshareFramework

class MyDetailsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x:0, y:100, width:50, height:50))
    
    @IBOutlet weak var fName: UITextField!
    @IBOutlet weak var lName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var genderPicker: UIPickerView!
    
    let genderOptions = ["Male", "Female"]
     var userImage:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Utils.instance.initActivityIndicator(activityIndicator: activityIndicator, controller: self)
        
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        genderPicker.dataSource = self
        genderPicker.delegate = self
        
        Model.instance.getCurrentUser() {(user) in
            self.updateAllTextFields(user!)
            self.genderPicker.selectRow(Int(user!["gender"] as! String)!, inComponent: 0, animated: true)
            
            self.stopAnimatingActivityIndicator()
        }
    }
    
    func updateAllTextFields(_ user: [String: Any]) {
        self.fName.text = user["fName"] as? String
        self.lName.text = user["lName"] as? String
        self.email.text = user["email"] as? String
        self.phone.text = user["phoneNum"] as? String
        
        let imagePath = user["imagePath"] as! String
        if imagePath != Utils.instance.defaultIconUrl {
            Model.instance.getImage(urlStr: imagePath, callback: { (image) in
                self.image.image = image
            })
        }
    }
    
    @IBAction func onChangePhoto(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) || UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let controller = UIImagePickerController()
            controller.delegate = self
            present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func onSubmit(_ sender: UIButton) {
        let gender = self.genderPicker.selectedRow(inComponent: 0).description
        Model.instance.updateUserDetails(fName: fName.text, lName: lName.text, email: email.text!, phoneNum: phone.text!, gender: gender, image: userImage){ (error) in
            if error != nil {
                Utils.instance.displayMessageToUser(messageToDisplay:"Your changes has been saved", controller: self)
            }
        }
    }
    
    func stopAnimatingActivityIndicator() {
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genderOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let attributedString = NSAttributedString(string: genderOptions[row], attributes: [NSAttributedStringKey.foregroundColor : UIColor.white])
        return attributedString
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        userImage = info["UIImagePickerControllerOriginalImage"] as? UIImage
        self.image.image = userImage
        dismiss(animated: true, completion: nil)
    }
}
