//
//  BHMinePrivateViewController.swift
//  BlindHelp
//

import UIKit
import WebKit

class BHMineLegalWebHostingViewController: BHBaseViewController, WKNavigationDelegate {

    private let pageNavTitle: String
    private let contentToLoad: String
    private let webView: WKWebView

    init(pageNavTitle: String, content htmlOrRemoteURLString: String) {
        self.pageNavTitle = pageNavTitle
        self.contentToLoad = htmlOrRemoteURLString
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        self.webView = WKWebView(frame: .zero, configuration: cfg)
        super.init(nibName: nil, bundle: nil)
        title = pageNavTitle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        kdNavBar.navTitleLab.text = pageNavTitle
        webView.navigationDelegate = self
        webView.isOpaque = false
        applyContentPayload()
    }

    override func setupBodyView() {
        view.addSubview(webView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let y = kNavBarFullHeight
        webView.frame = CGRect(
            x: 0,
            y: y,
            width: view.bounds.width,
            height: view.bounds.height - y
        )
    }

    private func applyContentPayload() {
        let s = contentToLoad.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else {
            view.cd_showDefaultToast("暂无内容")
            return
        }
        if let url = URL(string: s),
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https"
        {
            webView.load(URLRequest(url: url))
            return
        }
        let baseURL = Bundle.main.bundleURL
        webView.loadHTMLString(s, baseURL: baseURL)
    }
}

final class BHMinePrivateViewController: BHMineLegalWebHostingViewController {

    init() {
        super.init(pageNavTitle: "隐私政策", content: kPrivatePolicyHtmlStr)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
