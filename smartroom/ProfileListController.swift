//
//  ProfileListController.swift
//  smartroom
//
//  Created by Bruno Luis Mendivez Vasquez on 12/11/2016.
//  Copyright © 2016 Bruno Luis Mendivez Vasquez. All rights reserved.
//  Screen that shows a list of existing profiles to pick from

import UIKit
import CoreData

protocol pickProfileDelegate
{
    func pickProfile(profile: Profile?)
}

class ProfileListController: UITableViewController {

    var managedObjectContext: NSManagedObjectContext
    var profileList: NSMutableArray
    var currentProfileCollection: ProfileCollection?
    var delegate: pickProfileDelegate?
    
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
        return false
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let p: Profile = self.profileList[indexPath.row] as! Profile
        self.delegate?.pickProfile(p)
        exitViewController()
    }

    //reference InventoryManager demo (moodle)
    //closes curent view, shows previous
    func exitViewController()
    {
        let isPresentingInAddMode = presentingViewController is UITabBarController
        if isPresentingInAddMode {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            navigationController!.popViewControllerAnimated(true)
        }
    }
    
    @IBAction func pickNoProfile(sender: AnyObject) {
        self.delegate?.pickProfile(nil)
        exitViewController()
    }

}
