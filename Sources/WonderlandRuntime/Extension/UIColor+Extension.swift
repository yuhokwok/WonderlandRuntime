//
//  GradientColor.swift
//  FBPLand
//
//  Created by Reality Builder Team on 29/4/2022.
//

import UIKit
import SwiftUI
//
extension UIColor {
    
    var color : Color {
        return Color(uiColor: self)
    }
    
    static var undoRedo : UIColor {
        return #colorLiteral(red: 0.2413710952, green: 0.3599274755, blue: 0.4221712351, alpha: 1)
    }
    
    static var panelSectionGray : UIColor {
        return #colorLiteral(red: 0.9559871554, green: 0.9609465003, blue: 0.9608612657, alpha: 1)
    }
    
    static var panelGray : UIColor {
        return .white
    }
    
    static var utilityLightGray : UIColor {
        return #colorLiteral(red: 0.8945302963, green: 0.9143494964, blue: 0.9269376397, alpha: 1)
    }
    
    static var utilityBlue : UIColor {
        return #colorLiteral(red: 0.002443414647, green: 0.1713039279, blue: 0.3619536161, alpha: 1)
    }
    
    static var utilityBlueSecondary : UIColor {
        return #colorLiteral(red: 0.20403862, green: 0.42433092, blue: 0.6324217916, alpha: 1)
    }
    
    
    static var inputPrimary : UIColor {
        return #colorLiteral(red: 0.9855625033, green: 0.2636899054, blue: 0.4172780514, alpha: 1)
    }
    static var inputSecondary : UIColor {
        return #colorLiteral(red: 1, green: 0.5043635368, blue: 0.7664001584, alpha: 1)
    }
    
    static var middlePrimary : UIColor {
        return #colorLiteral(red: 0, green: 0.5659229159, blue: 0.6375774145, alpha: 1)
    }
    static var middleSecondary : UIColor {
        return #colorLiteral(red: 0, green: 0.8882648349, blue: 0.9956681132, alpha: 1)
    }
    
    static var outputPrimary : UIColor {
        return #colorLiteral(red: 1, green: 0.6924734712, blue: 0.2488802969, alpha: 1)
    }
    static var outputSecondary : UIColor {
        return #colorLiteral(red: 1, green: 0.6210629344, blue: 0.2177203298, alpha: 1)
    }
    
    static var objectPrimary : UIColor {
        return #colorLiteral(red: 0.8313413262, green: 0.4501733184, blue: 0.9898169637, alpha: 1)
    }
    static var objectSecondary : UIColor {
        return #colorLiteral(red: 0.6728597283, green: 0.4100296497, blue: 0.9888545871, alpha: 1)
    }
    
    static var borderYellow : UIColor {
        return #colorLiteral(red: 1, green: 0.9233352542, blue: 0.1794297695, alpha: 1)
    }
    
    static var voxelGray : UIColor {
        return #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
    }
    
    static func getColor(for blockType: String, isPrimary: Bool) -> UIColor {
        if isPrimary == true {
            switch (blockType){
            case "input":
                return .inputPrimary
            case "middle":
                return .middlePrimary
            case "output":
                return .outputPrimary
            default:
                return .objectPrimary
            }
        } else {
            switch (blockType){
            case "input":
                return .inputSecondary
            case "middle":
                return .middleSecondary
            case "output":
                return .outputSecondary
            default:
                return .objectSecondary
            }
        }
    }
    
    static func color (from hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    var hex: String {
        return String(format: "#%02x%02x%02x", Int(rgba.red * 255), Int(rgba.green * 255), Int(rgba.blue * 255))
    }
}

func getGradientLayout(from : UIColor, to : UIColor) -> CAGradientLayer {
    let gradient = CAGradientLayer()

    gradient.frame = .zero
    gradient.colors = [from.cgColor, to.cgColor]
    
    gradient.startPoint = CGPoint(x: 0.5, y: 0)
    gradient.endPoint = CGPoint(x: 0.5, y: 1)
    
    return gradient
}


extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (r,g,b,a)
        }
        return (0, 0, 0, 0)
    }
    
    //    var htmlRGBA: String {
    //        return String(format: "#%02x%02x%02x%02x", Int(rgba.red * 255), Int(rgba.green * 255), Int(rgba.blue * 255), Int(rgba.alpha * 255) )
    //    }
    var htmlRGB: String {
        return String(format: "#%02x%02x%02x", Int(rgba.red * 255), Int(rgba.green * 255), Int(rgba.blue * 255))
    }
    
    func toSIMD4() -> SIMD4<Float> {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        
        return SIMD4(Float(red), Float(green), Float(blue), Float(alpha))
    }
}


extension UIColor {
    static func color(hex : String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    
}
