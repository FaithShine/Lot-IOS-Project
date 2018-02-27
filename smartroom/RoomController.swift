//
//  RoomController.swift
//  smartroom
//
//  Created by Bruno Luis Mendivez Vasquez on 12/11/2016.
//  Copyright © 2016 Bruno Luis Mendivez Vasquez. All rights reserved.
//  Main screen - Automatic and manual control of the light. Activation of surveillance mode. Picking of light profile.
//  References
//  MQTT Library (SwiftMQTT) -> https://github.com/aciidb0mb3r/SwiftMQTT
//

import UIKit
import SwiftMQTT

class RoomController: UITableViewController, HSBColorPickerDelegate, pickProfileDelegate, MQTTSessionDelegate {
    
    @IBOutlet weak var lblAmbientLight: UILabel!
    @IBOutlet weak var pvAmbientLight: UIProgressView!
    @IBOutlet weak var lblBrightness: UILabel!
    @IBOutlet weak var cpColor: HSBColorPicker!
    @IBOutlet weak var sldBrightness: UISlider!
    @IBOutlet weak var swSurveillance: UISwitch!
    @IBOutlet weak var swLight: UISwitch!
    @IBOutlet weak var btnColor: UIButton!
    @IBOutlet weak var lblProfile: UILabel!
    
    var currentProfile: Profile?
    var mqttSession: MQTTSession!
    var mqttConnected: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cpColor.delegate = self
        currentProfile = nil
        
        // Default light color stuff
        btnColor.backgroundColor = UIColor.whiteColor()
        btnColor.layer.borderWidth = 1
        btnColor.layer.borderColor = UIColor.blackColor().CGColor
        
