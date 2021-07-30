//
//  SearchRecommendAccountsCollectionViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/1.
//

import Combine
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import MetaTextKit
import MastodonMeta

protocol SearchRecommendAccountsCollectionViewCellDelegate: NSObject {
    func followButtonDidPressed(clickedUser: MastodonUser)
    
    func configFollowButton(with mastodonUser: MastodonUser, followButton: HighlightDimmableButton)
}

class SearchRecommendAccountsCollectionViewCell: UICollectionViewCell {
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: SearchRecommendAccountsCollectionViewCellDelegate?
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8.4
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = Asset.Colors.Border.searchCard.color.cgColor
        return imageView
    }()
    
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    
    let displayNameLabel = MetaLabel(style: .recommendAccountName)
    
    let acctLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let followButton: HighlightDimmableButton = {
        let button = HighlightDimmableButton(type: .custom)
        button.setInsets(forContentPadding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16), imageTitlePadding: 0)
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.Scene.Search.Recommend.Accounts.follow, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 12
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        headerImageView.af.cancelImageRequest()
        avatarImageView.af.cancelImageRequest()
        visualEffectView.removeFromSuperview()
        disposeBag.removeAll()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override var isHighlighted: Bool {
        didSet {
            contentView.alpha = isHighlighted ? 0.8 : 1.0
        }
    }

}

extension SearchRecommendAccountsCollectionViewCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headerImageView.layer.borderColor = Asset.Colors.Border.searchCard.color.cgColor
        applyShadow(color: Asset.Colors.Shadow.searchCard.color, alpha: 0.1, x: 0, y: 3, blur: 12, spread: 0)
    }

    private func configure() {
        headerImageView.backgroundColor = Asset.Colors.brandBlue.color
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous
        clipsToBounds = false
        applyShadow(color: Asset.Colors.Shadow.searchCard.color, alpha: 0.1, x: 0, y: 3, blur: 12, spread: 0)
        
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerImageView)
        NSLayoutConstraint.activate([
            headerImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.distribution = .fill
        containerStackView.alignment = .center
        containerStackView.spacing = 6
        containerStackView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 88),
            avatarImageView.heightAnchor.constraint(equalToConstant: 88)
        ])
        containerStackView.addArrangedSubview(avatarImageView)
        containerStackView.setCustomSpacing(20, after: avatarImageView)
        displayNameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(displayNameLabel)
        containerStackView.setCustomSpacing(0, after: displayNameLabel)
        
        acctLabel.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(acctLabel)
        containerStackView.setCustomSpacing(7, after: acctLabel)
        
        followButton.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(followButton)
        NSLayoutConstraint.activate([
            followButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 76),
            followButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        ])
        containerStackView.addArrangedSubview(followButton)
    }
    
    func config(with mastodonUser: MastodonUser) {
        do {
            let mastodonContent = MastodonContent(content: mastodonUser.displayNameWithFallback, emojis: mastodonUser.emojiMeta)
            let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
            displayNameLabel.configure(content: metaContent)
        } catch {
            let metaContent = PlaintextMetaContent(string: mastodonUser.displayNameWithFallback)
            displayNameLabel.configure(content: metaContent)
        }
        acctLabel.text = "@" + mastodonUser.acct
        avatarImageView.af.setImage(
            withURL: URL(string: mastodonUser.avatar)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        )
        headerImageView.af.setImage(
            withURL: URL(string: mastodonUser.header)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        ) { [weak self] _ in
            guard let self = self else { return }
            self.headerImageView.addSubview(self.visualEffectView)
            self.visualEffectView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.visualEffectView.topAnchor.constraint(equalTo: self.headerImageView.topAnchor),
                self.visualEffectView.leadingAnchor.constraint(equalTo: self.headerImageView.leadingAnchor),
                self.visualEffectView.trailingAnchor.constraint(equalTo: self.headerImageView.trailingAnchor),
                self.visualEffectView.bottomAnchor.constraint(equalTo: self.headerImageView.bottomAnchor)
            ])
        }
        delegate?.configFollowButton(with: mastodonUser, followButton: followButton)
        followButton.publisher(for: .touchUpInside)
            .sink { [weak self] _ in
                self?.followButtonDidPressed(mastodonUser: mastodonUser)
            }
            .store(in: &disposeBag)
    }
    
    func followButtonDidPressed(mastodonUser: MastodonUser) {
        delegate?.followButtonDidPressed(clickedUser: mastodonUser)
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SearchRecommendAccountsCollectionViewCell_Previews: PreviewProvider {
    static var controls: some View {
        Group {
            UIViewPreview {
                let cell = SearchRecommendAccountsCollectionViewCell()
                cell.avatarImageView.backgroundColor = .white
                cell.headerImageView.backgroundColor = .red
                cell.displayNameLabel.text = "sunxiaojian"
                cell.acctLabel.text = "sunxiaojian@mastodon.online"
                return cell
            }
            .previewLayout(.fixed(width: 257, height: 202))
        }
    }
    
    static var previews: some View {
        Group {
            controls.colorScheme(.light)
            controls.colorScheme(.dark)
        }
        .background(Color.gray)
    }
}

#endif