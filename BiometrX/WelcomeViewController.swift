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
    static let WalletHandle: String = "WalletHandle"
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
    @IBOutlet weak var isStrictModeSwitch: UISwitch!
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var resetImageView: UIImageView!
    @IBOutlet weak var isUserPresenceSwitch: UISwitch!
    @IBOutlet weak var sysProtSwitch: UISwitch!
    @IBOutlet weak var bioStAndPasscodeSwitch: UISwitch!
    
    private let appDelegate: AppDelegate  = UIApplication.shared.delegate as! AppDelegate
    private var passcodeSet: Bool = false;
    private var passCode: String?
    private var walletHandle: String?
    private var passcodeMode: PassCodeMode = .normal
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.backgroundColor = UIColor.white;
        resetImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resetApp)))
        resetImageView.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        isUserPresenceSwitch.addTarget(self, action: #selector(switchStateDidChangeUserPr(_:)), for: .valueChanged)
        sysProtSwitch.addTarget(self, action: #selector(switchStateDidChangeSysProt(_:)), for: .valueChanged)
        bioStAndPasscodeSwitch.addTarget(self, action: #selector(switchStateDidChangBioAndPass(_:)), for: .valueChanged)
        initLogic()
      
       
        // Do any additional setup after loading the view.
    }
    
//    func initLogic(){
//
//        let cond1 = StorgeService.shared.getString(key: KEY_ACCESSCONT_POL_USERPRESENCE)
//        let cond2 = StorgeService.shared.getString(key: KEY_ACCESSCONT_POL_SYSPROT)
//
//        //MARK: Init Logic
//        //First check if there is passcode in keychain
//        passcodeSet = initPasscode()
//        if(!passcodeSet){
//            signInButton.setTitle("Setup Pin", for: .normal)
//            statusLabel.text = "Please enter 6 digit code"
//        }
//
//
//        if passcodeSet &&
//             (StorgeService.shared.getString(key: KEY_ACCESSCONT_POL_USERPRESENCE) != nil
//              || StorgeService.shared.getString(key: KEY_ACCESSCONT_POL_SYSPROT) != nil
//              || StorgeService.shared.getString(key: KEY_ACCESSCONT_POL_BIOANDPASS) != nil){
//            //That means that the user has already been asked for auth when app started
//            //No need to re-ask the user again just sign in
//            loginSuccess()
//            return
//        }
//
//        toggleBiometry(isHidden: !passcodeSet)
//
//    }
    

    
    
    @objc func switchStateDidChangeUserPr(_ sender:UISwitch){
        if (sender.isOn == true){
            StorgeService.shared.saveData(key: KEY_ACCESSCONT_POL_USERPRESENCE, object: "on")
        }
        else{
            StorgeService.shared.saveData(key: KEY_ACCESSCONT_POL_USERPRESENCE, object: nil)
        }
    }
    
    @objc func switchStateDidChangeSysProt(_ sender:UISwitch){
        if (sender.isOn == true){
            StorgeService.shared.saveData(key: KEY_ACCESSCONT_POL_SYSPROT, object: "on")
        }
        else{
            StorgeService.shared.saveData(key: KEY_ACCESSCONT_POL_SYSPROT, object: nil)
        }
    }
    
    @objc func switchStateDidChangBioAndPass(_ sender:UISwitch){
        if (sender.isOn == true){
            StorgeService.shared.saveData(key: KEY_ACCESSCONT_POL_BIOANDPASS, object: "on")
        }
        else{
            StorgeService.shared.saveData(key: KEY_ACCESSCONT_POL_BIOANDPASS, object: nil)
        }
    }
    
    func initLogic() {
        print("Trying to read wallet handle value")

        //MARK: Init Logic
        //First check if there is passcode in keychain
        let walletHandleSet = initWalletHandle()
        let coomonCondition = (StorgeService.shared.getString(key: KEY_ACCESSCONT_POL_USERPRESENCE) != nil
                               || StorgeService.shared.getString(key: KEY_ACCESSCONT_POL_SYSPROT) != nil
                               || StorgeService.shared.getString(key: KEY_ACCESSCONT_POL_BIOANDPASS) != nil)
        
        if(walletHandleSet  && coomonCondition){
            loginSuccess()
            return
        } else {
            //Then check passcode
            passcodeSet = initPasscode()
            if(!passcodeSet){
                signInButton.setTitle("Setup Pin", for: .normal)
                statusLabel.text = "Please enter 6 digit code"
            }


            if passcodeSet && coomonCondition {
                //That means that the user has already been asked for auth when app started
                //No need to re-ask the user again just sign in
                loginSuccess()
                return
            }

            toggleBiometry(isHidden: !passcodeSet)
            
        }
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
    
    func initWalletHandle() -> Bool {
        print("checking wallet handle ..")
        do {
            if let passc = try KeyStore.shared.getValue(forKey: Keys.WalletHandle) {
                passCode = passc
                print("Found handle:\(passc)")
                return true;
            }
        }catch {
            alertUser(message: error.localizedDescription)
        }
        
        print("Handle not set")
        
        return false;
    }
    
    //Resets the app no need to uninstall it
    @objc func resetApp(){
        do{
            print("Wiping Keychain values")
            try KeyStore.shared.removeAll()
            StorgeService.shared.saveData(key: KEY_ACCESSCONT_POL_SYSPROT, object: nil)
            StorgeService.shared.saveData(key: KEY_ACCESSCONT_POL_USERPRESENCE, object: nil)
            StorgeService.shared.saveData(key: KEY_ACCESSCONT_POL_BIOANDPASS, object: nil)
            DispatchQueue.main.async {
                [weak self] in
                self?.alert("Restart the App")
            }
        } catch{
            print("Exception wiping Keychain:\(error.localizedDescription)")
        }
    }
    
    //Main function that takes user passcode input and
    //acts in both situations
    //Situation 1- Passcode set -> then check passcode match -> Yes -> Enable biometry (if biometry changed) or Login
    //Situation 2- Passcode not set -> create passcode -> show biometrics login
    
    //Saving 2 values in keychain in 2 separet containers
    
    @IBAction func signInPinCodeAction(_ sender: Any) {
        guard let pin = pinLabel.text else {
            alertUser(message: "Please enter pin")
            return
        }
        statusLabel.text = ""
        
        if passcodeSet {
        
            if pin == passCode {
                
                if passcodeMode == .normal{
                    //Normal passcode entry attempt
                    loginSuccess()
                    
                } else {
                    
                    //This time user entered passcode to re-enable biometry after biometry change
                    toggleBiometry(isHidden: false)
                    PhoneSecurityService.shared.acceptNewBiometrics = true
                    pinLabel.text = ""
                }
                
            } else {
                alertUser(message: "Incorrect pin")
            }
            
        } else {
            
            //MARK: Saving passcode first time
            print("saving passcode")
            
            var passSavingMode:PasscodeAccessPolicy = .relaxed;
            var walletSavingMode:PasscodeAccessPolicy = .relaxed;
            var isDoubleMode = false
            //check that first, since its priority is higher
            if bioStAndPasscodeSwitch.isOn {
                passSavingMode  = .applicationPass
                walletSavingMode = .biometrySet
                isDoubleMode = true
            } else if sysProtSwitch.isOn {
                passSavingMode  = .applicationPass
            } else if isUserPresenceSwitch.isOn {
                passSavingMode = .withUserPresence
            } else if isStrictModeSwitch.isOn {
                passSavingMode = .strict
            }
            
            if isDoubleMode {
                print("Double mode detected")
                //first save app passcode
                if let errorSaving = KeyStore.shared.store(str: pin, forKey: Keys.KeyPasscode, strictMode: passSavingMode) {
                    alertUser(message: errorSaving);
                    return
                }
                
                print("passcode saved with .applicationPass flag")
                
                //then save wallet handle in different mode
                if let errorSaving = KeyStore.shared.store(str: "Wallet123", forKey: Keys.WalletHandle, strictMode: walletSavingMode) {
                    alertUser(message: errorSaving);
                    return
                }
                
                print("wallet handle saved with .biometrySet flag")
                
                
            } else {
                
                if let errorSaving = KeyStore.shared.store(str: pin, forKey: Keys.KeyPasscode, strictMode: passSavingMode) {
                    alertUser(message: errorSaving);
                    return
                }
                
               
            }
            
            passcodeSet = true;
            passCode = pin
            signInButton.setTitle("Enter Pin", for: .normal)
            toggleBiometry(isHidden: false)
            pinLabel.text = ""
            print("passcode created")
           
            
        }
    }
    
    private func toggleBiometry(isHidden: Bool){
        biometricsButton.isHidden = isHidden
        settingsView.isHidden = !isHidden
        resetImageView.isHidden = isHidden
    }
    
    
    
    @IBAction func authBiometricsTapped(_ sender: Any) {
        print("Login with biometrics")
        if !PhoneSecurityService.shared.checkBiometrics(forPolicy: .deviceOwnerAuthenticationWithBiometrics, callback: processBiometrics){
            if !PhoneSecurityService.shared.checkBiometrics(forPolicy: .deviceOwnerAuthentication, callback: processPasscoderesults) {
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
        DispatchQueue.main.async {
            [weak self] in
            if success {
                print("Success")
                self?.loginSuccess()
                return
            } else {
                self?.alert(error?.localizedDescription ?? "Undefined error")
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
    
   
    
    func alert(_ message: String){
        let alert = UIAlertController(title: "Attention!", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
