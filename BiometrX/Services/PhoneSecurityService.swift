//
//  PhoneSecurityService.swift
//  BiometrX
//
//  Created by macadmin on 2021-11-19.
//

import Foundation
import LocalAuthentication

protocol IPhoneSecurityService: AnyObject {
    func checkBiometrics(forPolicy policy: LAPolicy, callback:((Bool, BiometricError?)->Void)?) -> Bool
    var acceptNewBiometrics: Bool { get set }
}


public class PhoneSecurityService: IPhoneSecurityService {
    
    var acceptNewBiometrics: Bool  = false
    private let context = LAContext()
    private var newBiometryPolicyString: String?
    
    
    init(){
        context.localizedFallbackTitle = "Enter Pin"
    }
    func checkBiometrics(forPolicy policy: LAPolicy, callback: ((Bool, BiometricError?) -> Void)?) -> Bool {
        var error:NSError?
        
        if context.canEvaluatePolicy(policy, error: &error) {
            let reason = "Identify Yourself"
            context.evaluatePolicy(policy, localizedReason: reason){
                [weak self] success, authenticationError in
                if self?.biometricsChanged(domainPolicy: self?.context.evaluatedPolicyDomainState) ?? false
                {
                    print("Warning! Detected biometrics change!")
                    callback?(false, BiometricError.biometryChanged)
                } else if success {
                    callback?(success, nil)
                } else if let bError = error {
                    callback?(false, self?.biometricError(from: bError))
                }
                
            }
            return true;
        } else {
            return false;
        }
    }
    
    
    //MARK: Private functions
    //Maping function
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
    
    
    private  func biometricsChanged(domainPolicy: Data?) -> Bool {
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
                        if(acceptNewBiometrics){
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
    
    
    
    public static let shared: PhoneSecurityService =  PhoneSecurityService()
    
    
}
