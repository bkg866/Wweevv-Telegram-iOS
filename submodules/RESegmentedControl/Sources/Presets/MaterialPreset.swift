//
//  MaterialPreset.swift
//  RESegmentedControl
//
//  Created by Sherzod Khashimov on 11/26/19.
//  Copyright © 2019 Sherzod Khashimov. All rights reserved.
//

import Foundation
import UIKit
import WevConfig

public struct MaterialPreset: SegmentedControlPresettable {

    public var segmentStyle: SegmentStylable
    public var segmentItemStyle: SegmentItemStylable
    public var segmentSelectedItemStyle: SegmentSelectedItemStylable

    struct SegmentStyle: SegmentStylable {
        var size: SegmentedControlSize = .maxHeight

        var clipsToBounds: Bool = true

        var borderWidth: CGFloat = 0

        var borderColor: CGColor? = nil

        var cornerRadius: CGFloat = 0

        var spacing: CGFloat = 0

        init() { }
    }

    struct SegmentItemStyle: SegmentItemStylable {
        var textColor: UIColor = .black

        var tintColor: UIColor = .black

        var selectedTextColor: UIColor = .white

        var selectedTintColor: UIColor = .white

        var backgroundColor: UIColor = .white

        var borderWidth: CGFloat = 0

        var borderColor: CGColor?

        var font: UIFont = LJFont.regular(15)

        var selectedFont: UIFont? = LJFont.medium(15)

        var imageHeight: CGFloat = 15

        var imageRenderMode: UIImage.RenderingMode = .alwaysTemplate

        var spacing: CGFloat = 5

        var cornerRadius: CGFloat = 0

        var shadow: ShadowStylable? = nil

        var separator: SeparatorStylable? = nil

        var axis: NSLayoutConstraint.Axis = .horizontal

        init(backgroundColor: UIColor, tintColor: UIColor, normalColor: UIColor) {
            self.backgroundColor = backgroundColor
            self.selectedTextColor = tintColor
            self.selectedTintColor = tintColor
            self.textColor = normalColor
            self.tintColor = normalColor
        }
    }

    struct SegmentSelectedItemStyle: SegmentSelectedItemStylable {

        var backgroundColor: UIColor = .white

        var cornerRadius: CGFloat = 0

        var borderWidth: CGFloat = 0

        var borderColor: CGColor?

        var size: SelectedSegmentSize = .height(5, position: .bottom)

        var offset: CGFloat = 0

        var shadow: ShadowStylable? = nil

        init(tintColor: UIColor) {
            self.backgroundColor = tintColor
        }

    }

    public init(backgroundColor: UIColor, tintColor: UIColor, normalColor: UIColor = .black) {
        self.segmentStyle = SegmentStyle()
        self.segmentItemStyle = SegmentItemStyle(backgroundColor: backgroundColor, tintColor: tintColor, normalColor: normalColor)
        self.segmentSelectedItemStyle = SegmentSelectedItemStyle(tintColor: tintColor)
    }

}
