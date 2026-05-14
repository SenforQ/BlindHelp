//
//  BHMinePhotoViewController.swift
//  BlindHelp
//

import AVFoundation
import PhotosUI
import UIKit
import UniformTypeIdentifiers

final class BHMinePhotoViewController: BHBaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPickerViewControllerDelegate {

    private enum AlbumTab {
        case album
        case video
    }

    private final class BHMineAlbumUploadCell: UICollectionViewCell {

        private let card = UIView()
        private let iconView = UIImageView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            card.backgroundColor = UIColor.kHexColor(hexString: "#EAEAEA")
            card.layer.cornerRadius = kScaleW(8)
            card.layer.masksToBounds = true
            contentView.addSubview(card)
            if let img = UIImage(systemName: "camera.fill")?.withTintColor(UIColor.kHexColor(hexString: "#444444"), renderingMode: .alwaysOriginal) {
                iconView.image = img
            }
            iconView.contentMode = .scaleAspectFit
            card.addSubview(iconView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            card.frame = contentView.bounds
            let sz = min(card.bounds.width, card.bounds.height) * 0.32
            iconView.frame = CGRect(
                x: (card.bounds.width - sz) / 2,
                y: (card.bounds.height - sz) / 2,
                width: sz,
                height: sz
            )
        }
    }

    private final class BHMineAlbumMediaCell: UICollectionViewCell {

        private let thumbView = UIImageView()
        private let playBadge = UIImageView()
        private let deleteBtn = UIButton(type: .custom)
        private var thumbRequestToken = UUID()

        override init(frame: CGRect) {
            super.init(frame: frame)
            clipsToBounds = true

            thumbView.contentMode = .scaleAspectFill
            thumbView.layer.cornerRadius = kScaleW(8)
            thumbView.layer.masksToBounds = true
            thumbView.backgroundColor = UIColor.kHexColor(hexString: "#EAEAEA")
            contentView.addSubview(thumbView)

            playBadge.image = UIImage(systemName: "play.circle.fill")?.withTintColor(UIColor.white.withAlphaComponent(0.92), renderingMode: .alwaysOriginal)
            playBadge.contentMode = .scaleAspectFit
            playBadge.isHidden = true
            contentView.addSubview(playBadge)

            deleteBtn.adjustsImageWhenHighlighted = false
            if let img = UIImage(systemName: "xmark.circle.fill")?.withTintColor(UIColor.kHexColor(hexString: "#FF3B30"), renderingMode: .alwaysOriginal) {
                deleteBtn.setImage(img, for: .normal)
            }
            deleteBtn.addTarget(self, action: #selector(deleteTap), for: .touchUpInside)
            deleteBtn.isHidden = true
            contentView.addSubview(deleteBtn)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            onTapDelete = nil
            thumbView.image = nil
        }

        private var onTapDelete: (() -> Void)?

        override func layoutSubviews() {
            super.layoutSubviews()
            thumbView.frame = contentView.bounds
            let playSize = min(contentView.bounds.width, contentView.bounds.height) * 0.35
            playBadge.frame = CGRect(
                x: (contentView.bounds.width - playSize) / 2,
                y: (contentView.bounds.height - playSize) / 2,
                width: playSize,
                height: playSize
            )
            let d = kScaleW(24)
            deleteBtn.frame = CGRect(
                x: contentView.bounds.width - d + kScaleW(2),
                y: kScaleW(6),
                width: d,
                height: d
            )
        }

        @objc private func deleteTap() {
            onTapDelete?()
        }

        func configure(record: BHMineSavedMediaRecord, editing: Bool, fileURL: URL) {
            onTapDelete = nil
            deleteBtn.isHidden = !editing
            playBadge.isHidden = record.kind != .video

            let token = UUID()
            thumbRequestToken = token
            thumbView.image = nil

            if record.kind == .photo {
                if let img = UIImage(contentsOfFile: fileURL.path) {
                    thumbView.image = img
                }
                return
            }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let img = Self.makeVideoPoster(url: fileURL)
                DispatchQueue.main.async {
                    guard let self, self.thumbRequestToken == token else { return }
                    self.thumbView.image = img
                }
            }
        }

