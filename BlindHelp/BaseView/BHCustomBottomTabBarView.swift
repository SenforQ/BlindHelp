//
//  BHCustomBottomTabBarView.swift
//  BlindHelp
//

import UIKit

/// 自定义底部主导航条（与系统 `UITabBar` 并存：中间为拍照，其余四项对应 `TabBarController` 下标 0～3）。
final class BHCustomBottomTabBarView: UIView {

    enum MainTab: Int, CaseIterable {
        case home = 0
        case square = 1
        case message = 2
        case mine = 3

        var title: String {
            switch self {
            case .home: return "首页"
            case .square: return "广场"
            case .message: return "消息"
            case .mine: return "我的"
            }
        }

        fileprivate var iconNames: (selected: String, normal: String) {
            switch self {
            case .home: return ("tab_home_s", "tab_home_n")
            case .square: return ("tab_square_s", "tab_square_n")
            case .message: return ("tab_message_s", "tab_message_n")
            case .mine: return ("tab_mine_s", "tab_mine_n")
            }
        }
    }

    private weak var hostViewController: UIViewController?
    private var selectedMainTab: MainTab

    private let cardView = UIView()
    private var tabButtons: [UIButton] = []
    private var tabIconViews: [UIImageView] = []
    private var tabLabels: [UILabel] = []

    private let photoButton = UIButton(type: .custom)
    private let photoImageView = UIImageView(image: UIImage(named: "tab_photo_s"))

    /// 中间拍照按钮回调；未设置时不响应业务（可自行在控制器里赋值）。
    var onPhotoButtonTapped: (() -> Void)?

    init(host: UIViewController, selectedMainTab: MainTab) {
        self.hostViewController = host
        self.selectedMainTab = selectedMainTab
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        buildCardChrome()
        buildTabItems()
        buildPhotoButton()
        reflectSelection()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildCardChrome() {
        cardView.backgroundColor = .kHexColor(hexString: "#FFFFFF")
        cardView.layer.masksToBounds = false
        cardView.layer.shadowColor = UIColor.kHexColor(hexString: "#000000", alpha: 0.1).cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOpacity = 1
        addSubview(cardView)
    }

    private func buildTabItems() {
        for tab in MainTab.allCases {
            let button = UIButton(type: .custom)
            button.backgroundColor = .clear
            let icon = UIImageView()
            icon.contentMode = .scaleAspectFill
            let label = UILabel()
            label.text = tab.title
            label.font = .systemFont(ofSize: kScaleW(10))
            label.textAlignment = .center
            button.addSubview(icon)
            button.addSubview(label)
            tabButtons.append(button)
            tabIconViews.append(icon)
            tabLabels.append(label)
            cardView.addSubview(button)
            let current = tab
            button.bh_setTapAction { [weak self] _ in
                self?.handleTab(current)
            }
        }
    }

    private func buildPhotoButton() {
        photoImageView.contentMode = .scaleAspectFill
        photoButton.addSubview(photoImageView)
        cardView.addSubview(photoButton)
        photoButton.bh_setTapAction { [weak self] _ in
            self?.handlePhoto()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let width = bounds.width
        let cardHeight = kScaleW(54)
        let cardY = kScaleW(7)
        cardView.frame = CGRect(x: 0, y: cardY, width: width, height: cardHeight)

        let cornerRadius = cardHeight / 2
        cardView.layer.cornerRadius = cornerRadius
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: cornerRadius
        ).cgPath

        let photoWidth = kScaleW(54)
        let gap = kScaleW(5)
        let segmentWidth = (width - photoWidth - gap * 2) / 4
        guard segmentWidth > 1 else { return }

        var x: CGFloat = 0
        for i in 0..<2 {
            placeTab(index: i, originX: &x, segmentWidth: segmentWidth, cardHeight: cardHeight)
        }
        x += gap
        photoButton.frame = CGRect(x: x, y: -kScaleW(7), width: photoWidth, height: photoWidth)
        photoImageView.frame = photoButton.bounds
        x += photoWidth + gap
        for i in 2..<4 {
            placeTab(index: i, originX: &x, segmentWidth: segmentWidth, cardHeight: cardHeight)
        }
    }

    private func placeTab(index: Int, originX: inout CGFloat, segmentWidth: CGFloat, cardHeight: CGFloat) {
        let frame = CGRect(x: originX, y: 0, width: segmentWidth, height: cardHeight)
        tabButtons[index].frame = frame
        let inset = CGRect(x: 0, y: 0, width: segmentWidth, height: cardHeight)
        layoutTabContents(index: index, in: inset)
        originX += segmentWidth
    }

    private func layoutTabContents(index: Int, in buttonBounds: CGRect) {
        let icon = tabIconViews[index]
        let label = tabLabels[index]
        let iconSize = kScaleW(24)
        icon.frame = CGRect(
            x: (buttonBounds.width - iconSize) / 2,
            y: kScaleW(7),
            width: iconSize,
            height: iconSize
        )
        let labelHeight = kScaleW(14)
        label.frame = CGRect(
            x: 0,
            y: buttonBounds.height - kScaleW(7) - labelHeight,
            width: buttonBounds.width,
            height: labelHeight
        )
    }

    private func reflectSelection() {
        for (idx, tab) in MainTab.allCases.enumerated() {
            let selected = tab == selectedMainTab
            let names = tab.iconNames
            tabIconViews[idx].image = UIImage(named: selected ? names.selected : names.normal)
            tabLabels[idx].textColor = selected
                ? .kHexColor(hexString: "#000000")
                : .kHexColor(hexString: "#777777")
        }
    }

    private func handleTab(_ tab: MainTab) {
        guard let host = hostViewController,
              let tabBar = host.tabBarController else { return }
        if tab.rawValue == tabBar.selectedIndex {
            host.navigationController?.popToRootViewController(animated: true)
            return
        }
        tabBar.selectedIndex = tab.rawValue
    }

    private func handlePhoto() {
        onPhotoButtonTapped?()
    }

    /// 添加到控制器底部安全区之上，应在 `viewDidLayoutSubviews` 中与 `view.bounds` 同步更新 frame。
    func layoutFrame(in containerBounds: CGRect) {
        let barHeight = kScaleW(61)
        let y = containerBounds.height - kBottomSafeHeight - kScaleW(12) - barHeight
        frame = CGRect(
            x: kScaleW(14),
            y: y,
            width: containerBounds.width - kScaleW(28),
            height: barHeight
        )
    }
}

extension UIViewController {

    /// 将自定义底栏置于视图最前，避免被后续添加的子视图遮挡。
    func bh_bringCustomTabBarToFront(_ bar: BHCustomBottomTabBarView) {
        view.bringSubviewToFront(bar)
    }
}
