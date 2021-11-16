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

enum PassCodeMode {
    case normal
    case activateBiometry
}
class WelcomeViewController: UIViewController {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var pinLabel: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var biometricsButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    private let appDelegate: AppDelegate  = UIApplication.shared.delegate as! AppDelegate
    private var passcodeSet: Bool = false;
    private var passCode: String?
    private let context = LAContext()
    private var newBiometryPolicyString: String?
    private var passcodeMode: PassCodeMode = .normal
    private var storeNewPolicy: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white;
        
        context.localizedFallbackTitle = "Enter Pin"
        
        passcodeSet = initPasscode()
        if(!passcodeSet){
            signInButton.setTitle("Setup Pin", for: .normal)
            statusLabel.text = "Please enter 6 digit code"
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
        statusLabel.text = ""
        
        if passcodeSet {
            if pin == passCode {
                if passcodeMode == .normal{
                    loginSuccess()
                } else {
                    toggleBiometry(isHidden: false)
                    storeNewPolicy = true
                    pinLabel.text = ""
                }
                
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
                toggleBiometry(isHidden: false)
                pinLabel.text = ""
                print("passcode created")
            }
            
        }
    }
    
    private func toggleBiometry(isHidden: Bool){
        biometricsButton.isHidden = isHidden
    }
    
    @IBAction func authBiometricsTapped(_ sender: Any) {
        print("Login with biometrics")
        if !checkBiometrics(forPolicy: .deviceOwnerAuthenticationWithBiometrics, callback: processBiometrics){
            if !checkBiometrics(forPolicy: .deviceOwnerAuthentication, callback: processPasscoderesults) {
                alertUser(message: "Its recommended that you use Biometrics or Passcode to secure your wallet\nUse Pin to unlock your wallet")
            }
        }
    }
    
    func processBiometrics(success: Bool, error: BiometricError?) -> Void {
        DispatchQueue.main.async {
            [weak self] in
            if success {
                print("Success")
                self?.loginSuccess()
                return
            }
            
            switch(error){
            case .biometryChanged:
                print("Detected biometrics change")
                self?.passcodeMode = .activateBiometry
                self?.toggleBiometry(isHidden: true)
                self?.statusLabel.text = "Enter passcode to activate biometrics"
                break
            default:
                self?.alertUser(message: "\(String(describing: error?.errorDescription))")
                break
            }
        }
    }
    
    func processPasscoderesults(success: Bool, error: Error?) -> Void {
        
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
    
    func checkBiometrics(forPolicy policy: LAPolicy, callback:@escaping (Bool, BiometricError?)->Void) -> Bool {
        var error:NSError?
        
        if context.canEvaluatePolicy(policy, error: &error) {
            let reason = "Identify Yourself"
            context.evaluatePolicy(policy, localizedReason: reason){
                [weak self] success, authenticationError in
                if self?.biometricsChanged(domainPolicy: self?.context.evaluatedPolicyDomainState) ?? false
                {
                    print("Warning! Detected biometrics change!")
                    callback(false, BiometricError.biometryChanged)
                } else if success {
                    callback(success, nil)
                } else if let bError = error {
                    callback(false, self?.biometricError(from: bError))
                }
                
            }
            return true;
        } else {
            return false;
        }
        
    }
    
    func biometricsChanged(domainPolicy: Data?) -> Bool {
        print("Checking domainPolicy")
        if let domainState = domainPolicy {
            print("found domain policy")
            // Enrollment state the same
            let bData = domainState.base64EncodedData()
            if let decodedString = String(data: bData, encoding: .utf8) {
                print("Decoded Value: \(decodedString)")
                if let oldValue = StorgeService.shared.getString(key: KEY_BIOMETRICS_POL) {
                    
                    print("old stored policy:\(oldValue)")
                    print("Biomertics changed? \(oldValue != decodedString)")
                    if oldValue != decodedString {
                        newBiometryPolicyString = decodedString
                        if(storeNewPolicy){
                            print("Stored new policy")
                            StorgeService.shared.saveData(key: KEY_BIOMETRICS_POL, object: decodedString)
                            return false
                        }
                    }
                    return oldValue != decodedString;
                } else {
                    print("Saving policy for this biometrics ..")
                    StorgeService.shared.saveData(key: KEY_BIOMETRICS_POL, object: decodedString)
                }
            }
            
        } else {
            // Enrollment state changed
            print("No domain policy")
            
        }
        return false
    }
    
    
    private func biometricError(from nsError: NSError) -> BiometricError {
        let error: BiometricError
        
        switch nsError {
        case LAError.authenticationFailed:
            error = .authenticationFailed
        case LAError.userCancel:
            error = .userCancel
        case LAError.userFallback:
            error = .userFallback
        case LAError.biometryNotAvailable:
            error = .biometryNotAvailable
        case LAError.biometryNotEnrolled:
            error = .biometryNotEnrolled
        case LAError.biometryLockout:
            error = .biometryLockout
        default:
            error = .unknown
        }
        
        return error
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
