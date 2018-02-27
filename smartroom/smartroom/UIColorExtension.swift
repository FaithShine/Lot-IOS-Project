//
//  UIColorExtensions.swift
//  reminder_app
//
//  Reference http://stackoverflow.com/a/36342082
//  Extensions for the UIColor class. Added methods to convert UIColor to #hex and viceversa.
//  Added function to calculate UIColor from RGB values (no alpha)

import Foundation
import UIKit

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
    // hue, saturation, brightness and alpha components from UIColor**
    var hsbComponents:(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var hue:CGFloat = 0
        var saturation:CGFloat = 0
        var brightness:CGFloat = 0
        var alpha:CGFloat = 0
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha){
            return (hue,saturation,brightness,alpha)
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
    
    var htmlRGBaColor:String {
        let red = rgbComponents.red * 255
        let green = rgbComponents.green * 255
        let blue = rgbComponents.blue * 255
        let alpha = rgbComponents.alpha * 255
        if (red.isNaN || green.isNaN || blue.isNaN || alpha.isNaN)
        {
            return ""
        }
        else
        {
            return String(format: "#%02x%02x%02x%02x", Int(red), Int(green),Int(blue),Int(alpha))
        }
    }
    
    
    
    /*
    var htmlRGBaColor:String {
    return String(format: "#%02x%02x%02x%02x", Int(rgbComponents.red * 255), Int(rgbComponents.green * 255),Int(rgbComponents.blue * 255),Int(rgbComponents.alpha * 255) )
    }*/
}

extension UIColor {
    
    static func colorFromRGB(redValue: Int, greenValue: Int, blueValue: Int) -> UIColor {
        let m = min(redValue, greenValue, blueValue)
        let alpha = CGFloat(255 - m)/255
        let rgba_red = Int(CGFloat(redValue - m)/alpha)
        let rgba_green = Int(CGFloat(greenValue - m) / alpha)
        let rgba_blue = Int(CGFloat(blueValue - m) / alpha)
        
        return UIColor(red: CGFloat(rgba_red)/255, green: CGFloat(rgba_green)/255, blue: CGFloat(rgba_blue)/255, alpha: alpha)
    }
    
    //Constructor extension to support htmlRGBaColor strings
    public convenience init?(hexString: String) {
        let r, g, b, a: CGFloat
        
        if hexString.hasPrefix("#") {
            let start = hexString.startIndex.advancedBy(1)
            let hexColor = hexString.substringFromIndex(start)
            
            if hexColor.characters.count == 8 {
                let scanner = NSScanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexLongLong(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
}