//
//  InterfaceController.swift
//  piWatch Extension
//
//  Created by Ian Jones on 6/15/19.
//  Copyright © 2019 Ian Jones. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var hostLabel: WKInterfaceLabel!
    var host: String = "unset"
    @IBOutlet weak var backlightSwitch: WKInterfaceSwitch!
    var backlight: String = "0.0"
    @IBOutlet weak var brightnessSlider: WKInterfaceSlider!
    var brightness: String = "0.0"
    @IBOutlet weak var pwrLedSwitch: WKInterfaceSwitch!
    var pwr: String = "0.0"
    @IBOutlet weak var actLedSwitch: WKInterfaceSwitch!
    var act: String = "0.0"
    
    let extensionDelegate = WKExtension.shared().delegate as! ExtensionDelegate
    
    @IBAction func backlightChanged(_ value: Bool) {
        if value {
            backlight = "1.0"
        } else {
            backlight = "0.0"
        }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["backlight": backlight], replyHandler: nil, errorHandler: nil)
        }
    }
    @IBAction func brightnessChanged(_ value: Float) {
        brightness = value.description
        print("brightness is \(brightness)")
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["brightness": brightness], replyHandler: nil, errorHandler: nil)
        }
    }
    @IBAction func pwrChanged(_ value: Bool) {
        if value {
            pwr = "1.0"
        } else {
            pwr = "0.0"
        }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["pwr": pwr], replyHandler: nil, errorHandler: nil)
        }
    }
    @IBAction func actChanged(_ value: Bool) {
        if value {
            act = "1.0"
        } else {
            act = "0.0"
        }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["act": act], replyHandler: nil, errorHandler: nil)
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        extensionDelegate.interface = self
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
