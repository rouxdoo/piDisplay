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
    @IBOutlet weak var logView: UITextView!
    
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
    var brightness: Float = 0
    
    func sshCmd(host: String, user: String, pass: String, command: String, completion: @escaping (String) -> Void = {_ in}) {
        var response: String?
        activityIndicator.startAnimating()
        DispatchQueue.global(qos: .default).async {
            self.log("Command: " + command)
            let session: NMSSHSession = NMSSHSession(host: host, port: 22, andUsername: user)
            session.connect()
            session.authenticate(byPassword: pass)
            if session.isAuthorized {
                var error: NSError?
                response = session.channel.execute(command, error: &error)
                session.disconnect()
                completion(response ?? "")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
            } else {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    func log(_ string: String) {
        DispatchQueue.main.async {
            self.logView.text = self.logView.text + string + "\n"
            if self.logView.text.count > 0 {
                let location = self.logView.text.count - 1
                let bottom = NSMakeRange(location, 1)
                self.logView.scrollRangeToVisible(bottom)
            }
        }
    }
    var installingRpiBacklight: Bool = false
    func validHost(host: String, user: String, pass: String) -> Bool {
        log(" ----------------\n")
        log("Validating host: " + host)
        log("-username: " + user)
        let session: NMSSHSession = NMSSHSession(host: host, port: 22, andUsername: user)
        session.connect()
        if session.isConnected {
            log("Connection successful")
        } else {
            log("Connection failed")
            return false
        }
        session.authenticate(byPassword: pass)
        if session.isAuthorized {
            log("Authorized: " + session.remoteBanner!)
            if installingRpiBacklight {
                return true
            }
            var error: NSError?
            let response = session.channel.execute("command -v rpi-backlight", error: &error)
            if response.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) == "" {
                log("You need to install rpi-backlight - see settings")
                session.disconnect()
                isConnected(state: false)
                return false
            } else {
                log("rpi-backlight installed at: " + response.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))
                session.disconnect()
                isConnected(state: true)
                return true
            }
        } else {
            log("Authorization failed (user/password)")
            session.disconnect()
            isConnected(state: false)
            return false
        }
    }
    func isConnected(state: Bool) {
        if state {
            log("Saving host and login configuration\n")
            UserDefaults.standard.set(self.pihost, forKey: "pihost")
            UserDefaults.standard.set(self.piuser, forKey: "piuser")
            UserDefaults.standard.set(self.pipass, forKey: "pipass")
            self.connectionStatusLabel.text = "Connected: " + self.pihost
            self.brightnessSlider.isEnabled = true
            self.backlightSwitch.isEnabled = true
        } else {
            self.connectionStatusLabel.text = "Unable to connect"
            self.brightnessSlider.isEnabled = false
            self.backlightSwitch.isEnabled = false
        }
    }
    @IBAction func testButtonPressed(_ sender: Any) {
        logView.text = ""
        if validHost(host: pihost, user: piuser, pass: pipass) {
            log("Checking current display settings")
            sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight --power", completion: { (cmd1) -> Void in
                if cmd1.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) == "True" {
                    DispatchQueue.main.async {
                        self.backlightSwitch.isOn = true
                        self.log("Backlight is on")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.backlightSwitch.isOn = false
                        self.log("Backlight is off")
                    }
                }
            })
            sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight --actual-brightness", completion: { (cmd2) -> Void in
                self.brightness = Float(cmd2.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)) ?? 0
                DispatchQueue.main.async {
                    self.brightnessSlider.value = self.brightness
                    self.log("Brightness: " + String(self.brightness))
                }
            })
        } 
    }
    @IBAction func backlightSwitchPressed(_ sender: Any) {
        if validHost(host: pihost, user: piuser, pass: pipass) {
            log("Setting backlight")
            if (sender as! UISwitch).isOn {
                sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight --on", completion: { (_) -> Void in
                    self.log("Backlight set: on" + "\n")
                })
            } else {
                sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight --off", completion: { (_) -> Void in
                    self.log("Backlight set: off" + "\n")
                })
            }
        }
    }
    @IBAction func brightnessSliderChanged(_ sender: Any) {
        if validHost(host: pihost, user: piuser, pass: pipass) {
            log("Setting brightness")
            let slider = sender as! UISlider
            brightness = slider.value
            let newval = Int(brightness)
            sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight -b " + String(newval) + " -d 1 -s", completion: { (_) -> Void in
                self.log("Brightness set: " + String(self.brightness) + "\n")
            })
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
            log("Enter your raspberry pi login credentials above.")
        } else {
            pihostTextfield.text = UserDefaults.standard.string(forKey: "pihost")
            piuserTextfield.text = UserDefaults.standard.string(forKey: "piuser")
            pipasswdTextfield.text = UserDefaults.standard.string(forKey: "pipass")
            //_ = validHost(host: pihost, user: piuser, pass: pipass)
            testButtonPressed(testConnectionButton)
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
