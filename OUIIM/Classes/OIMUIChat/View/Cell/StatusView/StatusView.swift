import ChatLayout
import Foundation
import UIKit

final class StatusView: UIView, StaticViewFactory {

    private lazy var imageView = UIImageView(frame: bounds)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: 15)
        widthConstraint.priority = UILayoutPriority(rawValue: 999)
        widthConstraint.isActive = true
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: 15)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true

        imageView.contentMode = .center
    }

    func setup(with status: MessageStatus) {
        switch status {
        case .sent(let attachInfo):
            // 根据已读状态显示不同图标
            switch attachInfo.readedStatus {
            case .signalReaded(let isRead):
                if isRead {
                    imageView.image = UIImage(named: "read_status")
                    imageView.tintColor = .systemBlue
                } else {
                    imageView.image = UIImage(named: "sent_status")
                    imageView.tintColor = .lightGray
                }
            case .groupReaded(let isRead, _):
                if isRead {
                    imageView.image = UIImage(named: "read_status")
                    imageView.tintColor = .systemBlue
                } else {
                    imageView.image = UIImage(named: "sent_status")
                    imageView.tintColor = .lightGray
                }
            }
        case .received:
            imageView.image = UIImage(named: "sent_status")
            imageView.tintColor = .systemBlue
        case .sending:
            imageView.image = UIImage(named: "sent_status")
            imageView.tintColor = .orange
        case .sentFailure:
            break
        }
    }

}
