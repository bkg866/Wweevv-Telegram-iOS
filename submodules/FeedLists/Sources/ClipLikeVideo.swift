//
//  ClipLikeVideo.swift
//  _idx_FeedLists_7162C0DC_ios_min13.0
//

import Foundation
import UIKit

public struct ClipLikeVideo: Codable {

    public let userId: Int64
    public let videoId: String
    public let type: Int
    
    public init(userId: Int64, videoId: String, type: VideoTypes) {
        self.userId = userId
        self.videoId = videoId
        self.type = type.rawValue
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case videoId = "video_id"
        case type = "video_type"
    }
}
