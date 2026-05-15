//
//  BHFigureReportViewController.swift
//  BlindHelp
//

import UIKit

/// 图文角色主页「举报」表单页。
final class BHFigureReportViewController: BHBaseViewController, UITextViewDelegate {

    private let figureId: Int
    private let targetDisplayName: String

    private let backdropGradientLayer = CAGradientLayer()
    private let ambienceImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "base_liner_bg"))
        v.alpha = 0.44
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    private let scrollView = UIScrollView()
    private let scrollContent = UIView()
    private let headlineLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let reasonShell = UIView()
    private let reasonTextView = UITextView()
    private let placeholderLabel = UILabel()
    private let submitButton = UIButton(type: .system)

    init(figureId: Int, targetDisplayName: String) {
        self.figureId = figureId
        self.targetDisplayName = targetDisplayName
        super.init(nibName: nil, bundle: nil)
        title = "举报"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshReportingCopyFromLatestCatalogProfile()
    }

    override func setupBodyView() {
        baseBackgroundTopImgV.isHidden = true
        baseBackgroundBodyImgV.isHidden = true
        kdNavBar.navTitleLab.text = "举报"

        view.insertSubview(ambienceImageView, at: 0)

        backdropGradientLayer.colors = [
            UIColor.kHexColor(hexString: "#BFE68C").cgColor,
            UIColor.kHexColor(hexString: "#D8EAC7").cgColor,
            UIColor.kHexColor(hexString: "#EEF4E9").cgColor,
            UIColor.kHexColor(hexString: "#F8F9F8").cgColor,
            UIColor.kHexColor(hexString: "#FBFBFB").cgColor,
        ]
        backdropGradientLayer.locations = [0, 0.22, 0.42, 0.72, 1]
        backdropGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        backdropGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(backdropGradientLayer, at: 0)

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.backgroundColor = .clear

        headlineLabel.font = .bh_pingFang(size: kScaleW(21), weight: .bold)
        headlineLabel.textColor = .black
        headlineLabel.text = "请选择举报理由"
        headlineLabel.numberOfLines = 0

        subtitleLabel.font = .bh_pingFang(size: kScaleW(14), weight: .regular)
        subtitleLabel.textColor = .kHexColor(hexString: "#666666")
        subtitleLabel.text = "你正在举报「\(targetDisplayName)」（ID \(figureId)）"
        subtitleLabel.numberOfLines = 0

        reasonShell.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        reasonShell.layer.cornerRadius = kScaleW(14)
        reasonShell.layer.masksToBounds = true

        reasonTextView.delegate = self
        reasonTextView.font = .bh_pingFang(size: kScaleW(15), weight: .regular)
        reasonTextView.textColor = .black
        reasonTextView.backgroundColor = .clear
        reasonTextView.textContainerInset = UIEdgeInsets(
            top: kScaleW(12),
            left: kScaleW(12),
            bottom: kScaleW(12),
            right: kScaleW(12)
        )

        placeholderLabel.text = "请描述具体情况，我们会尽快处理…"
        placeholderLabel.font = reasonTextView.font
        placeholderLabel.textColor = .kHexColor(hexString: "#AAAAAA")
        placeholderLabel.numberOfLines = 0

        submitButton.layer.cornerRadius = kScaleW(23)
        submitButton.layer.masksToBounds = true
        submitButton.backgroundColor = .black
        submitButton.setTitle("提交举报", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = .bh_pingFang(size: kScaleW(16), weight: .medium)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        view.addSubview(scrollView)
        view.bringSubviewToFront(kdNavBar)
        scrollView.addSubview(scrollContent)
        scrollContent.addSubview(headlineLabel)
        scrollContent.addSubview(subtitleLabel)
        scrollContent.addSubview(reasonShell)
        reasonShell.addSubview(reasonTextView)
        reasonShell.addSubview(placeholderLabel)
        scrollContent.addSubview(submitButton)
    }

    override func setupSubConstraints() {
        ambienceImageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollContent.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        reasonShell.translatesAutoresizingMaskIntoConstraints = false
        reasonTextView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            ambienceImageView.topAnchor.constraint(equalTo: view.topAnchor),
            ambienceImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ambienceImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ambienceImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: kdNavBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            scrollContent.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            scrollContent.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scrollContent.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollContent.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            scrollContent.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            headlineLabel.topAnchor.constraint(equalTo: scrollContent.topAnchor, constant: kScaleW(20)),
            headlineLabel.leadingAnchor.constraint(equalTo: scrollContent.leadingAnchor, constant: kScaleW(18)),
            headlineLabel.trailingAnchor.constraint(equalTo: scrollContent.trailingAnchor, constant: -kScaleW(18)),

            subtitleLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: kScaleW(10)),
            subtitleLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),

            reasonShell.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: kScaleW(18)),
            reasonShell.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            reasonShell.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            reasonShell.heightAnchor.constraint(equalToConstant: kScaleW(176)),

            reasonTextView.topAnchor.constraint(equalTo: reasonShell.topAnchor),
            reasonTextView.leadingAnchor.constraint(equalTo: reasonShell.leadingAnchor),
            reasonTextView.trailingAnchor.constraint(equalTo: reasonShell.trailingAnchor),
            reasonTextView.bottomAnchor.constraint(equalTo: reasonShell.bottomAnchor),

            placeholderLabel.topAnchor.constraint(equalTo: reasonShell.topAnchor, constant: kScaleW(20)),
            placeholderLabel.leadingAnchor.constraint(equalTo: reasonShell.leadingAnchor, constant: kScaleW(17)),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: reasonShell.trailingAnchor, constant: -kScaleW(12)),

            submitButton.topAnchor.constraint(equalTo: reasonShell.bottomAnchor, constant: kScaleW(28)),
            submitButton.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            submitButton.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            submitButton.heightAnchor.constraint(equalToConstant: kScaleW(48)),
            submitButton.bottomAnchor.constraint(equalTo: scrollContent.bottomAnchor, constant: -kScaleW(32)),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backdropGradientLayer.frame = view.bounds
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !(textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 每次展示时同步角色资料昵称，拉黑/屏蔽后仍保留 ID，名称以本地目录为准刷新。
    private func refreshReportingCopyFromLatestCatalogProfile() {
        let name = BHFigureResourceCatalog.profile(figureId: figureId)?.nickname ?? targetDisplayName
        subtitleLabel.text = "你正在举报「\(name)」（ID \(figureId)）"
    }

    @objc private func submitTapped() {
        let trimmed = reasonTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            view.cd_showDefaultToast("请填写举报内容")
            return
        }
        view.cd_showDefaultToast("举报已提交，感谢反馈")
        navigationController?.popViewController(animated: true)
    }
}
