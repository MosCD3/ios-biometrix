//
//  WelcomeViewController.swift
//  BiometrX
//
//  Created by Mostafa Gamal on 2021-11-06.
//

import UIKit
import LocalAuthentication

struct Keys {
    static let KeyPasscode: String = "Passcode"
}
class WelcomeViewController: UIViewController {

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var pinLabel: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var biometricsButton: UIButton!
    
    private let appDelegate: AppDelegate  = UIApplication.shared.delegate as! AppDelegate
    private var passcodeSet: Bool = false;
    private var passCode: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white;
        passcodeSet = initPasscode()
        if(!passcodeSet){
            signInButton.setTitle("Setup Pin", for: .normal)
            biometricsButton.isHidden = true
        }
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        // Do any additional setup after loading the view.
    }
    
    func initPasscode() -> Bool {
        print("checking passcode ..")
        do {
            if let passc = try KeyStore.shared.getValue(forKey: Keys.KeyPasscode) {
                passCode = passc
                print("Found passcode:\(passc)")
                return true;
            }
        }catch {
            alertUser(message: error.localizedDescription)
        }
        
        print("Passcode not set")
        
        return false;
    }
    
    @IBAction func signInPinCodeAction(_ sender: Any) {
        guard let pin = pinLabel.text else {
            alertUser(message: "Please enter pin")
            return
        }
        
        if passcodeSet {
            if pin == passCode {
                loginSuccess()
            } else {
                alertUser(message: "Incorrect pin")
            }
            
        } else {
            
           
            print("saving passcode")
            if let errorSaving = KeyStore.shared.store(str: pin, forKey: Keys.KeyPasscode) {
                alertUser(message: errorSaving);
                return
            } else {
                passcodeSet = true;
                passCode = pin
                signInButton.setTitle("Enter Pin", for: .normal)
                biometricsButton.isHidden = false
                pinLabel.text = ""
                print("passcode created")
            }
            
        }
    }
    
    @IBAction func authBiometricsTapped(_ sender: Any) {
        print("Login with biometrics")
        let context = LAContext()
        
        context.localizedFallbackTitle = "Enter Pin"
        
        var error:NSError?
        
        
        //Start with Biometrics
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            let reason = "Identify Yourself"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason){
                [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        print("Success")
                        self?.loginSuccess()
                    } else {
                        self?.alertUser(message: "Error\(authenticationError?.localizedDescription)")
                        
                    }
                }
                
               
            }
        } else {
            
            //If not, then check phone passcode
            print("Biometrics error!:\(error?.localizedDescription)")
            print("Trying phone passcode")
//            alertUser(message: "Biometrics not available here!:\(error)")
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error){
                let reason = "Identify Yourself"
                
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason){
                    [weak self] success, authenticationError in
                    DispatchQueue.main.async {
                        if success {
                            print("Success")
                            self?.loginSuccess()
                        } else {
                            self?.alertUser(message: "Error\(authenticationError?.localizedDescription)")
                            
                        }
                    }
                    
                   
                }
            } else {
                
                //If not, then check phone passcode
                print(".deviceOwnerAuthentication failed:\(error?.localizedDescription ?? "Undefined error")")
                alertUser(message: "Its recommended that you use Biometrics or Passcode to secure your wallet\nUse Pin to unlock your wallet")
            }
        }
    }
    
    func alertUser(message: String)->Void{
        let ac = UIAlertController(title: "Attention!", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(ac, animated: true)
    }
    
    
    @objc func dismissKeyboard() {
      view.endEditing(true)
    }
    
    
    func loginSuccess() {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "AfterLogin") {
            self.navigationController!.pushViewController(vc, animated: true)
        }
       
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
