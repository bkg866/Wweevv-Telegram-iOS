//
//  UIDevice+Extensions.swift
//  CrissCross
//
//  Created by Kyle Lee on 9/4/20.
//  Copyright © 2020 Kilo Loco. All rights reserved.
//

import UIKit

extension UIDevice {
    var hasNotch: Bool {
        let bottom = UIApplication.shared.currentWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
}
extension UIApplication {
    var currentWindow: UIWindow? {
        connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first
    }
}
