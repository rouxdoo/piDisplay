//
//  AppDelegate.swift
//  piDisplay
//
//  Created by Ian Jones on 12/31/18.
//  Copyright © 2018 Ian Jones. All rights reserved.
//

import UIKit
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(activationState)
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        //
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        //
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let brightness = message["brightness"]
        let backlight = message["backlight"]
        let pwr = message["pwr"]
        let act = message["act"]
        DispatchQueue.main.async {
            print("didReceiveMessage without reply handler")
            if (brightness != nil) {
                self.mainVc?.brightness = Float(brightness as! String)!
                self.mainVc?.brightnessSlider.value = Float(brightness as! String)!
                self.mainVc?.brightnessSliderChanged(self.mainVc?.brightnessSlider as Any)
            }
            if backlight != nil {
                self.mainVc?.systemBacklight = Float(backlight as! String)!
                if self.mainVc!.systemBacklight! > 0.0 {
                    self.mainVc?.backlightSwitch.isOn = true
                } else {
                    self.mainVc?.backlightSwitch.isOn = false
                }
                self.mainVc?.backlightSwitchPressed(self.mainVc?.backlightSwitch as Any)
            }
            if pwr != nil {
                self.mainVc?.systemPwr = Float(pwr as! String)!
                if self.mainVc!.systemPwr! > 0.0 {
                    self.mainVc?.pwrLedSwitch.isOn = true
                } else {
                    self.mainVc?.pwrLedSwitch.isOn = false
                }
                self.mainVc?.pwdLedPressed(self.mainVc?.pwrLedSwitch as Any)
            }
            if act != nil {
                self.mainVc?.systemAct = Float(act as! String)!
                if self.mainVc!.systemAct! > 0.0 {
                    self.mainVc?.actLedSwitch.isOn = true
                } else {
                    self.mainVc?.actLedSwitch.isOn = false
                }
                self.mainVc?.actLedPressed(self.mainVc?.actLedSwitch as Any)
            }
        }
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            print("didReceiveMessage with reply handler")
            let replyDict: [String:Any] = [
                "getSet": "set",
                "host": self.mainVc?.pihost ?? "no hostname",
                "backlight": String(format: "%.01f", self.mainVc!.systemBacklight!),
                "brightness":String(format: "%.01f", self.mainVc!.systemBrightness!),
                "pwr": String(format: "%.01f", self.mainVc!.systemPwr!),
                "act": String(format: "%.01f", self.mainVc!.systemAct!)
            ]
            if message["getSet"] as! String == "get" {
                replyHandler(replyDict)
                print(replyDict.debugDescription)
            }
        }
    }

    var window: UIWindow?
    var mainVc: ViewController?
    var isLaunching: Bool = true


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("appWillResignActive")
        if mainVc?.segmentedController.selectedSegmentIndex == 1 {
            mainVc?.segmentedController.selectedSegmentIndex = 0
            mainVc?.segmentChanged(mainVc?.segmentedController as Any)
        }
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entered backgound state")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("appWillEnterForeground")
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("appDidBecomeActive")
        print(isLaunching)
        if !isLaunching {
            print("pressing testConnection")
            mainVc?.testButtonPressed(mainVc?.testConnectionButton as Any)
        }
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("App will terminate")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

