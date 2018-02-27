//
//  ProfileDetailController.swift
//  smartroom
//
//  Created by Bruno Luis Mendivez Vasquez on 12/11/2016.
//  Copyright © 2016 Bruno Luis Mendivez Vasquez. All rights reserved.
//
//  ref dismiss on drag, to hide pickers and keyboard: http://stackoverflow.com/questions/2321038/dismiss-keyboard-by-touching-background-of-uitableview
//
import UIKit
import CoreData

protocol addProfileDelegate
{
    func addProfile(profile: Profile)
    func updateProfiles()
}

class ProfileDetailController: UITableViewController, HSBColorPickerDelegate {

    @IBOutlet weak var scTimeToMax: UISegmentedControl!
    @IBOutlet weak var lblTimeToMax: UILabel!
    @IBOutlet weak var sldMaxBrightness: UISlider!
    @IBOutlet weak var lblMaxBrightness: UILabel!
    @IBOutlet weak var sldAmbientLight: UISlider!
    @IBOutlet weak var lblAmbientLight: UILabel!
    @IBOutlet weak var cpColor: HSBColorPicker!
    @IBOutlet weak var txtOffAt: UITextField!
    @IBOutlet weak var btnColor: UIButton!
    @IBOutlet weak var txtProfileName: UITextField!
    @IBOutlet weak var swDoorToggle: UISwitch!
    
    var delegate: addProfileDelegate?
    var managedObjectContext: NSManagedObjectContext
    var editingProfile: Profile?
    var selectedTime: String?
    
    // CoreDate initialization
    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        self.managedObjectContext = appDelegate.managedObjectContext
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cpColor.delegate = self
        
        swDoorToggle.setOn(false, animated: false)
        
        // Default light color stuff
        btnColor.backgroundColor = UIColor.whiteColor()
        btnColor.layer.borderWidth = 1
        btnColor.layer.borderColor = UIColor.blackColor().CGColor
        selectedTime = ""
        
        // if the profile is being edited, show data on the controller
        if let profile = editingProfile
        {
            txtProfileName.text = profile.name
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let date = dateFormatter.dateFromString(profile.offAt!)
            dateFormatter.dateFormat = "h:mm a"
            txtOffAt.text = "Lights OFF at " + dateFormatter.stringFromDate(date!)
            
            selectedTime = profile.offAt!
            swDoorToggle.setOn(profile.doorTrigger as! Bool, animated: false)
            let profileColor = UIColor(hexString: profile.color!)
            btnColor.backgroundColor = profileColor
            lblAmbientLight.text = "ON at ambient light level (\(Int(profile.onAmbientLevel!))%)"
            sldAmbientLight.setValue(Float(profile.onAmbientLevel!) / 100.0, animated: false)
            lblMaxBrightness.text = "Maximum brightness (\(Int(profile.maxBrightness!))%)"
            sldMaxBrightness.setValue(Float(profile.maxBrightness!) / 100.0, animated: false)
            scTimeToMax.selectedSegmentIndex = (Int(profile.timeToBrightness!) / 5) - 1
        }
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
    
    // validation
    func isValidProfile() -> String
    {
        var msgUser: String?
        
        if txtProfileName.text == ""
        {
            msgUser = "A profile name is required!"
            return msgUser!
        }
        if txtOffAt.text == "" || selectedTime == ""
        {
            msgUser = "A turn off time is required!"
            return msgUser!
        }
        return ""
    }
    
    @IBAction func saveProfile(sender: AnyObject) {
        let msgUser = isValidProfile()
        if msgUser != ""
        {
            let alertController = UIAlertController(title: "Alert", message: msgUser, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Got it", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else
        {
            // existing profile
            if editingProfile != nil
            {
                editingProfile?.name = txtProfileName.text
                editingProfile?.offAt = selectedTime
                editingProfile?.doorTrigger = swDoorToggle.on
                editingProfile?.color = btnColor.backgroundColor?.htmlRGBaColor
                editingProfile?.onAmbientLevel = Int(sldAmbientLight.value * 100)
                editingProfile?.maxBrightness = Int(sldMaxBrightness.value * 100)
                editingProfile?.timeToBrightness = (scTimeToMax.selectedSegmentIndex + 1) * 5
                self.delegate?.updateProfiles()
            }
            else // new profile
            {
                let newProfile: Profile = (NSEntityDescription.insertNewObjectForEntityForName("Profile", inManagedObjectContext: self.managedObjectContext) as? Profile)!
                newProfile.name = txtProfileName.text
                newProfile.offAt = selectedTime
                newProfile.doorTrigger = swDoorToggle.on
                newProfile.color = btnColor.backgroundColor?.htmlRGBaColor
                newProfile.onAmbientLevel = Int(sldAmbientLight.value * 100)
                newProfile.maxBrightness = Int(sldMaxBrightness.value * 100)
                newProfile.timeToBrightness = (scTimeToMax.selectedSegmentIndex + 1) * 5
                self.delegate?.addProfile(newProfile)
            }
            exitViewController()
        }
    }
    
    // format conversion (we want 24H internally), ref: http://stackoverflow.com/questions/29321947/xcode-swift-am-pm-time-to-24-hour-format
    func datePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        txtOffAt.text = "Lights OFF at " + dateFormatter.stringFromDate(sender.date)
        let dateString = dateFormatter.stringFromDate(sender.date)
        
        dateFormatter.dateFormat = "h:mm a"
        let date = dateFormatter.dateFromString(dateString)
        dateFormatter.dateFormat = "HH:mm"
        selectedTime = dateFormatter.stringFromDate(date!)
    }
    
    //When textfield is being edited, show datepicker
    // ref: http://blog.apoorvmote.com/change-textfield-input-to-datepicker/
    @IBAction func editDidBeginOffAt(sender: UITextField) {
        let datePickerView:UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.Time
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: "datePickerValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    @IBAction func didChangeMaxBrightness(sender: AnyObject) {
        lblMaxBrightness.text = "Maximum brightness (\(Int(sldMaxBrightness.value * 100))%)"
    }
    @IBAction func didChangeAmbientLight(sender: AnyObject) {
        lblAmbientLight.text = "ON at ambient light level (\(Int(sldAmbientLight.value * 100))%)"
    }

    // color picker delegate, to chagen color dynamically
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizerState) {
        btnColor.backgroundColor = color
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
