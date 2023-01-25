//
//  WEVChannel.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import HandyJSON
import UIKit


public struct SlimVideo: Codable {
    public let id: String // youtube id
    public let blob:String  // youtube payload
    public let channelId: String?
    public let channelTitle: String?
    public let is_live: Bool
}

public struct Thumbnail: Codable {
    public let url: String? // youtube id
    public let width:Int  // youtube payload
    public let height:Int
}
public struct YoutubeVideo: Codable {
    public let id: String // youtube id
    public let title:String  // youtube payload
    public let thumbnails:[Thumbnail?]
    public let description:String?
    public let duration:String?
    public var isLive:Bool?
    public let viewCount:Int64?
    public var channelId: String?
    public var channelTitle: String?
}
