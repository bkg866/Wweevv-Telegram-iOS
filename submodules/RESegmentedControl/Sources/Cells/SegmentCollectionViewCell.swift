//
//  SegmentCollectionViewCell.swift
//  RESegmentedControl
//
//  Created by Sherzod Khashimov on 7/10/18.
//  Copyright © 2018 Sherzod Khashimov. All rights reserved.
//

import UIKit

class SegmentCollectionViewCell: UICollectionViewCell {

    var containerView: UIView = UIView(frame: .zero)
    var stackView: UIStackView = UIStackView(frame: .zero)
    var imageView: UIImageView = UIImageView(frame: .zero)
    var textLabel: UILabel = UILabel(frame: .zero)
    var labelView: UIView = UIView(frame: .zero)

    private var item: SegmentModel? {
        didSet {
            textLabel.text = item?.title ?? ""
            textLabel.isHidden = item?.title == nil

            imageView.isHidden = !(item?.isImageAvailable ?? false)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func initView() {
        
        self.contentView.addSubview(containerView)
        containerView.addSubview(stackView)
        stackView.addArrangedSubview(imageView)
        labelView.addSubview(textLabel)
        stackView.addArrangedSubview(labelView)
        
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 6
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().offset(3)
        }
        
        stackView.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.top.bottom.greaterThanOrEqualToSuperview().offset(5)
        }
        
        textLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(6)
            make.top.bottom.trailing.equalToSuperview()
        }
        
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.height.width.equalTo(20)
        }
    }

    func loadImageIfNeeded() {
        if let imageName = item?.imageName {
            if let image = UIImage(named: imageName, in: Bundle.main, compatibleWith: nil) {
                imageView.image = image
            }
        }
    }

    private var style: SegmentItemStylable? {
        didSet {
            configUI()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        item = nil
        imageView.image = nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        item = nil
    }

    override var isSelected: Bool {
        didSet {
            if isSelected != oldValue {
                self.setNeedsLayout()
                let duration = 0.5
                if #available(iOS 10.0, *) {
                    let layoutAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1.3) {
                        self.layoutIfNeeded()
                    }
                    layoutAnimator.startAnimation()
                } else {
                    // Fallback on earlier versions
                    UIView.animate(withDuration: duration) {
                        self.layoutIfNeeded()
                    }
                }
            }
        }
    }

    private func configUI() {
        guard let style = style else { return }
        stackView.spacing = style.spacing
        stackView.axis = style.axis
        
        stackView.setCustomSpacing(style.spacing, after: imageView)
        stackView.spacing = style.spacing

        if let shadowStyle = style.shadow {
            self.applyShadow(with: shadowStyle)
        }
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let style = style else { return }
        if isSelected {
            self.textLabel.textColor = style.selectedTextColor
            self.textLabel.font = style.selectedFont ?? style.font
            self.imageView.tintColor = style.selectedTintColor
        } else {
            self.textLabel.textColor = style.textColor
            self.textLabel.font = style.font
            self.imageView.tintColor = style.tintColor
        }
    }

}

extension SegmentCollectionViewCell {
    func configure(_ item: SegmentModel, style: SegmentItemStylable) {
        self.style = style
        self.item = item
    }
}
