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
    @IBAction func rpibacklightInstall(_ sender: Any) {
        let vc: ViewController = presentingViewController as! ViewController
        if !vc.validHost(host: vc.pihost, user: vc.piuser, pass: vc.pipass) {
            vc.connectionStatusLabel.text = "Authenticate first to install..."
            vc.log("Unable to log in to pi host")
            self.dismiss(animated: true, completion: nil)
        } else {
            let installAlert = UIAlertController(title: "Install on Pi", message: "RUN THIS COMMAND NOW??\n\n" + "git clone https://github.com/linusg/rpi-backlight.git && cd rpi-backlight && sudo python3 setup.py install && sudo cat SUBSYSTEM==\"backlight\",RUN+=\"/bin/chmod 666 /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power\" > /etc/udev/rules.d/backlight-permissions.rules", preferredStyle: UIAlertController.Style.actionSheet)
            installAlert.popoverPresentationController?.sourceView = self.installRpiButton
            installAlert.popoverPresentationController?.sourceRect = (sender as! UIButton).bounds
            installAlert.addAction(UIAlertAction(title: "Yes, do it!", style: .default, handler: { (action: UIAlertAction!) in
                vc.sshCmd(host: vc.pihost, user: vc.piuser, pass: vc.pipass, command: "git clone https://github.com/linusg/rpi-backlight.git && cd rpi-backlight && sudo python3 setup.py install && sudo cat SUBSYSTEM==\"backlight\",RUN+=\"/bin/chmod 666 /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power\" > /etc/udev/rules.d/backlight-permissions.rules")
                self.dismiss(animated: true, completion: nil)
            }))
            installAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                vc.log("Install of rpi-backlight cancelled")
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
    @IBAction func nmsshLicense(_ sender: Any) {
        if let url = URL(string: "https://github.com/NMSSH/NMSSH/blob/master/LICENSE"), UIApplication.shared.canOpenURL(url) {
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
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsPane.layer.cornerRadius = 15
        settingsPane.layer.borderWidth = 2
        settingsPane.layer.borderColor = UIColor.blue.cgColor
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
