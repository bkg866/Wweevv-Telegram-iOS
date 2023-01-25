//
//  BackgroundCollectionViewCell.swift
//  RESegmentedControl
//
//  Created by Sherzod Khashimov on 11/26/19.
//  Copyright © 2019 Sherzod Khashimov. All rights reserved.
//

import UIKit

class BackgroundCollectionViewCell: UICollectionViewCell {
    
    var bgView = UIView(frame: .zero)
    var separatorView = UIView(frame: .zero)

    var separatorViewWidthLC: NSLayoutConstraint?
    var separatorViewLeadingLC: NSLayoutConstraint?
    var separatorViewTopLC: NSLayoutConstraint?
    var separatorViewBottomLC: NSLayoutConstraint?

    private var style: SegmentItemStylable? {
        didSet {
            configUI()
        }
    }

    private var isSeparatorVisible: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func initView() {
        self.addSubview(bgView)
        bgView.snp.makeConstraints({ make in
            make.top.equalToSuperview()
        })
        
        self.addSubview(separatorView)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorViewWidthLC = separatorView.widthAnchor.constraint(equalToConstant: 1)
        separatorViewLeadingLC = separatorView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0.5)
        separatorViewTopLC = separatorView.topAnchor.constraint(equalTo: self.topAnchor)
        separatorViewBottomLC = separatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        
        separatorViewWidthLC?.isActive = true
        separatorViewLeadingLC?.isActive = true
        separatorViewTopLC?.isActive = true
        separatorViewBottomLC?.isActive = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        separatorView.isHidden = true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    private func configUI() {
        guard let style = style else { return }

        bgView.backgroundColor = style.backgroundColor
        bgView.layer.cornerRadius = style.cornerRadius
        bgView.layer.borderColor = style.borderColor
        bgView.layer.borderWidth = style.borderWidth
        self.contentView.layer.masksToBounds = true
        self.applyShadow(with: style.shadow)

        if let separatorStyle = style.separator {
            separatorViewWidthLC?.constant = separatorStyle.width
            separatorViewTopLC?.constant = separatorStyle.offset
            separatorViewBottomLC?.constant = separatorStyle.offset
            separatorViewLeadingLC?.constant = -(separatorStyle.width / 2)
            separatorView.backgroundColor = separatorStyle.color
        }

        self.separatorView.isHidden = !isSeparatorVisible || style.separator == nil
    }
}

extension BackgroundCollectionViewCell {
    func configure(style: SegmentItemStylable, isSeparatorVisible: Bool) {
        self.isSeparatorVisible = isSeparatorVisible
        self.style = style
    }
}
