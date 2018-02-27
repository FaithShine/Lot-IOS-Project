//
//  ViewController.swift
//  mqtt
//
//  Created by Bruno Luis Mendivez Vasquez on 9/11/2016.
//  Copyright © 2016 Bruno Luis Mendivez Vasquez. All rights reserved.
//

import UIKit
import SwiftMQTT

class ViewController: UIViewController, MQTTSessionDelegate, HSBColorPickerDelegate {

    @IBOutlet weak var viewer: UIImageView!
    @IBOutlet weak var colorPicker: HSBColorPicker!
    var mqttSession: MQTTSession!
    
    var mqttConnected: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorPicker.delegate = self
        mqttConnected = false
        getImageFromURL()
        //establishConnection()
    }

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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getImageFromURL()
    {
        let endPoint: String = "http://118.139.71.81:8080/api/camera"
        let session = NSURLSession.sharedSession()
        let url = NSURL(string: endPoint)!
        
        session.dataTaskWithURL(url, completionHandler: { ( data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard let realResponse = response as? NSHTTPURLResponse where realResponse.statusCode == 200 else
            {
                print("Not a 200 response")
                return
                
            }
            self.performSelectorOnMainThread("updateImage:", withObject: data!, waitUntilDone: false)
            
        }).resume()
    }
    
    func updateImage(imgData: NSData)
    {
        self.viewer.image = UIImage(data: imgData)
    }
    
    func establishConnection() {
        let host = "118.139.78.203"
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
            self.subscribeToChannel("command/color")
        }
    }

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
    
    // MARK: - ColorPicker Delegate
    
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizerState) {
        // consider other states for changing the color in the application, only send the last color to the server
        if mqttConnected == true && state == .Ended
        {
            if color.RGBColor != ""
            {
                let RGBArray = [ "red": Int(color.rgbComponents.red * 255),
                    "green": Int(color.rgbComponents.green * 255),
                    "blue": Int(color.rgbComponents.blue * 255)]
                do
                {
                    let data = try NSJSONSerialization.dataWithJSONObject(RGBArray, options: NSJSONWritingOptions.PrettyPrinted)
                    publish(data, channel: "command/color")
                    //let json = String(data: data, encoding: NSUTF8StringEncoding)
                } catch let error as NSError {
                    print(error.description)
                }
                
                
            }
        }
    }
    
    // MARK: - MQTTSessionDelegates
    
    func mqttSession(session: MQTTSession, didReceiveMessage message: NSData, onTopic topic: String) {
        let string = String(data: message, encoding: NSUTF8StringEncoding)!
        print("data received on topic \(topic) message \(string)")
    }
    
    func didDisconnectSession(session: MQTTSession) {
        print("Session Disconnected")
        mqttConnected = false
    }
    
    func socketErrorOccurred(session: MQTTSession) {
        print("Socket error occurred")
    }
}

extension UIColor {
    var rgbComponents:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (r,g,b,a)
        }
        return (0,0,0,0)
    }
    
    var RGBColor:String {
        let red = rgbComponents.red * 255
        let green = rgbComponents.green * 255
        let blue = rgbComponents.blue * 255
        if (red.isNaN || green.isNaN || blue.isNaN)
        {
            return ""
        }
        else
        {
            return String(format: "%d, %d, %d", Int(red), Int(green),Int(blue))
        }
    }
}
