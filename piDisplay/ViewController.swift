//
//  ViewController.swift
//  piDisplay
//
//  Created by Ian Jones on 12/31/18.
//  Copyright © 2018 Ian Jones. All rights reserved.
//

import UIKit
//import SwiftSH
import NMSSH

class ViewController: UIViewController {
    @IBOutlet weak var pihostTextfield: UITextField!
    @IBOutlet weak var piuserTextfield: UITextField!
    @IBOutlet weak var pipasswdTextfield: UITextField!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var testConnectionButton: UIButton!
    @IBOutlet weak var backlightSwitch: UISwitch!
    @IBOutlet weak var backlightLabel: UILabel!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var brightnessLabel: UILabel!
    
    var pihost: String {
        get {
            return pihostTextfield.text ?? ""
        }
    }
    var piuser: String {
        get {
            return piuserTextfield.text ?? ""
        }
    }
    var pipass: String {
        get {
            return pipasswdTextfield.text ?? ""
        }
    }
    
    @IBAction func testButtonPressed(_ sender: Any) {
        let session: NMSSHSession = NMSSHSession(host: pihost, port: 22, andUsername: piuser)
        session.connect()
        session.authenticate(byPassword: pipass)
        if session.isAuthorized {
            UserDefaults.standard.set(pihost, forKey: "pihost")
            UserDefaults.standard.set(piuser, forKey: "piuser")
            UserDefaults.standard.set(pipass, forKey: "pipass")
            connectionStatusLabel.text = "Host Validated"
            brightnessSlider.isEnabled = true
            backlightSwitch.isEnabled = true
            var error: NSError?
            var response = session.channel.execute("sudo rpi-backlight --power", error: &error)
            response = response.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            if response == "True" {
                backlightSwitch.isOn = true
            } else {
                backlightSwitch.isOn = false
            }
            response = session.channel.execute("sudo rpi-backlight --actual-brightness", error: &error)
            response = response.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            let brightness = Float(response)
            brightnessSlider.value = brightness ?? 0
            session.disconnect()
        } else {
            print("authentication failed")
        }
    }
    @IBAction func backlightSwitchPressed(_ sender: Any) {
        let session: NMSSHSession = NMSSHSession(host: pihost, port: 22, andUsername: piuser)
        session.connect()
        session.authenticate(byPassword: pipass)
        if session.isAuthorized {
            var error: NSError?
            if (sender as! UISwitch).isOn {
                let _: String? = session.channel.execute("sudo rpi-backlight --on", error: &error)
            } else {
                let _: String? = session.channel.execute("sudo rpi-backlight --off", error: &error)
            }
            session.disconnect()
        } else {
            print("authentication failed")
        }
    }
    @IBAction func brightnessSliderChanged(_ sender: Any) {
        let session: NMSSHSession = NMSSHSession(host: pihost, port: 22, andUsername: piuser)
        session.connect()
        session.authenticate(byPassword: pipass)
        if session.isAuthorized {
            var error: NSError?
            let slider = sender as! UISlider
            let newval = Int(slider.value)
            let _: String? = session.channel.execute("sudo rpi-backlight -b " + String(newval) + " -d 1 -s", error: &error)
            session.disconnect()
        } else {
            print("authentication failed")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If first launch
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if !launchedBefore  {
            print("First launch, setting UserDefaults")
            UserDefaults.standard.set(true, forKey: "launchedBefore")
        } else {
            pihostTextfield.text = UserDefaults.standard.string(forKey: "pihost")
            piuserTextfield.text = UserDefaults.standard.string(forKey: "piuser")
            pipasswdTextfield.text = UserDefaults.standard.string(forKey: "pipass")
        }
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
