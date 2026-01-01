//
//  AppDelegate.swift
//  SVGDemo
//
//  Created by xiaoshanlin on 2026/1/1.
//

import UIKit
import SVGBucket

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        LogUseTime.measure("init resource"){
            Resource.initResource()
        }
        
        let controller =  ViewController.loadFromStoryboard()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
        return true
    }
    
    
}

