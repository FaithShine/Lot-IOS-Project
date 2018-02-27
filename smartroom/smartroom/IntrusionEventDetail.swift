//
//  IntrusionEventDetail.swift
//  smartroom
//
//  Created by Bruno Luis Mendivez Vasquez on 14/11/2016.
//  Copyright © 2016 Bruno Luis Mendivez Vasquez. All rights reserved.
//  Screen that shows the details of a intrusion event (picture and metadata)

import UIKit

class IntrusionEventDetail: UIViewController {
    
    @IBOutlet weak var lblIntrusionDate: UILabel!
    @IBOutlet weak var lblIntrusionTime: UILabel!
    @IBOutlet weak var pvPicture: UIImageView!

    var currentTimestamp: Double?
    
    // load the contents of a selected cell in the current view controller
    override func viewDidLoad() {
        super.viewDidLoad()

        pvPicture.contentMode = UIViewContentMode.ScaleAspectFit
        
        if let timestamp = currentTimestamp {
            let date = NSDate(timeIntervalSince1970: timestamp / 1000)
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            lblIntrusionDate.text = "Date: " + dateFormatter.stringFromDate(date)
            dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
            dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
            lblIntrusionTime.text = "Time: " + dateFormatter.stringFromDate(date)
            getImageFromURL()
        }
    }

    // dynamic alerts
    func showAlert(msg: String)
    {
        let alertController = UIAlertController(title: "Alert", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Got it", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // REST request tutorial: https://www.youtube.com/watch?v=uQ_MyVDiSbo
    // handle images in swift http://stackoverflow.com/questions/24231680/loading-downloading-image-from-url-on-swift
    func getImageFromURL()
    {
        let endPoint: String = "http://\(MyVariables.SERVER_IP_ADDRESS):8080/api/intrusion/\(Int(currentTimestamp!))"
        let session = NSURLSession.sharedSession()
        let url = NSURL(string: endPoint)!
        
        session.dataTaskWithURL(url, completionHandler: { ( data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard let realResponse = response as? NSHTTPURLResponse where realResponse.statusCode == 200 else
            {
                print("Not a 200 response")
                self.performSelectorOnMainThread("showAlert:", withObject: "Can't retrieve the image. No such file.", waitUntilDone: false)
                return
                
            }
            self.performSelectorOnMainThread("updateImage:", withObject: data!, waitUntilDone: false)
        }).resume()
    }
    
    // handle images in swift http://stackoverflow.com/questions/24231680/loading-downloading-image-from-url-on-swift
    func updateImage(imgData: NSData)
    {
        self.pvPicture.image = UIImage(data: imgData)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
