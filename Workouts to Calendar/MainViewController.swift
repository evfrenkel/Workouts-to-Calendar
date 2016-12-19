//
//  MainViewController.swift
//  Calendar Test
//
//  Created by Evan Frenkel on 9/23/16.
//  Copyright © 2016 Evan Frenkel. All rights reserved.
//

import UIKit
import EventKit
import HealthKit

class MainViewController: UITableViewController {
    
    let defaults = UserDefaults.init()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var source: EKSource?
    
    /// Views
    @IBOutlet weak var chooseCalendarCell: UITableViewCell!
    @IBOutlet weak var syncSwitchViewCell: UITableViewCell!
    var switchView: UISwitch?
    
    /// Functions 
    override func viewDidLoad() {
        source = appDelegate.manager.eventStoreManager.getSourceAccount()
        switchView = UISwitch.init()
        switchView!.isOn = defaults.bool(forKey: syncDefaultsKey)
        switchView!.addTarget(self, action: #selector(self.syncSettingUpdated(sender:)), for: UIControlEvents.valueChanged)
        syncSwitchViewCell.accessoryView = switchView
    }
    override func viewWillAppear(_ animated: Bool) {
        if let source = appDelegate.manager.eventStoreManager.getSourceAccount() {
            if source != self.source {
                print("source != self.source")
                switchView?.setOn(false, animated: true)
                syncSettingUpdated(sender: switchView!)
            }
            chooseCalendarCell.detailTextLabel?.text = source.title
            switchView?.isEnabled = true
            self.source = source
        }
        else {
            switchView?.isEnabled = false
            chooseCalendarCell.detailTextLabel?.text = ""
        }
        chooseCalendarCell.isSelected = false
    }
    func syncSettingUpdated(sender: UISwitch) {
        if sender.isOn {
            if HKHealthStore.isHealthDataAvailable() {
                defaults.set(true, forKey: syncDefaultsKey)
                appDelegate.manager.startObserving()
            }
            else {
                showAlert(title: "Device not supported",
                          message: "This device does not provide access to the Health App")
                sender.setOn(false, animated: true)
            }
        }
        else {
            defaults.set(false, forKey: syncDefaultsKey)
            appDelegate.manager.stopObserving()
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController.init(title: title,
                                           message: message,
                                           preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction.init(title: "Dismiss",
                                           style: UIAlertActionStyle.cancel,
                                           handler: nil))
        present(alert,
                animated: true,
                completion: nil)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "toSelectSource" {
            switch EKEventStore.authorizationStatus(for: EKEntityType.event) {
            case EKAuthorizationStatus.denied,
                 EKAuthorizationStatus.restricted:
                showAlert(title: "Calendar access required",
                          message: "Enable access in\nSettings > Privacy > Calendars")
                chooseCalendarCell.isSelected = false
                return false
            case EKAuthorizationStatus.notDetermined:
                appDelegate.manager.eventStoreManager.askForCalendarAuth()
                chooseCalendarCell.isSelected = false
                return false
            default:
                return true
            }
        }
        return true
    }
}