        func setDeleteHandler(_ block: @escaping () -> Void) {
            onTapDelete = block
        }

        private static func makeVideoPoster(url: URL) -> UIImage? {
            let asset = AVURLAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.3, preferredTimescale: 600)
            guard let cg = try? gen.copyCGImage(at: time, actualTime: nil) else { return nil }
            return UIImage(cgImage: cg)
        }
    }

    private let segmentedControl = UISegmentedControl(items: ["相册", "视频"])
    private let layoutFlow = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layoutFlow)

    private let navRightActionBtn = UIButton(type: .system)

    private var selectedTab: AlbumTab = .album
    private var isEditingMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "我的相册"
        kdNavBar.navTitleLab.text = "我的相册"

        navRightActionBtn.setTitleColor(.kHexColor(hexString: "#000000"), for: .normal)
        navRightActionBtn.titleLabel?.font = .bh_pingFang(size: 16, weight: .regular)
        navRightActionBtn.addTarget(self, action: #selector(editBarButtonTapped), for: .touchUpInside)
        kdNavBar.navigationView.addSubview(navRightActionBtn)
        applyEditButtonAppearance()

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.15)
        segmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        segmentedControl.layer.cornerRadius = kScaleW(10)
        segmentedControl.layer.masksToBounds = true

        segmentedControl.setTitleTextAttributes([
            .font: UIFont.bh_pingFang(size: 14, weight: .regular),
            .foregroundColor: UIColor.kHexColor(hexString: "#999999")
        ], for: .normal)
        segmentedControl.setTitleTextAttributes([
            .font: UIFont.bh_pingFang(size: 14, weight: .medium),
            .foregroundColor: UIColor.kHexColor(hexString: "#000000")
        ], for: .selected)

        segmentedControl.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)

        layoutFlow.minimumInteritemSpacing = kScaleW(8)
        layoutFlow.minimumLineSpacing = kScaleW(8)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.register(BHMineAlbumUploadCell.self, forCellWithReuseIdentifier: "upload")
        collectionView.register(BHMineAlbumMediaCell.self, forCellWithReuseIdentifier: "media")
        collectionView.keyboardDismissMode = .onDrag
    }

    override func setupBodyView() {
        view.addSubview(segmentedControl)
        view.addSubview(collectionView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let navSubview = kdNavBar.navigationView
        let nw = navSubview.bounds.width
        let ew = kScaleW(56)
        navRightActionBtn.frame = CGRect(x: nw - ew - kScaleW(10), y: 0, width: ew, height: kNavBarHeight)

        let topY = kdNavBar.frame.maxY + kScaleW(10)
        segmentedControl.frame = CGRect(x: kScaleW(14), y: topY, width: kScreenWidth - kScaleW(28), height: kScaleW(34))

        let collY = segmentedControl.frame.maxY + kScaleW(12)
        collectionView.frame = CGRect(
            x: 0,
            y: collY,
            width: view.bounds.width,
            height: view.bounds.height - collY
        )
        layoutFlow.sectionInset = UIEdgeInsets(top: 0, left: kScaleW(14), bottom: kScaleW(20), right: kScaleW(14))
        layoutFlow.invalidateLayout()
    }

    private func orderedItems(for tab: AlbumTab) -> [BHMineSavedMediaRecord] {
        switch tab {
        case .album:
            return BHLocalMineAlbumStore.shared.filteredRecords(kind: .photo)
        case .video:
            return BHLocalMineAlbumStore.shared.filteredRecords(kind: .video)
        }
    }

    private func showsLeadingUploadCell() -> Bool {
        !isEditingMode
    }

    private func rowCount(for tab: AlbumTab) -> Int {
        orderedItems(for: tab).count + (showsLeadingUploadCell() ? 1 : 0)
    }

    private func albumTab(forSegmentIndex segment: Int) -> AlbumTab {
        segment == 0 ? .album : .video
    }

    private func mapIndexPathItemToMediaIndex(item: Int) -> Int? {
        if showsLeadingUploadCell() {
            if item == 0 {
                return nil
            }
            return item - 1
        }
        return item
    }

    @objc private func segmentValueChanged(_ sender: UISegmentedControl) {
        selectedTab = albumTab(forSegmentIndex: sender.selectedSegmentIndex)
        isEditingMode = false
        applyEditButtonAppearance()
        collectionView.reloadData()
    }

    @objc private func editBarButtonTapped() {
        isEditingMode.toggle()
        applyEditButtonAppearance()
        collectionView.reloadData()
    }

    private func applyEditButtonAppearance() {
        navRightActionBtn.setTitle(isEditingMode ? "取消" : "编辑", for: .normal)
    }

    private func tileSideLength(forWidth w: CGFloat) -> CGFloat {
        let columns: CGFloat = 3
        let inset = layoutFlow.sectionInset.left + layoutFlow.sectionInset.right
        let spacing = layoutFlow.minimumInteritemSpacing * (columns - 1)
        return floor((w - inset - spacing) / columns)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        rowCount(for: selectedTab)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let idx = mapIndexPathItemToMediaIndex(item: indexPath.item) else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "upload", for: indexPath) as! BHMineAlbumUploadCell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "media", for: indexPath) as! BHMineAlbumMediaCell
        let rows = orderedItems(for: selectedTab)
        let record = rows[idx]
        let fileURL = BHLocalMineAlbumStore.shared.resolvedURL(for: record)
        cell.configure(record: record, editing: isEditingMode, fileURL: fileURL)
        cell.setDeleteHandler { [weak self] in
            BHLocalMineAlbumStore.shared.deleteRecord(id: record.id)
            self?.collectionView.reloadData()
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        if mapIndexPathItemToMediaIndex(item: indexPath.item) != nil {
            return
        }
        presentGalleryPicker(for: selectedTab)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let s = tileSideLength(forWidth: collectionView.bounds.width)
        return CGSize(width: s, height: s)
    }

    private func presentGalleryPicker(for tab: AlbumTab) {
        var cfg = PHPickerConfiguration()
        cfg.filter = tab == .album ? .images : .videos
        cfg.selectionLimit = 0

        let picker = PHPickerViewController(configuration: cfg)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }
        handlePickerResults(results, tabExpectation: selectedTab)
    }

    private func handlePickerResults(_ results: [PHPickerResult], tabExpectation: AlbumTab) {
        switch tabExpectation {
        case .album:
            for r in results {
                guard r.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
                r.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
                    guard let img = obj as? UIImage, let jpeg = img.jpegData(compressionQuality: 0.92) else { return }
                    DispatchQueue.main.async {
                        do {
                            _ = try BHLocalMineAlbumStore.shared.addPhotoJPEGData(jpeg)
                            self?.collectionView.reloadData()
                        } catch {
                            self?.view.cd_showDefaultToast("保存失败，请重试")
                        }
                    }
                }
            }

        case .video:
            for r in results {
                let provider = r.itemProvider
                let movieId = UTType.movie.identifier
                guard provider.hasItemConformingToTypeIdentifier(movieId) else { continue }
                provider.loadFileRepresentation(forTypeIdentifier: movieId) { url, _ in
                    let copyResult: Result<Void, Error> = {
                        guard let url else {
                            return .failure(NSError(domain: "BHPhoto", code: -1))
                        }

                        let gotAccess = url.startAccessingSecurityScopedResource()
                        defer {
                            if gotAccess {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }

                        do {
                            _ = try BHLocalMineAlbumStore.shared.addVideoCopiedFromPickerURL(url)
                            return .success(())
                        } catch {
                            return .failure(error)
                        }
                    }()

                    DispatchQueue.main.async { [weak self] in
                        switch copyResult {
                        case .success:
                            self?.collectionView.reloadData()
                        case .failure:
                            self?.view.cd_showDefaultToast("保存视频失败")
                        }
                    }
                }
            }
        }
    }
}
