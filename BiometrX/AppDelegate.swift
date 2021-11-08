//
//  AppDelegate.swift
//  BiometrX
//
//  Created by Mostafa Gamal on 2021-11-06.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var isFirsLaunch: Bool = false;

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        checkFirstLaunch()
        
        // Override point for customization after application launch.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "WelcomePage")
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: vc);
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func checkFirstLaunch() {
        let hasAlreadyLaunched = UserDefaults.standard.bool(forKey: "hasAlreadyLaunched")
        guard hasAlreadyLaunched else {
            print("App first Launch")
            UserDefaults.standard.set(true, forKey: "hasAlreadyLaunched")
            isFirsLaunch = true;
            
            //wipe out keychain
            do{
                print("Wiping Keychain values")
                try KeyStore.shared.removeAll()
            } catch{
                print("Exception wiping Keychain:\(error.localizedDescription)")
            }
            
            return
        }
    }


}

