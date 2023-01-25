//
//  LJExtension+UIFont.swift
//  Wweevv
//
//  Created by panjinyong on 2020/12/22.
//

import UIKit
extension UIFont: LJExtensionCompatible {}

extension LJExtension where Base == UIFont {
    
    public static func main(_ size: CGFloat) -> UIFont {
        regular(size)
    }
    
    public static func regular(_ size: CGFloat) -> UIFont {
        UIFont(name: "PingFangSC-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    public static func semibol(_ size: CGFloat) -> UIFont {
        UIFont(name: "PingFangSC-Semibold", size: size) ?? UIFont.systemFont(ofSize: size)
    }

    public static func medium(_ size: CGFloat) -> UIFont {
        UIFont(name: "PingFangSC-Medium", size: size) ?? UIFont.systemFont(ofSize: size)
    }

    public static func light(_ size: CGFloat) -> UIFont {
        UIFont(name: "PingFangSC-Light", size: size) ?? UIFont.systemFont(ofSize: size)
    }


}
