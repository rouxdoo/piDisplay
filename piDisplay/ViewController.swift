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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
    var hostAuthorized: Bool = false
    var piBacklightOn: Bool = false
    var brightness: Float = 0
    
    @IBAction func testButtonPressed(_ sender: Any) {
        let host = pihost
        let user = piuser
        let pass = pipass
        activityIndicator.startAnimating()
        DispatchQueue.global(qos: .default).async {
            let session: NMSSHSession = NMSSHSession(host: host, port: 22, andUsername: user)
            session.connect()
            session.authenticate(byPassword: pass)
            if session.isAuthorized {
                self.hostAuthorized = true
                var error: NSError?
                var response = session.channel.execute("sudo rpi-backlight --power", error: &error)
                response = response.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                if response == "True" {
                    self.piBacklightOn = true
                } else {
                    self.piBacklightOn = false
                }
                response = session.channel.execute("sudo rpi-backlight --actual-brightness", error: &error)
                response = response.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                self.brightness = Float(response) ?? 0
                session.disconnect()
            } else {
                print("authentication failed")
            }
            DispatchQueue.main.async {
                if self.hostAuthorized {
                    UserDefaults.standard.set(self.pihost, forKey: "pihost")
                    UserDefaults.standard.set(self.piuser, forKey: "piuser")
                    UserDefaults.standard.set(self.pipass, forKey: "pipass")
                    self.connectionStatusLabel.text = "Host Validated"
                    self.brightnessSlider.isEnabled = true
                    self.backlightSwitch.isEnabled = true
                    if self.piBacklightOn {
                        self.backlightSwitch.isOn = true
                    } else {
                        self.backlightSwitch.isOn = true
                    }
                    self.brightnessSlider.value = self.brightness
                } else {
                    self.connectionStatusLabel.text = "Not Connected"
                    self.brightnessSlider.isEnabled = false
                    self.backlightSwitch.isEnabled = false
                }
                self.activityIndicator.stopAnimating()
            }
        }
    }
    @IBAction func backlightSwitchPressed(_ sender: Any) {
        if (sender as! UISwitch).isOn {
            piBacklightOn = true
        } else {
            piBacklightOn = false
        }
        let host = pihost
        let user = piuser
        let pass = pipass
        activityIndicator.startAnimating()
        DispatchQueue.global(qos: .default).async {
            let session: NMSSHSession = NMSSHSession(host: host, port: 22, andUsername: user)
            session.connect()
            session.authenticate(byPassword: pass)
            if session.isAuthorized {
                var error: NSError?
                if self.piBacklightOn {
                    let _: String? = session.channel.execute("sudo rpi-backlight --on", error: &error)
                } else {
                    let _: String? = session.channel.execute("sudo rpi-backlight --off", error: &error)
                }
                session.disconnect()
            } else {
                print("authentication failed")
            }
            DispatchQueue.main.async {
                // stuff that goes on main thread
                self.activityIndicator.stopAnimating()
            }
        }
    }
    @IBAction func brightnessSliderChanged(_ sender: Any) {
        let slider = sender as! UISlider
        brightness = slider.value
        let newval = Int(brightness)
        let host = pihost
        let user = piuser
        let pass = pipass
        activityIndicator.startAnimating()
        DispatchQueue.global(qos: .default).async {
            let session: NMSSHSession = NMSSHSession(host: host, port: 22, andUsername: user)
            session.connect()
            session.authenticate(byPassword: pass)
            if session.isAuthorized {
                var error: NSError?
                let _: String? = session.channel.execute("sudo rpi-backlight -b " + String(newval) + " -d 1 -s", error: &error)
                session.disconnect()
            } else {
                print("authentication failed")
            }
            DispatchQueue.main.async {
                // stuff that goes on main thread
                self.activityIndicator.stopAnimating()
            }
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
