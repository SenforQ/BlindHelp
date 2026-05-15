//
//  BHHomePageViewController.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// Tab「首页」根页面。
final class BHHomePageViewController: BHBaseViewController {

    private lazy var topImageView: UIImageView = {
        let tempImageView = UIImageView(image: UIImage(named: "home_top_image"))
        tempImageView.contentMode = .scaleAspectFill
        tempImageView.frame = CGRectMake(0, 0, kScreenWidth, kScaleW(211))
        return tempImageView
    }()

    private lazy var leftNavTitleLab: UILabel = {
        let lab = UILabel(
            frame: CGRect(
                x: kScaleW(14),
                y: kStatusBarHeight + kScaleW(10),
                width: kScaleW(100),
                height: kScaleW(25)
            )
        )
        lab.text = "首页"
        lab.textColor = .kHexColor(hexString: "#FFFFFF")
        lab.font = .bh_pingFang(size: 18, weight: .medium)
        lab.textAlignment = .left
        return lab
    }()

    private let homeSegmentTitleBar = UIView()

    private let homeSegmentSliderView: UIView = {
        let v = UIView()
        v.backgroundColor = .kHexColor(hexString: "#A6F500")
        v.layer.cornerRadius = kScaleW(3)
        v.layer.masksToBounds = true
        return v
    }()

    private var homeSegmentButtons: [UIButton] = []

    private var selectedHomeSegmentIndex = 0

    private weak var homeFeedPagingScrollView: UIScrollView?

    private enum SegmentEmbeddedTag {
        static let videoCollection = 5001
        static let placesTable = 5002
    }

    private static var segmentListTailInsetHeight: CGFloat { kBottomSafeHeight + 72 }

    private static let videoCollectionSectionFooterReuseId = "BHHomeTravelVideoSectionFooter"

    private static let placesSectionTitleHeaderReuseId = "BHHomePlacesSectionTitleHeader"
    private static let placesSectionTitleLabelTag = 9_001

    private static var placesRecommendedSectionTitleTopInset: CGFloat { kScaleW(14) }
    private static var placesRecommendedSectionTitleHeight: CGFloat { kScaleW(22) }
    private static var placesRecommendedSectionTitleBottomInset: CGFloat { kScaleW(8) }

    private static var placesRecommendedSectionHeaderHeight: CGFloat {
        placesRecommendedSectionTitleTopInset + placesRecommendedSectionTitleHeight
            + placesRecommendedSectionTitleBottomInset
    }

    private var popularSpotsTableView: UITableView?
    private var popularSpotsDisplay: [BHPopularChinaSpot] = []

