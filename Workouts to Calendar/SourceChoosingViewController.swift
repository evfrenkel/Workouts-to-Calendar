//
//  CalendarChoosingViewController.swift
//  Calendar Test
//
//  Created by Evan Frenkel on 9/22/16.
//  Copyright © 2016 Evan Frenkel. All rights reserved.
//

import UIKit
import EventKit

class SourceChoosingViewController: UITableViewController {
    
    let defaults = UserDefaults.init()
    let eventStore = EKEventStore()
    var sources = [EKSource]()
    var sourceIdentifier: String?
    
    override func viewDidLoad() {
        let allSources = eventStore.sources
        sourceIdentifier = defaults.string(forKey: sourceDefaultsKey)
        for source in allSources {
            switch source.sourceType {
            case .subscribed:
                break
            case .birthdays:
                break
            default:
                if isSourceWritable(source: source) {
                    sources.append(source)
                }
            }
        }
        self.tableView.reloadData()
    }
    
    func isSourceWritable(source: EKSource) -> Bool {
        let calendar = EKCalendar.init(for: EKEntityType.event, eventStore: eventStore)
        calendar.title = "Workouts to Calendar App"
        calendar.source = source
        do {
            try eventStore.saveCalendar(calendar, commit: false)
            try eventStore.removeCalendar(calendar, commit: false)
            return true
        }
        catch {
            //debugPrint("🚫 testCalendarFrom() -> " + error.localizedDescription)
            return false
        }
    }
    
    // Did Select Row At
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sourceIdentifier = sources[indexPath.row].sourceIdentifier
        defaults.set(sources[indexPath.row].sourceIdentifier, forKey: sourceDefaultsKey)
       
        self.tableView.reloadData()
    }
    // Cell For Row At
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let source = sources[indexPath.row]
        cell.textLabel?.text = source.title
        
        if sourceIdentifier != nil, source.sourceIdentifier == sourceIdentifier! {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
    
        return cell
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    // Number of Rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sources.count
    }
}
