//
//  WEVChannel.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

// MARK: - Crew
public struct WevUser: Codable {
    public let userId: Int64
    public let firstname: String?
    public let lastname: String?
    public let username: String?
    public let phone: String?
    public let referralcode: String?

    
    public init(userId: Int64, firstname: String?, lastname: String?, username: String?, phone: String?, referralcode: String?) {
        self.userId = userId
        self.firstname = firstname
        self.lastname = lastname
        self.username = username
        self.phone = phone
        self.referralcode = referralcode
    }
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case firstname = "first_name"
        case lastname = "last_name"
        case username = "username"
        case phone = "phone"
        case referralcode = "referral_code"
    }
}
// MARK: - Crew
public struct Points: Codable {
    public let id: Int64
    public let userId: Int64?
    public let pointType: Int?
    public let points: Int64?
    public let friendUserId: Int64?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case pointType = "point_type"
        case points = "points"
        case friendUserId = "friend_user_id"
    }
}

public struct PointsInsert: Codable {
    public let userId: Int64?
    public let pointType: Int?
    public let points: Int64?
    public let friendUserId: Int64?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case pointType = "point_type"
        case points = "points"
        case friendUserId = "friend_user_id"
    }
    
    public init(userId: Int64?, pointType: Int?, points: Int64?, friendUserId: Int64?) {
        self.userId = userId
        self.pointType = pointType
        self.points = points
        self.friendUserId = friendUserId
    }
}

public struct PointsType: Codable {
    public let id: Int64
    public let type: Int
    public let message: String
    public let points: Int64
    public let isdeleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case message
        case points
        case isdeleted = "is_deleted"
    }
}
public struct UserPoints: Codable {
    public let points: Int64?

    enum CodingKeys: String, CodingKey {
        case points = "sum"
    }
}
/**
 * Generate a random referral code
 */
public class referalCode {
static let digits = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9"
  ];
  
static let letters = [
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
  ];

    public static func generateRefferalCode() -> String {
        var code = ""
        for _ in 0..<4 {
            code += letters.randomElement() ?? ""
        }
        for _ in 0..<1 {
            code += digits.randomElement() ?? ""
        }
        return code
    }

}
