//
//  BHMineUserTermsViewController.swift
//  BlindHelp
//

import UIKit

final class BHMineUserTermsViewController: BHMineLegalWebHostingViewController {

    init() {
        super.init(pageNavTitle: "用户协议", content: kUserAgreementHtmlStr)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
