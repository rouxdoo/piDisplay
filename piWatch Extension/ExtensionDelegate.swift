//
//  ExtensionDelegate.swift
//  piWatch Extension
//
//  Created by Ian Jones on 6/15/19.
//  Copyright © 2019 Ian Jones. All rights reserved.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    
    var interface: InterfaceController?
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // get initial state of pi from iphone app
        sync(getSet: "get")
    }

    func sync(getSet: String) {
        print("Sync()")
        if WCSession.default.isReachable {
            var messageDict = [
                "getSet": getSet,
                "host": "",
                "backlight": "",
                "brightness": "",
                "pwr": "",
                "act": ""
            ]
            if getSet == "get" {
                print("Sending: " + messageDict.debugDescription)
                WCSession.default.sendMessage(messageDict,
                                              replyHandler: {(replyDict) -> Void in
                                                print("Recieved reply: " + replyDict.debugDescription)
                                                if replyDict["getSet"] as! String == "set" {
                                                    DispatchQueue.main.async {
                                                        self.setInterface(replyDict: replyDict)
                                                    }
                                                }
                },
                                              errorHandler: {(error) -> Void in
                                                print(error)
                })
            } else {
                messageDict["backlight"] = interface?.backlight
                messageDict["brightness"] = interface?.brightness
                messageDict["pwr"] = interface?.pwr
                messageDict["act"] = interface?.act
                print(messageDict)
                WCSession.default.sendMessage(messageDict, replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    // func to set watch interface from phone data
    func setInterface(replyDict: [String:Any]) {
        interface?.host = replyDict["host"] as! String
        interface?.hostLabel.setText(interface?.host)
        interface?.backlight = replyDict["backlight"] as! String
        interface?.brightness = replyDict["brightness"] as! String
        interface?.pwr = replyDict["pwr"] as! String
        interface?.act = replyDict["act"] as! String
        if interface?.backlight == "1.0" {
            interface?.backlightSwitch.setOn(true)
        } else {
            interface?.backlightSwitch.setOn(false)
        }
        interface?.brightnessSlider.setValue(Float(interface!.brightness)!)
        if interface?.pwr == "1.0" {
            interface?.pwrLedSwitch.setOn(true)
        } else {
            interface?.pwrLedSwitch.setOn(false)
        }
        if interface?.act == "1.0" {
            interface?.actLedSwitch.setOn(true)
        } else {
            interface?.actLedSwitch.setOn(false)
        }
    }
    
    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }


    func applicationDidBecomeActive() {
        sync(getSet: "get")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}
