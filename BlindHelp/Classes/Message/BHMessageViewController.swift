//
//  BHMessageViewController.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// Tab「消息」根页面。
final class BHMessageViewController: BHBaseViewController {

    private lazy var bottomTabBar: BHCustomBottomTabBarView = {
        let bar = BHCustomBottomTabBarView(host: self, selectedMainTab: .message)
        bar.onPhotoButtonTapped = {
            print("点击拍照")
        }
        return bar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .kHexColor(hexString: "#F7F7F7")
        view.addSubview(bottomTabBar)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomTabBar.layoutFrame(in: view.bounds)
        bh_bringCustomTabBarToFront(bottomTabBar)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}
