//
//  LJHelper.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

/// 字体
public struct LJFont {
    
    public static func regular(_ size: CGFloat) -> UIFont {
        UIFont(name: "Rubik-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }

    public static func medium(_ size: CGFloat) -> UIFont {
        UIFont(name: "Rubik-Medium", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    public static func bold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Rubik-Bold", size: size) ?? UIFont.systemFont(ofSize: size)
    }

}

public struct LJColor {
    
    public static let main = Self.hex(0x128A84)
    
    public static let black = Self.hex(0x353535)
   
    public static let gray = Self.hex(0x868686)
    
    /// 分割线的灰色
    public static let lineGray = Self.hex(0xE6E6E6)

    /// 灰色背景
    public static let grayBg = Self.hex(0xE6E6E6)

    public static func hex(_ hex: UInt, _ alpha: CGFloat = 1) -> UIColor {
        UIColor.lj.hex(hex, alpha)
    }
}

public struct LJScreen {
    //屏幕大小
    public static let height: CGFloat = UIScreen.main.bounds.size.height
    public static let width: CGFloat = UIScreen.main.bounds.size.width
    
    //iPhoneX的比例
    public static let scaleWidthOfIX = UIScreen.main.bounds.size.width / 375.0
    public static let scaleHeightOfIX = UIScreen.main.bounds.size.height / 812.0
    public static let scaleHeightLessOfIX = scaleHeightOfIX > 1 ? 1 : scaleHeightOfIX
    public static let scaleWidthLessOfIX = scaleWidthOfIX > 1 ? 1 : scaleWidthOfIX


    // iphoneX
    public static let navigationBarHeight: CGFloat =  isiPhoneXMore() ? 88.0 : 64.0
    public static let safeAreaBottomHeight: CGFloat =  isiPhoneXMore() ? 34.0 : 0
    public static let statusBarHeight: CGFloat = isiPhoneXMore() ? 44.0 : 20.0
    public static let tabBarHeight: CGFloat = isiPhoneXMore() ? 83.0 : 49.0

    // iphoneX
    public static func isiPhoneXMore() -> Bool {
        var isMore:Bool = true
        if #available(iOS 11.0, *) {
            let keywindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            isMore = keywindow?.safeAreaInsets.bottom ?? 0 > CGFloat(0)
        }
        return isMore
    }

}

