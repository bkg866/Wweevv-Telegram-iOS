//
//  WEVChannel.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

// MARK: - Crew
public struct RumbleVideo: Codable {
    public let id: Int64
    public let title: String
    public let thumbnailUrl: String
    public let embedUrl: String
    public let m3u8Url: String?
    public let viewerCount: Int64
    public let likeCount: Int64?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case thumbnailUrl = "thumbnail_url"
        case embedUrl = "embed_url"
        case m3u8Url = "m3u8"
        case viewerCount = "viewer_count"
        case likeCount = "video_likes"
    }
}

//MARK:- Tiktok Video

// MARK: - Crew
public struct TikTokVideo: Codable {
    public let id: Int64
    public let title: String?
    public let thumbnailUrl: String
    public let embedUrl: String?
    public let m3u8Url: String
    public let viewerCount: Int64
    public let likeCount: Int64?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case thumbnailUrl = "thumbnail_url"
        case embedUrl = "embed_url"
        case m3u8Url = "m3u8"
        case viewerCount = "viewer_count"
        case likeCount = "video_likes"
    }
}
