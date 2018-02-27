//
//  ProfileMasterController.swift
//  smartroom
//
//  Created by Bruno Luis Mendivez Vasquez on 12/11/2016.
//  Copyright © 2016 Bruno Luis Mendivez Vasquez. All rights reserved.
//  Main screen for handling the profiles (allows edition and deletion)

import UIKit
import CoreData

class ProfileMasterController: UITableViewController, addProfileDelegate {

    var managedObjectContext: NSManagedObjectContext
    var profileList: NSMutableArray
    var currentProfileCollection: ProfileCollection?
    
    // Core Data Initialization
    required init?(coder aDecoder: NSCoder) {
        self.profileList = NSMutableArray()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        self.managedObjectContext = appDelegate.managedObjectContext
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // get all profiles stored in the application
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("ProfileCollection", inManagedObjectContext: self.managedObjectContext)
        fetchRequest.entity = entityDescription
        var result = NSArray?()
        do
        {
            result = try self.managedObjectContext.executeFetchRequest(fetchRequest)
            if result!.count == 0
            {
                self.currentProfileCollection = ProfileCollection.init(entity: NSEntityDescription.entityForName("ProfileCollection", inManagedObjectContext:
                    self.managedObjectContext)!, insertIntoManagedObjectContext: self.managedObjectContext)
            }
            else
            {
                self.currentProfileCollection = result![0] as? ProfileCollection
                self.profileList = NSMutableArray(array: (currentProfileCollection!.profiles?.allObjects as! [Profile]))
            }
        }
        catch
        {
            let fetchError = error as NSError
            print(fetchError)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.profileList.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "profileCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ProfileCell
        
        let p: Profile = self.profileList[indexPath.row] as! Profile
        cell.lblProfile.text = p.name
        cell.lblProfile.textColor = UIColor(hexString: p.color!)
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            managedObjectContext.deleteObject(profileList.objectAtIndex(indexPath.row) as! NSManagedObject)
            self.profileList.removeObjectAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            do
            {
                try self.managedObjectContext.save()
            }
            catch let error
            {
                print("Could not save Deletion \(error)")
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addProfileSegue"
        {
            let controller = segue.destinationViewController as! ProfileDetailController
            controller.managedObjectContext = self.managedObjectContext
            controller.delegate = self
        }
        else if segue.identifier == "showProfileSegue"
        {
            let profileDetailController = segue.destinationViewController as! ProfileDetailController
            profileDetailController.managedObjectContext = self.managedObjectContext
            profileDetailController.delegate = self
            
            if let selectedCell = sender as? UITableViewCell {
                let indexPath = tableView.indexPathForCell(selectedCell)!
                let p: Profile = self.profileList[indexPath.row] as! Profile
                profileDetailController.editingProfile = p
            }
        }
    }

    // delegate function to update editing profile with persistency
    func updateProfiles() {
        self.profileList = NSMutableArray(array: (currentProfileCollection!.profiles?.allObjects as! [Profile]))
        self.tableView.reloadData()
        do
        {
            try self.managedObjectContext.save()
        }
        catch let error
        {
            print("Could not save data \(error)")
        }
    }
    
    // delegate function to add a new profile
    func addProfile(profile: Profile) {
        self.currentProfileCollection?.addProfile(profile)
        self.profileList = NSMutableArray(array: (currentProfileCollection!.profiles?.allObjects as! [Profile]))
        self.tableView.reloadData()
        do
        {
            try self.managedObjectContext.save()
        }
        catch let error
        {
            print("Could not save data \(error)")
        }
    }
    

}
