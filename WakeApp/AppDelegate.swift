//
//  AppDelegate.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/27.
//

import UIKit
import FirebaseCore
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseFunctions
import IQKeyboardManagerSwift
import GoogleMobileAds

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var transactionObserver: TransactionObserver!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
//        let settings = Firestore.firestore().settings
//        settings.isPersistenceEnabled = false
//        Firestore.firestore().settings = settings
        
        IQKeyboardManager.shared.enable = true
        Network.shared.setUp()
        
        Task {
            await PurchaseManager().refreshPurchasedProdunts()
        }
        
        transactionObserver = TransactionObserver()
        //ST -テスト用
//        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
//
//        let settings = Firestore.firestore().settings
//        settings.host = "127.0.0.1:8080"
//        settings.isPersistenceEnabled = false
//        settings.isSSLEnabled = false
//        Firestore.firestore().settings = settings
        
//        Functions.functions().useEmulator(withHost: "localhost", port: 5001)
//        Storage.storage().useEmulator(withHost: "localhost", port: 9199)
        //ED -テスト用
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

