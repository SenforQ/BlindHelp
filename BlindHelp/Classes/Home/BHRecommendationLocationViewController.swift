//
//  BHRecommendationLocationViewController.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/14.
//

import UIKit

/// 首页「热门地点」对应的目的地攻略详情。
final class BHRecommendationLocationViewController: BHBaseViewController {

    private let spot: BHPopularChinaSpot

    private let navIssuesButton = UIButton(type: .system)

    private let scrollView = UIScrollView()

    private let contentStack = UIStackView()

    private let heroImageView = UIImageView()

    init(spot: BHPopularChinaSpot) {
        self.spot = spot
        super.init(nibName: nil, bundle: nil)
        title = spot.attractionTitle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        kdNavBar.navTitleLab.text = spot.attractionTitle
        configureNavIssuesAffairButtonIfNeeded()
        buildContentStack()
        scrollView.contentInsetAdjustmentBehavior = .never
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutNavIssuesButton()
    }

    override func setupBodyView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
    }

    override func setupSubConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: kNavBarFullHeight),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    private func buildContentStack() {
        contentStack.axis = .vertical
        contentStack.spacing = kScaleW(14)
        contentStack.layoutMargins = UIEdgeInsets(top: kScaleW(14), left: kScaleW(14), bottom: kScaleW(24), right: kScaleW(14))
        contentStack.isLayoutMarginsRelativeArrangement = true

        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.layer.cornerRadius = kScaleW(14)
        heroImageView.layer.masksToBounds = true
        heroImageView.backgroundColor = .kHexColor(hexString: "#E8EAED")
        heroImageView.image = UIImage(named: spot.coverImageAssetName) ?? UIImage(named: "home_top_image")
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(heroImageView)
        NSLayoutConstraint.activate([
            heroImageView.heightAnchor.constraint(equalTo: heroImageView.widthAnchor, multiplier: 240.0 / 375.0),
        ])

        let headlineLabel = UILabel()
        headlineLabel.numberOfLines = 0
        headlineLabel.font = .bh_pingFang(size: kScaleW(21), weight: .bold)
        headlineLabel.textColor = .black
        headlineLabel.text = spot.attractionTitle
        contentStack.addArrangedSubview(headlineLabel)

        contentStack.addArrangedSubview(metadataRow())

        let briefWrap = tintedCardWrap()
        let briefHeading = UILabel()
        briefHeading.font = .bh_pingFang(size: kScaleW(14), weight: .medium)
        briefHeading.textColor = .kHexColor(hexString: "#444444")
        briefHeading.text = "一句话摘要"
        let briefBody = UILabel()
        briefBody.numberOfLines = 0
        briefBody.font = .bh_pingFang(size: kScaleW(14), weight: .regular)
        briefBody.textColor = .black
        briefBody.text = spot.strategyBrief
        briefWrap.addSubview(briefHeading)
        briefWrap.addSubview(briefBody)
        briefHeading.translatesAutoresizingMaskIntoConstraints = false
        briefBody.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            briefHeading.topAnchor.constraint(equalTo: briefWrap.topAnchor, constant: kScaleW(12)),
            briefHeading.leadingAnchor.constraint(equalTo: briefWrap.leadingAnchor, constant: kScaleW(14)),
            briefHeading.trailingAnchor.constraint(equalTo: briefWrap.trailingAnchor, constant: -kScaleW(14)),
            briefBody.topAnchor.constraint(equalTo: briefHeading.bottomAnchor, constant: kScaleW(8)),
            briefBody.leadingAnchor.constraint(equalTo: briefWrap.leadingAnchor, constant: kScaleW(14)),
            briefBody.trailingAnchor.constraint(equalTo: briefWrap.trailingAnchor, constant: -kScaleW(14)),
            briefBody.bottomAnchor.constraint(equalTo: briefWrap.bottomAnchor, constant: -kScaleW(12)),
        ])
        contentStack.addArrangedSubview(briefWrap)

        let sectionHeading = UILabel()
        sectionHeading.font = .bh_pingFang(size: kScaleW(16), weight: .bold)
        sectionHeading.textColor = .black
        sectionHeading.text = "详尽攻略"
        contentStack.addArrangedSubview(sectionHeading)

        let sections = BHPopularChinaSpotTravelGuide.detailSections(for: spot)
        for block in sections {
            let card = whiteCardWrap()
            let h = UILabel()
            h.numberOfLines = 0
            h.font = .bh_pingFang(size: kScaleW(15), weight: .bold)
            h.textColor = .black
            h.text = block.heading

            let b = UILabel()
            b.numberOfLines = 0
            b.font = .bh_pingFang(size: kScaleW(14), weight: .regular)
            b.textColor = .kHexColor(hexString: "#333333")
            b.text = block.body

            card.addSubview(h)
            card.addSubview(b)
            h.translatesAutoresizingMaskIntoConstraints = false
            b.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                h.topAnchor.constraint(equalTo: card.topAnchor, constant: kScaleW(14)),
                h.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: kScaleW(14)),
                h.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -kScaleW(14)),
                b.topAnchor.constraint(equalTo: h.bottomAnchor, constant: kScaleW(10)),
                b.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: kScaleW(14)),
                b.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -kScaleW(14)),
                b.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -kScaleW(14)),
            ])

            contentStack.addArrangedSubview(card)
        }
    }

    private func metadataRow() -> UIView {
        let row = UIView()
        row.backgroundColor = .clear

        let loc = UILabel()
        loc.numberOfLines = 0
        loc.font = .bh_pingFang(size: kScaleW(13), weight: .regular)
        loc.textColor = .kHexColor(hexString: "#666666")
        loc.text = spot.locationLine

        let rating = UILabel()
        rating.font = .bh_pingFang(size: kScaleW(12), weight: .medium)
        rating.textColor = .black
        rating.backgroundColor = .kHexColor(hexString: "#A6F500")
        rating.layer.cornerRadius = kScaleW(4)
        rating.layer.masksToBounds = true
        rating.textAlignment = .center
        rating.text = " 评分 \(spot.ratingDisplay) "

        let certified = UILabel()
        certified.font = .bh_pingFang(size: kScaleW(11), weight: .medium)
        certified.textColor = .kHexColor(hexString: "#FF8A00")
        certified.layer.borderColor = UIColor.kHexColor(hexString: "#FF8A00").cgColor
        certified.layer.borderWidth = 1
        certified.layer.cornerRadius = kScaleW(4)
        certified.layer.masksToBounds = true
        certified.textAlignment = .center
        certified.text = " 已认证 "

        let topLine = UIStackView(arrangedSubviews: [certified, rating, UIView()])
        topLine.axis = .horizontal
        topLine.spacing = kScaleW(8)
        topLine.alignment = .center
        certified.setContentHuggingPriority(.required, for: .horizontal)
        rating.setContentHuggingPriority(.required, for: .horizontal)

        let col = UIStackView(arrangedSubviews: [topLine, loc])
        col.axis = .vertical
        col.spacing = kScaleW(8)
        row.addSubview(col)
        col.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            col.topAnchor.constraint(equalTo: row.topAnchor),
            col.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            col.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            col.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])

        return row
    }

    private func tintedCardWrap() -> UIView {
        let v = UIView()
        v.backgroundColor = .kHexColor(hexString: "#F0F4E8")
        v.layer.cornerRadius = kScaleW(12)
        v.layer.masksToBounds = true
        return v
    }

    private func whiteCardWrap() -> UIView {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = kScaleW(12)
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: kScaleW(2))
        v.layer.shadowRadius = kScaleW(6)
        v.layer.shadowOpacity = 1
        return v
    }

    private func configureNavIssuesAffairButtonIfNeeded() {
        guard spot.linkedFigureId != nil else {
            navIssuesButton.isHidden = true
            return
        }
        let sym = UIImage.SymbolConfiguration(pointSize: kScaleW(22), weight: .semibold)
        navIssuesButton.setImage(
            UIImage(systemName: "exclamationmark.circle.fill", withConfiguration: sym),
            for: .normal
        )
        navIssuesButton.tintColor = UIColor.systemRed
        navIssuesButton.adjustsImageWhenHighlighted = false
        navIssuesButton.accessibilityLabel = "举报或拉黑屏蔽"
        navIssuesButton.addTarget(self, action: #selector(navIssuesTapped), for: .touchUpInside)
        navIssuesButton.isHidden = false
        kdNavBar.navigationView.addSubview(navIssuesButton)
        kdNavBar.navigationView.bringSubviewToFront(navIssuesButton)
    }

    private func layoutNavIssuesButton() {
        guard !navIssuesButton.isHidden, navIssuesButton.superview != nil else { return }
        let nv = kdNavBar.navigationView
        let btnSide = kNavBarHeight
        let trailing = kScaleW(13)
        navIssuesButton.frame = CGRect(
            x: max(0, nv.bounds.width - trailing - btnSide),
            y: max(0, (nv.bounds.height - btnSide) / 2),
            width: btnSide,
            height: btnSide
        )
    }

    @objc private func navIssuesTapped() {
        guard let figureId = spot.linkedFigureId else { return }
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "举报", style: .default) { [weak self] _ in
            self?.openFigureReportFromLocationDetail(figureId: figureId)
        })
        sheet.addAction(UIAlertAction(title: "拉黑", style: .destructive) { [weak self] _ in
            self?.applyLocationDetailBlockOrShield(block: true, figureId: figureId)
        })
        sheet.addAction(UIAlertAction(title: "屏蔽", style: .destructive) { [weak self] _ in
            self?.applyLocationDetailBlockOrShield(block: false, figureId: figureId)
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = navIssuesButton
            pop.sourceRect = navIssuesButton.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(sheet, animated: true)
    }

    private func openFigureReportFromLocationDetail(figureId: Int) {
        guard let nav = navigationController else {
            view.cd_showDefaultToast("无法打开举报页")
            return
        }
        let name =
            BHFigureResourceCatalog.profile(figureId: figureId)?.nickname ?? spot.attractionTitle
        let report = BHFigureReportViewController(figureId: figureId, targetDisplayName: name)
        nav.pushViewController(report, animated: true)
    }

    private func applyLocationDetailBlockOrShield(block: Bool, figureId: Int) {
        if block {
            BHFigureBlockShieldStore.block(figureId: figureId)
        } else {
            BHFigureBlockShieldStore.shield(figureId: figureId)
        }
        NotificationCenter.default.post(name: .bhHomeFigureBlockedOrShieldedListDidChange, object: nil)
        view.cd_showDefaultToast(block ? "已拉黑" : "已屏蔽")
        navigationController?.popToRootViewController(animated: true)
    }
}
