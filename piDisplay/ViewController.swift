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
    
    func sshCmd(host: String, user: String, pass: String, command: String, completion: @escaping (String) -> Void = {_ in}) {
        var response: String?
        activityIndicator.startAnimating()
        DispatchQueue.global(qos: .default).async {
            let session: NMSSHSession = NMSSHSession(host: host, port: 22, andUsername: user)
            session.connect()
            session.authenticate(byPassword: pass)
            if session.isAuthorized {
                var error: NSError?
                response = session.channel.execute(command, error: &error)
                session.disconnect()
                completion(response ?? "")
            }
            DispatchQueue.main.async {
                // stuff that goes on main thread
                self.activityIndicator.stopAnimating()
            }
        }
    }
    func validHost(host: String, user: String, pass: String) -> Bool {
        let session: NMSSHSession = NMSSHSession(host: host, port: 22, andUsername: user)
        session.connect()
        session.authenticate(byPassword: pass)
        if session.isAuthorized {
            session.disconnect()
            return true
        } else {
            session.disconnect()
            return false
        }
    }
    @IBAction func testButtonPressed(_ sender: Any) {
        if validHost(host: pihost, user: piuser, pass: pipass) {
            sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight --power", completion: { (cmd1) -> Void in
                if cmd1.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) == "True" {
                    DispatchQueue.main.async {
                        self.backlightSwitch.isOn = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.backlightSwitch.isOn = false
                    }
                }
                DispatchQueue.main.async {
                    UserDefaults.standard.set(self.pihost, forKey: "pihost")
                    UserDefaults.standard.set(self.piuser, forKey: "piuser")
                    UserDefaults.standard.set(self.pipass, forKey: "pipass")
                    self.connectionStatusLabel.text = "Connected: " + self.pihost
                    self.brightnessSlider.isEnabled = true
                    self.backlightSwitch.isEnabled = true
                }
            })
            sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight --actual-brightness", completion: { (cmd2) -> Void in
                self.brightness = Float(cmd2.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)) ?? 0
                DispatchQueue.main.async {
                    self.brightnessSlider.value = self.brightness
                }
            })
        } else {
            self.connectionStatusLabel.text = "Unable to connect"
            self.brightnessSlider.isEnabled = false
            self.backlightSwitch.isEnabled = false
        }
    }
    @IBAction func backlightSwitchPressed(_ sender: Any) {
        if (sender as! UISwitch).isOn {
            piBacklightOn = true
            sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight --on")
        } else {
            piBacklightOn = false
            sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight --off")
        }
    }
    @IBAction func brightnessSliderChanged(_ sender: Any) {
        let slider = sender as! UISlider
        brightness = slider.value
        let newval = Int(brightness)
        sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight -b " + String(newval) + " -d 1 -s")
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
