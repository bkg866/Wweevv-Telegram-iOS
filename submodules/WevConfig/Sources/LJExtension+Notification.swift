//
//  LJExtension+Notification.swift
//  Wweevv
//
//  Created by panjinyong on 2020/12/22.
//

import Foundation
extension Notification.Name: LJExtensionCompatible {}
extension LJExtension where Base == Notification.Name {
    /// 包名
    public static let bundleId = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    
    /// 用户信息更新
    public static let didUpdatedUserInfo = Notification.Name.init("\(bundleId).didUpdatedUserInfo")
    
    /// 关联了新账号
    public static let didConnectedAccount = Notification.Name.init("\(bundleId).didConnectedAccount")

    /// 取消关联了某账号
    public static let didDisconnectedAccount = Notification.Name.init("\(bundleId).didDisconnectedAccount")

    /// 订阅了某主播
    public static let didSubscribeAnchor = Notification.Name.init("\(bundleId).didSubscribeAnchor")

    /// 取消订阅某主播
    public static let didUnsubscribeAnchor = Notification.Name.init("\(bundleId).didUnsubscribeAnchor")

    
}