    private lazy var bodyContentView: UIView = {
        let tempView = UIView.init(frame: CGRectMake(0, kScaleW(196), kScreenWidth, kScreenHeight - kScaleW(196)))
        tempView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tempView.layer.cornerRadius = kScaleW(20)
        tempView.layer.masksToBounds = true
        tempView.backgroundColor = .kHexColor(hexString: "#F7F7F7")

        homeSegmentTitleBar.frame = CGRectMake(0, 0, kScreenWidth, kScaleW(15) + kScaleW(25) + kScaleW(10))
        tempView.addSubview(homeSegmentTitleBar)

        homeSegmentTitleBar.addSubview(homeSegmentSliderView)

        let tempTitleArray = ["旅行视频", "热门地点"]
        homeSegmentButtons.removeAll()

        for index in 0..<tempTitleArray.count {
            let tempTitleBtn = UIButton(type: .custom)
            tempTitleBtn.setTitle(tempTitleArray[index], for: .normal)
            tempTitleBtn.setTitle(tempTitleArray[index], for: .selected)
            tempTitleBtn.tag = 110000 + index
            tempTitleBtn.setTitleColor(.kHexColor(hexString: "#777777"), for: .normal)
            tempTitleBtn.setTitleColor(.kHexColor(hexString: "#000000"), for: .selected)
            tempTitleBtn.addTarget(self, action: #selector(homeSegmentTitleTapped(_:)), for: .touchUpInside)
            homeSegmentTitleBar.addSubview(tempTitleBtn)
            homeSegmentButtons.append(tempTitleBtn)
        }

        selectedHomeSegmentIndex = 0
        layoutHomeSegmentButtons()
        updateHomeSegmentSliderFrame(animated: false)

        let scrollH = tempView.bounds.height - kScaleW(50)
        let tempScrollview = UIScrollView(
            frame: CGRect(x: 0, y: kScaleW(50), width: kScreenWidth, height: scrollH)
        )
        tempScrollview.showsHorizontalScrollIndicator = false
        tempScrollview.isPagingEnabled = true
        tempScrollview.bounces = false
        tempScrollview.contentSize = CGSize(width: kScreenWidth * 2, height: scrollH)
        tempView.addSubview(tempScrollview)
        homeFeedPagingScrollView = tempScrollview

        let flowCommon = UICollectionViewFlowLayout()
        flowCommon.minimumInteritemSpacing = kScaleW(10)
        flowCommon.minimumLineSpacing = kScaleW(12)
        flowCommon.sectionInset = UIEdgeInsets(top: kScaleW(8), left: kScaleW(14), bottom: kScaleW(24), right: kScaleW(14))

        let videoCollection = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: scrollH),
            collectionViewLayout: flowCommon
        )
        
        
        videoCollection.backgroundColor = .clear
        videoCollection.alwaysBounceVertical = true
        videoCollection.tag = SegmentEmbeddedTag.videoCollection
        if #available(iOS 11.0, *) {
            videoCollection.contentInsetAdjustmentBehavior = .never
        }
        videoCollection.register(
            BHHomeTravelVideoGridCell.self,
            forCellWithReuseIdentifier: BHHomeMovieVideoReuse.videoCell
        )
        videoCollection.register(
            BHHomeTravelCompositeHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: BHHomeTravelFeedReuse.header
        )
        videoCollection.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: Self.videoCollectionSectionFooterReuseId
        )
        videoCollection.dataSource = self
        videoCollection.delegate = self
        tempScrollview.addSubview(videoCollection)

        let placesTable = UITableView(frame: CGRect(x: kScreenWidth, y: 0, width: kScreenWidth, height: scrollH), style: .grouped)
        placesTable.separatorStyle = .none
        placesTable.backgroundColor = .clear
        placesTable.tag = SegmentEmbeddedTag.placesTable
        if #available(iOS 15.0, *) {
            placesTable.sectionHeaderTopPadding = 0
        }
        placesTable.delegate = self
        placesTable.dataSource = self
        placesTable.showsVerticalScrollIndicator = true
        placesTable.rowHeight = UITableView.automaticDimension
        placesTable.estimatedRowHeight = kScaleW(132)
        if #available(iOS 11.0, *) {
            placesTable.contentInsetAdjustmentBehavior = .never
        }
        placesTable.register(BHHomePopularPlaceCell.self, forCellReuseIdentifier: BHHomePopularPlaceCell.reuseId)
        placesTable.register(
            UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: Self.placesSectionTitleHeaderReuseId
        )
        placesTable.tableHeaderView = nil
        let placesTail = UIView(
            frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: Self.segmentListTailInsetHeight)
        )
        placesTail.backgroundColor = .clear
        placesTable.tableFooterView = placesTail
        tempScrollview.addSubview(placesTable)
        popularSpotsTableView = placesTable

        return tempView
    }()

    private lazy var bottomTabBar: BHCustomBottomTabBarView = {
        let bar = BHCustomBottomTabBarView(host: self, selectedMainTab: .home)
        bar.onPhotoButtonTapped = { [weak self] in
            guard let nav = self?.navigationController else { return }
            nav.pushViewController(BHDiscoverPostPhotoViewController(), animated: true)
        }
        return bar
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bottomTabBar.syncHighlightedSelectionWithHostingTabBar()
        reloadHomeCollectionsAfterFigureHideRulesChange()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFigureFeedHideListDidChange),
            name: .bhHomeFigureBlockedOrShieldedListDidChange,
            object: nil
        )

        view.backgroundColor = .kHexColor(hexString: "#F7F7F7")
        view.addSubview(topImageView)
        view.addSubview(leftNavTitleLab)
        view.addSubview(bodyContentView)
        view.addSubview(bottomTabBar)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomTabBar.layoutFrame(in: view.bounds)
        bh_bringCustomTabBarToFront(bottomTabBar)
        syncPopularPlacesTableFooterFrameIfNeeded()
    }

    @objc private func handleFigureFeedHideListDidChange() {
        reloadHomeCollectionsAfterFigureHideRulesChange()
    }

    private func videoSegmentCollectionView() -> UICollectionView? {
        bodyContentView.viewWithTag(SegmentEmbeddedTag.videoCollection) as? UICollectionView
    }

    /// 依据本地拉黑/屏蔽记录更新「热门地点」景点缓存并刷新控件。
    private func reloadHomeCollectionsAfterFigureHideRulesChange() {
        refreshPopularSpotsDisplayCacheIfNeeded()
        videoSegmentCollectionView()?.reloadData()
        popularSpotsTableView?.tableHeaderView = nil
        popularSpotsTableView?.reloadData()
    }

    private func refreshPopularSpotsDisplayCacheIfNeeded() {
        popularSpotsDisplay = BHPopularChinaSpotCatalog.visibleSpotsForHomeFeed()
    }

    private func syncPopularPlacesTableFooterFrameIfNeeded() {
        guard let tv = popularSpotsTableView, let fv = tv.tableFooterView else { return }
        let w = tv.bounds.width
        guard w > 0.5 else { return }
        let targetH = Self.segmentListTailInsetHeight
        if abs(fv.frame.width - w) > 0.5 || abs(fv.frame.height - targetH) > 0.5 {
            fv.frame = CGRect(x: 0, y: 0, width: w, height: targetH)
            tv.tableFooterView = fv
        }
    }

    private func presentRecommendationLocation(for spot: BHPopularChinaSpot) {
        guard let nav = navigationController else { return }
        let vc = BHRecommendationLocationViewController(spot: spot)
        nav.pushViewController(vc, animated: true)
    }

    private func presentPopularSpotIssuesActionSheet(for spot: BHPopularChinaSpot, sourceButton: UIButton) {
        guard let figureId = spot.linkedFigureId else {
            view.cd_showDefaultToast("暂无法对该地点执行此操作")
            return
        }
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "举报", style: .default) { [weak self] _ in
            self?.openFigureReportForPopularSpot(figureId: figureId, fallbackName: spot.attractionTitle)
        })
        sheet.addAction(UIAlertAction(title: "拉黑", style: .destructive) { [weak self] _ in
            self?.applyPopularSpotFigureBlockAndRefresh(figureId: figureId)
        })
        sheet.addAction(UIAlertAction(title: "屏蔽", style: .destructive) { [weak self] _ in
            self?.applyPopularSpotFigureShieldAndRefresh(figureId: figureId)
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sourceButton
            pop.sourceRect = sourceButton.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(sheet, animated: true)
    }

    private func openFigureReportForPopularSpot(figureId: Int, fallbackName: String) {
        guard let nav = navigationController else {
            view.cd_showDefaultToast("无法打开举报页")
            return
        }
        let name =
            BHFigureResourceCatalog.profile(figureId: figureId)?.nickname ?? fallbackName
        let report = BHFigureReportViewController(figureId: figureId, targetDisplayName: name)
        nav.pushViewController(report, animated: true)
    }

    private func applyPopularSpotFigureBlockAndRefresh(figureId: Int) {
        BHFigureBlockShieldStore.block(figureId: figureId)
        finishPopularSpotBlockOrShieldEffects(toast: "已拉黑")
    }

    private func applyPopularSpotFigureShieldAndRefresh(figureId: Int) {
        BHFigureBlockShieldStore.shield(figureId: figureId)
        finishPopularSpotBlockOrShieldEffects(toast: "已屏蔽")
    }

    private func finishPopularSpotBlockOrShieldEffects(toast: String) {
        NotificationCenter.default.post(name: .bhHomeFigureBlockedOrShieldedListDidChange, object: nil)
        view.cd_showDefaultToast(toast)
    }

    private func layoutHomeSegmentButtons() {
        var left = kScaleW(14)
        let top = kScaleW(15)
        let height = kScaleW(25)
        for (i, btn) in homeSegmentButtons.enumerated() {
            let selected = i == selectedHomeSegmentIndex
            btn.isSelected = selected
            btn.titleLabel?.font = .bh_pingFang(size: selected ? 18 : 16, weight: selected ? .medium : .regular)
            btn.sizeToFit()
            btn.frame = CGRect(x: left, y: top, width: btn.bounds.width, height: height)
            left = btn.frame.maxX + kScaleW(14)
        }
    }

    private func updateHomeSegmentSliderFrame(animated: Bool) {
        guard selectedHomeSegmentIndex >= 0, selectedHomeSegmentIndex < homeSegmentButtons.count else { return }
        let btn = homeSegmentButtons[selectedHomeSegmentIndex]
        let sliderY = kScaleW(15) + kScaleW(18)
        let target = CGRect(x: btn.frame.minX, y: sliderY, width: btn.bounds.width, height: kScaleW(6))
        guard animated else {
            homeSegmentSliderView.frame = target
            return
        }
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
            self.homeSegmentSliderView.frame = target
        }
    }

    @objc private func homeSegmentTitleTapped(_ sender: UIButton) {
        let idx = sender.tag - 110000
        guard idx >= 0, idx < homeSegmentButtons.count else { return }
        guard idx != selectedHomeSegmentIndex else { return }
        selectedHomeSegmentIndex = idx
        layoutHomeSegmentButtons()
        updateHomeSegmentSliderFrame(animated: true)
        homeFeedPagingScrollView?.setContentOffset(CGPoint(x: CGFloat(idx) * kScreenWidth, y: 0), animated: true)
    }
}

