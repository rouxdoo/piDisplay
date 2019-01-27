//
//  SettingsViewController.swift
//  piDisplay
//
//  Created by Ian Jones on 1/5/19.
//  Copyright © 2019 Ian Jones. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var settingsPane: UIView!
    @IBOutlet weak var closeButtonPane: UIButton!
    @IBOutlet weak var installRpiButton: UIButton!
    
    @IBAction func closePaneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func rpibacklightGit(_ sender: Any) {
        if let url = URL(string: "https://github.com/linusg/rpi-backlight"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    @IBAction func setupPi(_ sender: Any) {
        let vc: ViewController = presentingViewController as! ViewController
        vc.installingRpiBacklight = true
        if !vc.validHost(host: vc.pihost, user: vc.piuser, pass: vc.pipass) {
            vc.connectionStatusLabel.text = "Authenticate first to install..."
            vc.log("Unable to log in to pi host")
            vc.installingRpiBacklight = false
            self.dismiss(animated: true, completion: nil)
        } else {
            let installAlert = UIAlertController(title: "Install server dependancies on Pi device", message: "RUN THIS COMMAND NOW??\n\n" + "This will download server dependancies to the home directory on your pi. You can then review the installer script and optionally have it run for you.", preferredStyle: UIAlertController.Style.actionSheet)
            installAlert.popoverPresentationController?.sourceView = self.installRpiButton
            installAlert.popoverPresentationController?.sourceRect = (sender as! UIButton).bounds
            installAlert.addAction(UIAlertAction(title: "Yes, do it!", style: .default, handler: { (action: UIAlertAction!) in
                vc.sshCmd(host: vc.pihost, user: vc.piuser, pass: vc.pipass, command: "git clone https://github.com/rouxdoo/SwiftServer.git", completion: { (cmd) -> Void in
                    vc.sshCmd(host: vc.pihost, user: vc.piuser, pass: vc.pipass, command: "cat ./SwiftServer/installer.sh", completion: { (cmd) -> Void in
                        vc.logView.text = ""
                        vc.log(cmd + "\nThe installer script is located at:\n/home/pi/SwiftServer/installer.sh\nClick \"run\" above or install manually.\nThe installer will take a long time to complete.")
                        vc.shellCmdTextField.text = "~/SwiftServer/installer.sh"
                    })
                })
                vc.installingRpiBacklight = false
                self.dismiss(animated: true, completion: nil)
            }))
            installAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                vc.log("Install of server dependancies cancelled")
                vc.installingRpiBacklight = false
                self.dismiss(animated: true, completion: nil)
            }))
            present(installAlert, animated: true, completion: nil)
        }
    }
    @IBAction func nmsshGit(_ sender: Any) {
        if let url = URL(string: "https://github.com/NMSSH/NMSSH"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    @IBAction func elementalGit(_ sender: Any) {
        if let url = URL(string: "https://github.com/robreuss/ElementalController"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    @IBAction func clearUserDefaults(_ sender: Any) {
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
        let vc: ViewController = presentingViewController as! ViewController
        vc.pihostTextfield.text = ""
        vc.piuserTextfield.text = ""
        vc.pipasswdTextfield.text = ""
        vc.logView.text = ""
        vc.log("All stored data was cleared.")
        vc.isConnected(state: vc.server?.isConnected ?? false)
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsPane.layer.cornerRadius = 15
        settingsPane.layer.borderWidth = 2
        settingsPane.layer.borderColor = UIColor.blue.cgColor
    }
}
