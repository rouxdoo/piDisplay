//
//  ViewController.swift
//  piDisplay
//
//  Created by Ian Jones on 12/31/18.
//  Copyright © 2018 Ian Jones. All rights reserved.
//

import UIKit
import NMSSH
import ElementalController

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var pihostTextfield: UITextField!
    @IBOutlet weak var piuserTextfield: UITextField!
    @IBOutlet weak var pipasswdTextfield: UITextField!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var testConnectionButton: UIButton!
    @IBOutlet weak var segmentedController: UISegmentedControl!
    @IBOutlet weak var backlightSwitch: UISwitch!
    @IBOutlet weak var pwrLedSwitch: UISwitch!
    @IBOutlet weak var actLedSwitch: UISwitch!
    @IBOutlet weak var backlightLabel: UILabel!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var logView: UITextView!
    @IBOutlet weak var shellCmdTextField: UITextField!
    @IBOutlet weak var shellCmdButton: UIButton!
    
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
    var shellCmd: String {
        get {
            return shellCmdTextField.text ?? ""
        }
    }
    var brightness: Float = 0
    enum ComType: Int {
        case ssh = 1
        case swift = 2
    }
    var comType: ComType = .ssh
    
    enum ElementIdentifier: Int8 {
        case brightness = 1
        case backlight = 2
        case pwr = 3
        case act = 4
        case cmd = 5
    }
    var systemBrightness: Float?
    var systemBacklight: Float?
    var systemPwr: Float?
    var systemAct: Float?
    var brightnessElement: Element?
    var backlightElement: Element?
    var pwrElement: Element?
    var actElement: Element?
    var cmdElement: Element?
    var server: ServerDevice?
    var elementalController = ElementalController()
    var installingRpiBacklight: Bool = false
    
    // wrap activity indicator to count instances so we don't stop if background threads still running
    var activityCount: Int = 0
    func activityUp() {
        activityCount += 1
        activityIndicator.startAnimating()
    }
    func activityDown() {
        activityCount -= 1
        if activityCount == 0 {
            activityIndicator.stopAnimating()
        }
    }
    
    func sshCmd(host: String, user: String, pass: String, command: String, completion: @escaping (String) -> Void = {_ in}) {
        var response: String?
        if !installingRpiBacklight {
            self.log("Command: " + command)
        }
        activityUp()
        DispatchQueue.global(qos: .default).async {
            let session: NMSSHSession = NMSSHSession(host: host, port: 22, andUsername: user)
            session.connect()
            session.authenticate(byPassword: pass)
            if session.isAuthorized {
                var error: NSError?
                response = session.channel.execute(command, error: &error)
                session.disconnect()
                DispatchQueue.main.async {
                    completion(response ?? "")
                    self.activityDown()
                }
            } else {
                DispatchQueue.main.async {
                    session.disconnect()
                    self.activityDown()
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
            self.logView.flashScrollIndicators()
        }
    }
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
            isConnected(state: false)
            return false
        }
        session.authenticate(byPassword: pass)
        if session.isAuthorized {
            log("Authorized: " + session.remoteBanner!)
            if installingRpiBacklight {
                UserDefaults.standard.set(self.pihost, forKey: "pihost")
                UserDefaults.standard.set(self.piuser, forKey: "piuser")
                UserDefaults.standard.set(self.pipass, forKey: "pipass")
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
            if comType == .ssh {
                log("Saving host and login configuration\n")
                UserDefaults.standard.set(self.pihost, forKey: "pihost")
                UserDefaults.standard.set(self.piuser, forKey: "piuser")
                UserDefaults.standard.set(self.pipass, forKey: "pipass")
                self.connectionStatusLabel.text = "SSH: " + self.pihost
            } else {
                self.connectionStatusLabel.text = "SwiftServer: " + (server?.remoteServerAddress)!
            }
            self.brightnessSlider.isEnabled = true
            self.backlightSwitch.isEnabled = true
            self.pwrLedSwitch.isEnabled = true
            self.actLedSwitch.isEnabled = true
        } else { // isConnected(false)
            if comType == .swift {
                self.server = nil
            }
            self.connectionStatusLabel.text = "Unable to connect"
            self.brightnessSlider.isEnabled = false
            self.backlightSwitch.isEnabled = false
            self.pwrLedSwitch.isEnabled = false
            self.actLedSwitch.isEnabled = false
        }
    }
    @IBAction func segmentChanged(_ sender: Any) {
        dismissKeyboard()
        switch segmentedController.selectedSegmentIndex {
        case 0:
            log("Switching to SSH communication")
            comType = .ssh
            UserDefaults.standard.set(comType.rawValue, forKey: "comType")
            if server != nil {
                server?.disconnect()
                server = nil
            }
            testButtonPressed(testConnectionButton)
            brightnessSlider.isContinuous = false
            pihostTextfield.isEnabled = true
            piuserTextfield.isEnabled = true
            pipasswdTextfield.isEnabled = true
        case 1:
            logView.text = ""
            log("Switching to Swift Server communication")
            comType = .swift
            UserDefaults.standard.set(comType.rawValue, forKey: "comType")
            if server == nil {
                setupSwift()
            }
            brightnessSlider.isContinuous = true
            pihostTextfield.isEnabled = false
            piuserTextfield.isEnabled = false
            pipasswdTextfield.isEnabled = false
        default:
            break
        }
    }
    
    @IBAction func testButtonPressed(_ sender: Any) {
        dismissKeyboard()
        logView.text = ""
        if comType == .swift {
            if server == nil {
                self.isConnected(state: false)
                log("SwiftServer not connected. Try SSH.")
                return
            }
            if (server?.isConnected)! {
                log("Connected to swift server at: " + (server?.remoteServerAddress)!)
            } else {
                self.isConnected(state: false)
                server = nil
            }
            return
        }
        if validHost(host: pihost, user: piuser, pass: pipass) {
            log("Checking current display settings")
            sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight --power", completion: { (cmd) -> Void in
                if cmd.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) == "True" {
                    self.backlightSwitch.isOn = true
                    self.log("Backlight is on")
                } else {
                    self.backlightSwitch.isOn = false
                    self.log("Backlight is off")
                }
            })
            sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo rpi-backlight --actual-brightness", completion: { (cmd) -> Void in
                self.brightness = Float(cmd.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)) ?? 0
                self.brightnessSlider.value = self.brightness
                self.log("Brightness: " + String(self.brightness))
            })
            sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo cat /sys/class/leds/led1/brightness", completion: { (cmd) -> Void in
                self.systemPwr = Float(cmd.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))
                if self.systemPwr! > 0.0 {
                    self.pwrLedSwitch.isOn = true
                    self.log("Power LED is on")
                } else {
                    self.pwrLedSwitch.isOn = false
                    self.log("Power LED is off")
                }
            })
            sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo cat /sys/class/leds/led0/brightness", completion: { (cmd) -> Void in
                self.systemAct = Float(cmd.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))
                if self.systemAct! > 0.0 {
                    self.actLedSwitch.isOn = true
                    self.log("Activity LED is on")
                } else {
                    self.actLedSwitch.isOn = false
                    self.log("Activity LED is off")
                }
            })
        } 
    }
    @IBAction func backlightSwitchPressed(_ sender: Any) {
        if comType == .swift {
            var status = ""
            if (sender as! UISwitch).isOn {
                systemBacklight = 1.0
                status = "on"
            } else {
                systemBacklight = 0.0
                status = "off"
            }
            backlightElement?.value = systemBacklight
            do {
                try _ = server?.send(element: backlightElement!)
            } catch {
                log("Unable to send backlight element")
            }
            log("Setting backlight: \(status)")
            return
        }
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
    @IBAction func pwdLedPressed(_ sender: Any) {
        if comType == .swift {
            var status = ""
            if (sender as! UISwitch).isOn {
                systemPwr = 255.0
                status = "on"
            } else {
                systemPwr = 0.0
                status = "off"
            }
            pwrElement?.value = systemPwr
            do {
                try _ = server?.send(element: pwrElement!)
            } catch {
                log("Unable to send pwrLed element")
            }
            log("Setting power LED: \(status)")
            return
        }
        if validHost(host: pihost, user: piuser, pass: pipass) {
            let path = "/sys/class/leds/led1/brightness"
            log("Setting power")
            if (sender as! UISwitch).isOn {
                sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo echo 255 > " + path, completion: { (_) -> Void in
                    self.log("Power LED set: on" + "\n")
                })
            } else {
                sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo echo 0 > " + path, completion: { (_) -> Void in
                    self.log("Power LED set: off" + "\n")
                })
            }
        }
    }
    @IBAction func actLedPressed(_ sender: Any) {
        if comType == .swift {
            var status = ""
            if (sender as! UISwitch).isOn {
                systemAct = 255.0
                status = "on"
            } else {
                systemAct = 0.0
                status = "off"
            }
            actElement?.value = systemAct
            do {
                try _ = server?.send(element: actElement!)
            } catch {
                log("Unable to send actLed element")
            }
            log("Setting activity LED: \(status)")
            return
        }
        if validHost(host: pihost, user: piuser, pass: pipass) {
            log("Setting activity")
            let path = "/sys/class/leds/led0/brightness"
            if (sender as! UISwitch).isOn {
                sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo echo 255 > " + path, completion: { (_) -> Void in
                    self.log("Activity LED set: on" + "\n")
                })
            } else {
                sshCmd(host: pihost, user: piuser, pass: pipass, command: "sudo echo 0 > " + path, completion: { (_) -> Void in
                    self.log("Activity LED set: off" + "\n")
                })
            }
        }
    }
    @IBAction func brightnessSliderChanged(_ sender: Any) {
        if comType == .swift {
            systemBrightness = (sender as! UISlider).value
            brightness = systemBrightness!
            brightnessElement?.value = systemBrightness
            do {
                try _ = server?.send(element: brightnessElement!)
            } catch {
                log("Unable to send brightness element")
            }
            log("Setting brightness to \(brightness)")
            return
        }
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
    @IBAction func shellCmdPressed(_ sender: Any) {
        dismissKeyboard()
        if shellCmd == "" {
            return
        }
        log("---------------\n")
        if comType == .swift {
            log("Shell Command: " + shellCmd)
            cmdElement?.value = shellCmd
            do {
                try _ = server?.send(element: cmdElement!)
            } catch {
                log("Unable to send cmd element")
            }
        } else {
            sshCmd(host: pihost, user: piuser, pass: pipass, command: shellCmd, completion: { (resp) -> Void in
                self.log(resp)
            })
        }
        shellCmdTextField.text = ""
    }
    
    func setupSwift() {
//        elementalController.setupForBrowsingAs(deviceNamed: "ian")
        elementalController.setupForBrowsingAs(deviceNamed: UIDevice.current.name)
        elementalController.browser.events.foundServer.handler { serverDevice in
            self.log("Found SwiftServer: \(serverDevice.remoteServerAddress)")
            // Attach elements to server...
            self.brightnessElement = serverDevice.attachElement(
                Element(identifier: ElementIdentifier.brightness.rawValue,
                        displayName: "Brightness",
                        proto: .tcp,
                        dataType: .Float))
            
            self.backlightElement = serverDevice.attachElement(
                Element(identifier: ElementIdentifier.backlight.rawValue,
                        displayName: "Backlight",
                        proto: .tcp,
                        dataType: .Float))
            
            self.pwrElement = serverDevice.attachElement(
                Element(identifier: ElementIdentifier.pwr.rawValue,
                        displayName: "Power LED",
                        proto: .tcp,
                        dataType: .Float))
            
            self.actElement = serverDevice.attachElement(
                Element(identifier: ElementIdentifier.act.rawValue,
                        displayName: "Activity LED",
                        proto: .tcp,
                        dataType: .Float))
            
            self.cmdElement = serverDevice.attachElement(
                Element(identifier: ElementIdentifier.cmd.rawValue,
                        displayName: "Command",
                        proto: .tcp,
                        dataType: .String))
            
            self.brightnessElement?.handler = {element, _ in
                self.systemBrightness = element.value as? Float
                self.brightnessSlider.value = self.systemBrightness!
                self.log("Brightness is currently \(self.systemBrightness ?? 0)")
            }
            self.backlightElement?.handler = {element, _ in
                self.systemBacklight = element.value as? Float
                if self.systemBacklight == 0.0 {
                    self.backlightSwitch.isOn = false
                    self.log("Backlight is currently off")
                } else {
                    self.backlightSwitch.isOn = true
                    self.log("Backlight is currently on")
                }
            }
            self.pwrElement?.handler = {element, _ in
                self.systemPwr = element.value as? Float
                if self.systemPwr == 0.0 {
                    self.pwrLedSwitch.isOn = false
                    self.log("Power LED is currently off")
                } else {
                    self.pwrLedSwitch.isOn = true
                    self.log("Power LED is currently on")
                }
            }
            self.actElement?.handler = {element, _ in
                self.systemAct = element.value as? Float
                if self.systemAct == 0.0 {
                    self.actLedSwitch.isOn = false
                    self.log("Activity LED is currently off")
                } else {
                    self.actLedSwitch.isOn = true
                    self.log("Activity LED is currently on")
                }
            }
            self.cmdElement?.handler = { element, _ in
                self.log(element.value as! String)
            }
            // Once connected, you can send elements to the server...
            serverDevice.events.connected.handler = {serverDevice in
                self.activityDown()
                self.isConnected(state: true)
            }
            serverDevice.events.deviceDisconnected.handler = { serverDevice in
                self.log("SwiftServer disconnected")
                self.isConnected(state: false)
            }
            // Finally, connect to the server!
            serverDevice.connect()
            // save reference to server
            self.server = serverDevice
        }
        self.activityUp()
        DispatchQueue.global(qos: .default).async {
            self.elementalController.browser.browseFor(serviceName: "SwiftServer")
        }
        log("Browsing for SwiftServer on network...")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
            if self.elementalController.browser.isBrowsing {
                self.log("Browsing for SwiftServer on network...")
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                    if self.elementalController.browser.isBrowsing {
                        self.activityDown()
                        self.elementalController.browser.stopBrowsing()
                        self.log("Unable to locate SwiftServer on network.")
                        self.log("Shutting down browser. Try SSH.")
                    }
                }
            }
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == shellCmdTextField {
            shellCmdPressed(shellCmdButton)
        }
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        shellCmdTextField.delegate = self
        pihostTextfield.delegate = self
        piuserTextfield.delegate = self
        pipasswdTextfield.delegate = self
        if comType == .swift {
            pihostTextfield.isEnabled = false
            piuserTextfield.isEnabled = false
            pipasswdTextfield.isEnabled = false
            setupSwift()
        } else {
            pihostTextfield.isEnabled = true
            piuserTextfield.isEnabled = true
            pipasswdTextfield.isEnabled = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If first launch
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if !launchedBefore  {
            self.log("No user credentials found.")
            UserDefaults.standard.set(true, forKey: "launchedBefore")
            UserDefaults.standard.set(ComType.ssh.rawValue, forKey: "comType")
            log("Enter your raspberry pi ssh credentials above")
            log("to use ssh or try connecting to SwiftServer.")
        } else {
            pihostTextfield.text = UserDefaults.standard.string(forKey: "pihost")
            piuserTextfield.text = UserDefaults.standard.string(forKey: "piuser")
            pipasswdTextfield.text = UserDefaults.standard.string(forKey: "pipass")
            if ComType(rawValue: UserDefaults.standard.integer(forKey: "comType")) == nil {
                UserDefaults.standard.set(ComType.ssh.rawValue, forKey: "comType")
            } else {
                comType = ComType(rawValue: UserDefaults.standard.integer(forKey: "comType"))!
            }
            if comType == .swift {
                log("Swift Server is current com channel")
                brightnessSlider.isContinuous = true
                segmentedController.selectedSegmentIndex = 1
                segmentChanged(segmentedController)
                return
            }
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
