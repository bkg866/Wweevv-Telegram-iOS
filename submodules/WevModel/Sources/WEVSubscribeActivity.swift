//
//  WEVSubscribeActivity.swift
//  _idx_ContactListUI_AE77A1D0_ios_min13.0
//
//  Created by Apple on 11/11/22.
//

import Foundation
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   public let projectRegionCrews = try? newJSONDecoder().decode(ProjectRegionCrews.self, from: jsonData)

// MARK: - ProjectRegionCrews
public struct WEVSubscribeActivity: Codable {
    public let kind, etag: String
    public let items: [Item]
    public let nextPageToken: String
    public let pageInfo: PageInfo
}

// MARK: - Item
public struct Item: Codable {
    public let kind, etag, id: String
    public let snippet: Snippet
    public let contentDetails: ContentDetails
    public var subscribeId: Int64?
}

// MARK: - ContentDetails
public struct ContentDetails: Codable {
    public let upload: Upload
}

// MARK: - Upload
public struct Upload: Codable {
    public let videoID: String

    enum CodingKeys: String, CodingKey {
        case videoID = "videoId"
    }
}

// MARK: - Snippet
public struct Snippet: Codable {
    public let publishedAt: Date
    public let channelID, title, snippetDescription: String
    public let thumbnails: Thumbnails
    public let type: String

    enum CodingKeys: String, CodingKey {
        case publishedAt
        case channelID = "channelId"
        case title
        case snippetDescription = "description"
        case thumbnails, type
    }
}

// MARK: - Thumbnails
public struct Thumbnails: Codable {
    public let thumbnailsDefault, medium, high: Default
    public let standard: Default?
    public let maxres: Default?

    enum CodingKeys: String, CodingKey {
        case thumbnailsDefault = "default"
        case medium, high, standard, maxres
    }
}

// MARK: - Default
public struct Default: Codable {
    public let url: String
    public let width, height: Int
}

// MARK: - PageInfo
public struct PageInfo: Codable {
    public let totalResults, resultsPerPage: Int
}
