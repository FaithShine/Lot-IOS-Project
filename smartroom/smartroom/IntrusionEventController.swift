//
//  IntrusionEventController.swift
//  smartroom
//
//  Created by Bruno Luis Mendivez Vasquez on 14/11/2016.
//  Copyright © 2016 Bruno Luis Mendivez Vasquez. All rights reserved.
//  Screen that shows all the intrusion events stores in the server

import UIKit

class IntrusionEventController: UITableViewController {

    var intrusionEvents = [Double]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getQueryResult()
    }

    @IBAction func reload(sender: UIBarButtonItem) {
        getQueryResult()
    }
    
    // REST request tutorial: https://www.youtube.com/watch?v=uQ_MyVDiSbo
    func getQueryResult()
    {
        if intrusionEvents.count > 0
        {
            intrusionEvents.removeAll()
        }
        let postEndpoint:String = "http://\(MyVariables.SERVER_IP_ADDRESS):8080/api/intrusion"
        let session = NSURLSession.sharedSession()
        let url = NSURL(string: postEndpoint)!
        
        session.dataTaskWithURL(url, completionHandler: { ( data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard let realResponse = response as? NSHTTPURLResponse where
                realResponse.statusCode == 200 else {
                    print("Not a 200 response")
                    self.performSelectorOnMainThread("showAlert:", withObject: "Can't connect to the server", waitUntilDone: false)
                    return
            }
            // Read the JSON
            do {
                if let jsonString = NSString(data:data!, encoding: NSUTF8StringEncoding) {
                    print(jsonString)
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    let status = json["status"] as! String
                    if (status == "success")
                    {
                        if let payload = json["payload"] as? [[String: AnyObject]] {
                            for event in payload {
                                self.intrusionEvents.append(event["timestamp"]! as! Double)
                            }
                        }
                    }
                }
                //reload viewTable async http://www.kaleidosblog.com/swift-uitableview-load-data-from-json
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                    return
                })
            } catch {
                print("bad things happened")
            }
        }).resume()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showIntrusionDetailSegue"
        {
            let intrusionDetailController = segue.destinationViewController as! IntrusionEventDetail
            
            if let selectedCell = sender as? UITableViewCell {
                let indexPath = tableView.indexPathForCell(selectedCell)!
                let t: Double = self.intrusionEvents[indexPath.row]
                intrusionDetailController.currentTimestamp = t
            }
        }
    }
    
    // dynamic alerts
    func showAlert(msg: String)
    {
        let alertController = UIAlertController(title: "Alert", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Got it", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
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
        return self.intrusionEvents.count
    }
    
    // cell handler for representing the data on the table
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "intrusionEventCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! IntrusionCell
        let interval = intrusionEvents[indexPath.row]
        let date = NSDate(timeIntervalSince1970: interval / 1000)
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
        cell.lblIntrusionTitle.text = dateFormatter.stringFromDate(date)
        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
        cell.lblIntrusionSubtitle.text = dateFormatter.stringFromDate(date)
        
        return cell
    }


}
