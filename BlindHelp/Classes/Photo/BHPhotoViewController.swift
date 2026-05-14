//
//  BHPhotoViewController.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// 拍照/相册相关页面基类占位；当前未挂入 `BHBaseTabBarController`，需时可通过 push 或单独 Tab 接入。
final class BHPhotoViewController: BHBaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
}