extension BHHomePageViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard collectionView.tag == SegmentEmbeddedTag.videoCollection else { return 0 }
        return BHMovieResourceCatalog.homeFeedVisibleItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard collectionView.tag == SegmentEmbeddedTag.videoCollection else {
            return UICollectionViewCell()
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BHHomeMovieVideoReuse.videoCell,
            for: indexPath
        ) as! BHHomeTravelVideoGridCell
        let item = BHMovieResourceCatalog.homeFeedVisibleItems[indexPath.item]
        let title = BHFigureResourceCatalog.profile(figureId: item.figureId)?.nickname ?? "旅行记录"
        cell.apply(item: item, displayTitle: title)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard collectionView.tag == SegmentEmbeddedTag.videoCollection else {
            return UICollectionReusableView()
        }
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: BHHomePageViewController.videoCollectionSectionFooterReuseId,
                for: indexPath
            )
            footer.backgroundColor = .clear
            return footer
        }
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: BHHomeTravelFeedReuse.header,
            for: indexPath
        ) as! BHHomeTravelCompositeHeader
        header.onVideoHeroShellTapped = { [weak self] movieItem in
            self?.presentHomeVideoPlayback(movieItem: movieItem)
        }
        header.configure(videoHeroMovies: BHMovieResourceCatalog.homeFeedHeaderHeroMovies)
        return header
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        guard collectionView.tag == SegmentEmbeddedTag.videoCollection else {
            return .zero
        }
        let w = collectionView.bounds.width > 1 ? collectionView.bounds.width : kScreenWidth
        let h = BHHomeTravelCompositeHeader.preferredHeight(forWidth: w)
        return CGSize(width: w, height: h)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        guard collectionView.tag == SegmentEmbeddedTag.videoCollection else {
            return .zero
        }
        let w = collectionView.bounds.width > 1 ? collectionView.bounds.width : kScreenWidth
        let h = BHHomePageViewController.segmentListTailInsetHeight
        return CGSize(width: w, height: h)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard collectionView.tag == SegmentEmbeddedTag.videoCollection,
              let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: kScaleW(160), height: kScaleW(216))
        }
        let w = collectionView.bounds.width
        let inset = layout.sectionInset.left + layout.sectionInset.right
        let spacing = layout.minimumInteritemSpacing
        let cellW = floor((w - inset - spacing) / 2)
        let cellH = floor(cellW * 1.38)
        return CGSize(width: cellW, height: cellH)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView.tag == SegmentEmbeddedTag.videoCollection else { return }
        collectionView.deselectItem(at: indexPath, animated: true)
        guard indexPath.item < BHMovieResourceCatalog.homeFeedVisibleItems.count else { return }
        let item = BHMovieResourceCatalog.homeFeedVisibleItems[indexPath.item]
        presentHomeVideoPlayback(movieItem: item)
    }

    fileprivate func presentHomeVideoPlayback(movieItem: BHMovieResourceItem) {
        guard movieItem.bundleVideoURL() != nil else { return }
        let vc = BHHomeVideoShowViewController(movieItem: movieItem)
        let nav = BHBaseNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

extension BHHomePageViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard tableView.tag == SegmentEmbeddedTag.placesTable else { return nil }
        guard
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Self.placesSectionTitleHeaderReuseId)
        else {
            return nil
        }
        header.backgroundConfiguration = UIBackgroundConfiguration.clear()
        header.contentView.backgroundColor = .clear
        header.backgroundColor = .clear
        let label: UILabel
        if let existing = header.contentView.viewWithTag(Self.placesSectionTitleLabelTag) as? UILabel {
            label = existing
        } else {
            label = UILabel()
            label.tag = Self.placesSectionTitleLabelTag
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .bh_pingFang(size: 17, weight: .bold)
            label.textColor = .kHexColor(hexString: "#000000")
            header.contentView.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(
                    equalTo: header.contentView.leadingAnchor,
                    constant: kScaleW(14)
                ),
                label.trailingAnchor.constraint(
                    lessThanOrEqualTo: header.contentView.trailingAnchor,
                    constant: -kScaleW(14)
                ),
                label.topAnchor.constraint(
                    equalTo: header.contentView.topAnchor,
                    constant: Self.placesRecommendedSectionTitleTopInset
                ),
                label.bottomAnchor.constraint(
                    equalTo: header.contentView.bottomAnchor,
                    constant: -Self.placesRecommendedSectionTitleBottomInset
                ),
            ])
        }
        label.text = "地点推荐"
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard tableView.tag == SegmentEmbeddedTag.placesTable else { return 0 }
        return Self.placesRecommendedSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard tableView.tag == SegmentEmbeddedTag.placesTable else { return 0 }
        return Self.placesRecommendedSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard tableView.tag == SegmentEmbeddedTag.placesTable else { return 0 }
        return popularSpotsDisplay.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard tableView.tag == SegmentEmbeddedTag.placesTable else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: BHHomePopularPlaceCell.reuseId,
            for: indexPath
        ) as! BHHomePopularPlaceCell
        let spot = popularSpotsDisplay[indexPath.row]
        cell.configure(with: spot)
        cell.onTapDetail = { [weak self] in
            self?.presentRecommendationLocation(for: spot)
        }
        cell.onThumbIssuesMenu = { [weak self] spot, anchor in
            self?.presentPopularSpotIssuesActionSheet(for: spot, sourceButton: anchor)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard tableView.tag == SegmentEmbeddedTag.placesTable else { return UITableView.automaticDimension }
        return kScaleW(132)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.tag == SegmentEmbeddedTag.placesTable else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        guard popularSpotsDisplay.indices.contains(indexPath.row) else { return }
        let spot = popularSpotsDisplay[indexPath.row]
        presentRecommendationLocation(for: spot)
    }
}