        mqttConnected = false
        //connect to server
        connectToMQTTServer()
    }
    
    // send commands to server when toggling light (color and brightness)
    @IBAction func didToggleLight(sender: AnyObject) {
        if swLight.on == true
        {
            let color = btnColor.backgroundColor!
            sldBrightness.setValue(1, animated: true)
            lblBrightness.text = "Brightness (\(Int(sldBrightness.value * 100))%)"
            let brightness = CGFloat(sldBrightness.value)
            setLightColor(Int(color.rgbComponents.red * brightness * 255), green: Int(color.rgbComponents.green * brightness * 255), blue: Int(color.rgbComponents.blue * brightness * 255), brightness: Int(brightness * 100))
        }
        else
        {
            sldBrightness.setValue(0, animated: true)
            lblBrightness.text = "Brightness (\(Int(sldBrightness.value * 100))%)"
            setLightColor(0, green: 0, blue: 0, brightness: 0)
        }
    }
    
    // activate or deactivate the surveillance mode, send message to server
    @IBAction func didToggleSurveillance(sender: UISwitch)
    {
        if mqttConnected == true
        {
            if swSurveillance.on == true
            {
                let dummy: String = "surveillance_on"
                publish(dummy.dataUsingEncoding(NSUTF8StringEncoding)!, channel: "command/surveillance/on")
            }
            else
            {
                let dummy: String = "surveillance_off"
                publish(dummy.dataUsingEncoding(NSUTF8StringEncoding)!, channel: "command/surveillance/off")
            }
        }
        
    }
    // send current brightness value to server
    func setBrightness(value: Int)
    {
        if mqttConnected == true && swLight.on == true
        {
            let BrightnessArray = [ "brightness": value]
            do
            {
                let data = try NSJSONSerialization.dataWithJSONObject(BrightnessArray, options: NSJSONWritingOptions.PrettyPrinted)
                publish(data, channel: "command/brightness")
            } catch let error as NSError {
                print(error.description)
            }

        }
    }
    
    // command to set the color chosen in the app to the server
    func setLightColor(red: Int, green: Int, blue: Int, brightness: Int)
    {
        if mqttConnected == true
        {
            let RGBArray = [ "red": red,
                "green": green,
                "blue": blue,
                "brightness": brightness ]
            do
            {
                let data = try NSJSONSerialization.dataWithJSONObject(RGBArray, options: NSJSONWritingOptions.PrettyPrinted)
                publish(data, channel: "command/color")
            } catch let error as NSError {
                print(error.description)
            }
        }
    }
    
    // connection and subscription handling
    func connectToMQTTServer()
    {
        let host = MyVariables.SERVER_IP_ADDRESS
        let port: UInt16 = 1883
        let clientID = "wuut"
        
        mqttSession = MQTTSession(host: host, port: port, clientID: clientID, cleanSession: true, keepAlive: 15, useSSL: false)
        mqttSession.delegate = self
        print("Trying to connect to \(host) on port \(port) for clientID \(clientID)")
        mqttSession.connect {
            if !$0 {
                print("Error Occurred During connection \($1)")
                return
            }
            print("Connected.")
            // Handle subscriptions
            self.subscribeToChannel("command/color")
            self.subscribeToChannel("command/brightness")
            self.subscribeToChannel("event/ambientLight")
            self.subscribeToChannel("event/doorState")
            self.subscribeToChannel("event/intrusion")
            self.subscribeToChannel("event/color/off")
            self.subscribeToChannel("event/color/on")
            self.subscribeToChannel("command/profile/on")
            self.subscribeToChannel("command/profile/off")
            self.subscribeToChannel("command/surveillance/on")
            self.subscribeToChannel("command/surveillance/off")
            
            //self.setLightColor(0, green: 0, blue: 0, brightness: 0)
        }
    }
    
    //publish messages to server
    func publish(data: NSData, channel: String)
    {
        mqttSession.publishData(data, onTopic: channel, withQoS: .AtMostOnce, shouldRetain: false) {
            if !$0 {
                print("Error Occurred During Publish \($1)")
                return
            }
            print("Published message on channel \(channel)")
        }
    }
    
    //subscribe to channels in server
    func subscribeToChannel(subChannel: String) {
        mqttSession.subscribe(subChannel, qos: .AtMostOnce) {
            if !$0 {
                print("Error Occurred During subscription \($1)")
                return
            }
            print("Subscribed to \(subChannel)")
            self.mqttConnected = true
        }
    }
    
    // delegate function to pick a profile from another screen
    func pickProfile(profile: Profile?) {
        if profile != nil
        {
            self.currentProfile = profile
            self.lblProfile.text = currentProfile?.name
            self.lblProfile.textColor = UIColor(hexString: (currentProfile?.color)!)
            setProfileON()
        }
        else
        {
            self.currentProfile = nil
            self.lblProfile.text = "None"
            self.lblProfile.textColor = UIColor.blackColor()
            setProfileOFF()
        }
    }
    
    // disables all profile values in the server
    func setProfileOFF()
    {
        if (mqttConnected == true)
        {
            let dummy: String = "profile_off"
            publish(dummy.dataUsingEncoding(NSUTF8StringEncoding)!, channel: "command/profile/off")
        }
    }
    
    // enables an automatic profile in the server based on the chosen one
    func setProfileON()
    {
        if (mqttConnected == true)
        {
            let profileColor = UIColor(hexString: (currentProfile?.color)!)
            let colorRed = Int(profileColor!.rgbComponents.red * 255)
            let colorGreen = Int(profileColor!.rgbComponents.green * 255)
            let colorBlue = Int(profileColor!.rgbComponents.blue * 255)
            let offAt: String = (currentProfile?.offAt)!
            let autoDoor: Bool = currentProfile?.doorTrigger as! Bool
            let onAmbLevel: Int = Int((currentProfile?.onAmbientLevel)!)
            let maxBright: Int = Int((currentProfile?.maxBrightness)!)
            let timeToBright: Int = Int((currentProfile?.timeToBrightness)!)
            
            let profileArray = [ "profile_on": true,
                "light_auto_off_time": offAt,
                "light_auto_door": autoDoor,
                "light_color_r": colorRed,
                "light_color_g": colorGreen,
                "light_color_b": colorBlue,
                "light_auto_on_ambl": onAmbLevel,
                "light_max_brightness": maxBright,
                "light_max_br_time": timeToBright ]
            do
            {
                let data = try NSJSONSerialization.dataWithJSONObject(profileArray, options: NSJSONWritingOptions.PrettyPrinted)
                publish(data, channel: "command/profile/on")
            } catch let error as NSError {
                print(error.description)
            }
        }
    }
    
    // change screen to pick profile
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "pickProfileSegue"
        {
            let controller = segue.destinationViewController as! ProfileListController
            controller.delegate = self
        }
    }
    
    // event that triggers the slider movement for brightness
    @IBAction func didChangeBrightness(sender: AnyObject) {
        lblBrightness.text = "Brightness (\(Int(sldBrightness.value * 100))%)"
        setBrightness(Int(sldBrightness.value * 100))
    }
    
    // delegate function for picking a color dynamically
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizerState) {
        btnColor.backgroundColor = color
        if swLight.on == true && color.RGBColor != ""
        {
            let brightness = CGFloat(sldBrightness.value)
            setLightColor(Int(color.rgbComponents.red * brightness * 255), green: Int(color.rgbComponents.green * brightness * 255), blue: Int(color.rgbComponents.blue * brightness * 255), brightness: Int(brightness * 100))
        }
    }
    
    // changes the value and label for the ambient light sensor
    func updateAmbientLightIndicator(value: Float)
    {
        pvAmbientLight.progress = value / 100
        lblAmbientLight.text = "Ambient light level (\(Int(value))%)"
    }
    
    // parse incoming messages from the ambient light sensor
    func parseAmbientLightEvent(jsonData: NSData)
    {
        do
        {
            let json = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)
            let ambientLightLevel = json["level"] as? Double
            updateAmbientLightIndicator(Float(ambientLightLevel!))
        } catch {
            print("Error parsing JSON")
        }
    }
    
    // Notification handler for alerting the user when an intrusion has been detected
    func showDoorOpenAlert()
    {
        // Notify the user when someone entered the room
        let title = "Alert"
        let message = "Intrusion detected!"
        
        if UIApplication.sharedApplication().applicationState == .Active {
            // App is active, show an alert
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(alertAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            // App is inactive, show a notification
            let notification = UILocalNotification()
            notification.alertTitle = title
            notification.alertBody = message
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }
    
    // turn off the lights (controls in the screen only)
    func lightOff()
    {
        swLight.setOn(false, animated: true)
        sldBrightness.setValue(0, animated: true)
        lblBrightness.text = "Brightness (\(Int(sldBrightness.value * 100))%)"
    }
    
    // turn on the lights (controls in the screen only)
    func lightOn(data: NSData)
    {
        do
        {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            let brightnessLevel = json["level"] as? Int
            btnColor.backgroundColor = lblProfile.textColor
            swLight.setOn(true, animated: true)
            sldBrightness.setValue(Float(brightnessLevel!) / 100.0, animated: true)
            lblBrightness.text = "Brightness (\(Int(sldBrightness.value * 100))%)"
        } catch {
            print("Error parsing JSON")
        }
    }
    
    // parse incoming events from the server
    func parseMQTTIncomingMessage(topic: String, data: NSData)
    {
        switch(topic)
        {
            case "event/ambientLight":
                parseAmbientLightEvent(data)
                break
            case "event/intrusion":
                showDoorOpenAlert()
                break
            case "event/color/off":
                lightOff()
                break
            case "event/color/on":
                lightOn(data)
                break
            default:
                print("Unknown topic")
        }
    }
    // MARK: - MQTTSessionDelegates
    
    func mqttSession(session: MQTTSession, didReceiveMessage message: NSData, onTopic topic: String) {
        let string = String(data: message, encoding: NSUTF8StringEncoding)!
        print("data received on topic \(topic) message \(string)")
        
        parseMQTTIncomingMessage(topic, data: message)
    }
    
    func didDisconnectSession(session: MQTTSession) {
        print("Session Disconnected")
        mqttConnected = false
    }
    
    func socketErrorOccurred(session: MQTTSession) {
        print("Socket error occurred")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
