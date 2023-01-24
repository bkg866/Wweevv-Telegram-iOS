//
//  SegmentModel.swift
//  RESegmentedControl
//
//  Created by Sherzod Khashimov on 7/10/18.
//  Copyright © 2018 Sherzod Khashimov. All rights reserved.
//

import Foundation

/// Segment item model
public struct SegmentModel: Codable {

    /// Segmente item title
    public var title: String?

    /// Image name located in asset catalog
    public var imageName: String?
    public var searchStatus: String?

    /// Initializes with title only
    /// - Parameter title: Segment item title
    public init(title: String?) {
        self.title = title
    }

    /// Initializes with title and image
    /// - Parameters:
    ///   - title: Segment item title
    ///   - imageName: Image name located in asset catalog
    ///   - bundle: Bundle that will be used to get image by name
    public init(title: String? = nil, imageName: String? = nil, searchStatus: String) {
        self.title = title
        self.imageName = imageName
        self.searchStatus = searchStatus
    }
    
    /// Whether or not image is set
    public var isImageAvailable: Bool {
        if imageName != nil && imageName != "" {
            return true
        }
        return false
    }
}
