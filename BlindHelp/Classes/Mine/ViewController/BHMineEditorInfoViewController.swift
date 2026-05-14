//
//  BHMineEditorInfoViewController.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/14.
//

import UIKit
import PhotosUI

/// 各页面共用的头像网络地址；登录/拉取个人资料成功后赋值，编辑页与「我的」页可据此统一刷新头像显示。
enum BHMineUserAvatarStore {
    static var remoteURL: URL?
}

/// 资料编辑页。
final class BHMineEditorInfoViewController: BHBaseViewController {

    /// 当前选中的爱好下标（与按钮 `tag - 410000` 对应）；单选，同时仅一个为选中色。
    private var selectedHobbyIndex: Int?

    private weak var hobbySelectContainerView: UIView?

    /// 用户是否使用过相册头像；`false` 表示沿用资源图 `BHUserProfileManager.defaultAvatarAssetName`。
    private var avatarSourceIsCustom = false

    private var nickNameValueLabel: UILabel?
    private var personalityValueLabel: UILabel?
    private var locationValueLabel: UILabel?
    private var signaturePlaceholderTextView: UITextView?
    private var signatureInputTextView: UITextView?

    private static let personalityOptions = ["乐观", "开朗", "内敛", "成熟", "外向"]

    /// 顶部头像图，本地占位 + 网络图均可：网络场景使用 `kf.setImage(with:)` 或对 `image` 赋值。
    lazy var editorHeaderImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: BHUserProfileManager.defaultAvatarAssetName))
        v.contentMode = .scaleAspectFill
        v.layer.masksToBounds = true
        return v
    }()

    private lazy var editorHeaderIconBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.frame = CGRect(
            x: (kScreenWidth - kScaleW(80)) / 2,
            y: kNavBarFullHeight + kScaleW(12),
            width: kScaleW(80),
            height: kScaleW(110)
        )
        btn.addTarget(self, action: #selector(changerHeaderIconImageBtnClick(_:)), for: .touchUpInside)
        let iv = editorHeaderImageView
        iv.frame = CGRect(x: 0, y: 0, width: kScaleW(80), height: kScaleW(80))
        iv.layer.cornerRadius = iv.bounds.height / 2
        btn.addSubview(iv)

        let tip = UILabel(
            frame: CGRect(
                x: iv.left - kScaleW(12),
                y: iv.bottom + kScaleW(10),
                width: btn.bounds.width + kScaleW(24),
                height: kScaleW(20)
            )
        )
        tip.text = "点击更换头像"
        tip.textColor = .kHexColor(hexString: "#000000")
        tip.textAlignment = .center
        tip.font = .bh_pingFang(size: 14, weight: .regular)
        btn.addSubview(tip)

        return btn
    }()

    private lazy var editorContentView: UIView = {
        let tempView = UIView(
            frame: CGRect(
                x: kScaleW(14),
                y: editorHeaderIconBtn.bottom + kScaleW(20),
                width: kScreenWidth - kScaleW(28),
                height: kScreenHeight - editorHeaderIconBtn.bottom - kScaleW(20) - kBottomSafeHeight - kScaleW(43)
            )
        )
        tempView.layer.cornerRadius = kScaleW(20)
        tempView.layer.masksToBounds = true
        tempView.backgroundColor = .white
        
        let nickNameBtn = UIButton(frame: CGRectMake(0, kScaleW(10), tempView.width, kScaleW(40)))
        tempView.addSubview(nickNameBtn)
        nickNameBtn.addTarget(self, action: #selector(nickNameBtnClick(_:)), for: .touchUpInside)
        let leftNickNameTipLab = UILabel.init(frame: CGRectMake(kScaleW(14), 0, kScaleW(40), kScaleW(40)))
        leftNickNameTipLab.text = "昵称"
        leftNickNameTipLab.textAlignment = .left
        leftNickNameTipLab.font = .bh_pingFang(size: 14, weight: .regular)
        leftNickNameTipLab.textColor = .kHexColor(hexString: "#000000")
        nickNameBtn.addSubview(leftNickNameTipLab)
        
        let rightNickNameArrow = UIImageView(image: UIImage(named: "editor_right_arrow"))
        rightNickNameArrow.frame = CGRectMake(nickNameBtn.width - kScaleW(7) - kScaleW(14), (nickNameBtn.height - kScaleW(12))/2.0, kScaleW(7), kScaleW(12))
        nickNameBtn.addSubview(rightNickNameArrow)

        let nickNameValueLab = UILabel(frame: CGRectMake(rightNickNameArrow.left - kScaleW(6) - kScaleW(150), 0, kScaleW(150), kScaleW(40)))
        nickNameValueLab.text = BHStoredUserProfile.baseline.nickname
        nickNameValueLab.textAlignment = .right
        nickNameValueLab.font = .bh_pingFang(size: 14, weight: .regular)
        nickNameValueLab.textColor = .kHexColor(hexString: "#000000")
        nickNameBtn.addSubview(nickNameValueLab)
        self.nickNameValueLabel = nickNameValueLab

        let personalityBtn = UIButton(frame: CGRectMake(0, nickNameBtn.bottom, tempView.width, kScaleW(40)))
        tempView.addSubview(personalityBtn)
        personalityBtn.addTarget(self, action: #selector(personalityBtnClick(_:)), for: .touchUpInside)
        let leftPersonalityTipLab = UILabel.init(frame: CGRectMake(kScaleW(14), 0, kScaleW(40), kScaleW(40)))
        leftPersonalityTipLab.text = "性格"
        leftPersonalityTipLab.textAlignment = .left
        leftPersonalityTipLab.font = .bh_pingFang(size: 14, weight: .regular)
        leftPersonalityTipLab.textColor = .kHexColor(hexString: "#000000")
        personalityBtn.addSubview(leftPersonalityTipLab)

        let rightPersonalityArrow = UIImageView(image: UIImage(named: "editor_right_arrow"))
        rightPersonalityArrow.frame = CGRectMake(personalityBtn.width - kScaleW(7) - kScaleW(14), (personalityBtn.height - kScaleW(12)) / 2.0, kScaleW(7), kScaleW(12))
        personalityBtn.addSubview(rightPersonalityArrow)

        let personalityValueLab = UILabel(frame: CGRectMake(rightPersonalityArrow.left - kScaleW(6) - kScaleW(150), 0, kScaleW(150), kScaleW(40)))
        personalityValueLab.text = BHStoredUserProfile.baseline.personality
        personalityValueLab.textAlignment = .right
        personalityValueLab.font = .bh_pingFang(size: 14, weight: .regular)
        personalityValueLab.textColor = .kHexColor(hexString: "#000000")
        personalityBtn.addSubview(personalityValueLab)
        self.personalityValueLabel = personalityValueLab

        let hobbyView = UIView(frame: CGRectMake(0, personalityBtn.bottom, tempView.width, kScaleW(40) + kScaleW(30) + kScaleW(10)))
        tempView.addSubview(hobbyView)
        let leftHobbyTipLab = UILabel.init(frame: CGRectMake(kScaleW(14), 0, kScaleW(40), kScaleW(40)))
        leftHobbyTipLab.text = "爱好"
        leftHobbyTipLab.textAlignment = .left
        leftHobbyTipLab.font = .bh_pingFang(size: 14, weight: .regular)
        leftHobbyTipLab.textColor = .kHexColor(hexString: "#000000")
        hobbyView.addSubview(leftHobbyTipLab)

        let rightHobbyLab = UILabel.init(frame: CGRectMake(hobbyView.width - kScaleW(14) - kScaleW(150), 0, kScaleW(150), kScaleW(40)))
        rightHobbyLab.text = "请选择"
        rightHobbyLab.textAlignment = .right
        rightHobbyLab.font = .bh_pingFang(size: 14, weight: .regular)
        rightHobbyLab.textColor = .kHexColor(hexString: "#999999")
        hobbyView.addSubview(rightHobbyLab)

        let hobbySelectView = UIView.init(frame: CGRectMake(0, kScaleW(40), hobbyView.width, kScaleW(30)))
        hobbyView.addSubview(hobbySelectView)
        self.hobbySelectContainerView = hobbySelectView
        let hobbyDataArray = BHUserProfileManager.hobbyTitles
        let hobbyIntervalWidth = kScaleW(8) * (CGFloat(hobbyDataArray.count) - 1.0)
        let hobbyBtnWidth = (hobbySelectView.width - kScaleW(28) - hobbyIntervalWidth) / CGFloat(hobbyDataArray.count)

        for index in 0..<hobbyDataArray.count {
            let hobbySelectBtn = UIButton.init(frame: CGRectMake(kScaleW(14) + (hobbyBtnWidth + kScaleW(8)) * CGFloat(index) , 0, hobbyBtnWidth, kScaleW(30)))
            hobbySelectView.addSubview(hobbySelectBtn)
            hobbySelectBtn.backgroundColor = .kHexColor(hexString: "#ECECEC")
            hobbySelectBtn.setTitle(hobbyDataArray[index], for: .normal)
            hobbySelectBtn.titleLabel?.font = .bh_pingFang(size: 14, weight: .regular)
            hobbySelectBtn.setTitleColor(.kHexColor(hexString: "#000000"), for: .normal)
            hobbySelectBtn.layer.cornerRadius = hobbySelectBtn.height / 2.0
            hobbySelectBtn.addTarget(self, action: #selector(hobbySelectBtnClick(_:)), for: .touchUpInside)
            hobbySelectBtn.tag = 410000 + index
        }

        let locationBtn = UIButton(frame: CGRectMake(0, hobbyView.bottom, tempView.width, kScaleW(40)))
        tempView.addSubview(locationBtn)
        locationBtn.addTarget(self, action: #selector(locationBtnClick(_:)), for: .touchUpInside)
        let leftLocationTipLab = UILabel(frame: CGRectMake(kScaleW(14), 0, kScaleW(56), kScaleW(40)))
        leftLocationTipLab.text = "地区"
        leftLocationTipLab.textAlignment = .left
        leftLocationTipLab.font = .bh_pingFang(size: 14, weight: .regular)
        leftLocationTipLab.textColor = .kHexColor(hexString: "#000000")
        locationBtn.addSubview(leftLocationTipLab)

        let rightLocationArrow = UIImageView(image: UIImage(named: "editor_right_arrow"))
        rightLocationArrow.frame = CGRectMake(locationBtn.width - kScaleW(7) - kScaleW(14), (locationBtn.height - kScaleW(12)) / 2.0, kScaleW(7), kScaleW(12))
        locationBtn.addSubview(rightLocationArrow)

        let locationValueLab = UILabel(frame: CGRectMake(rightLocationArrow.left - kScaleW(6) - kScaleW(150), 0, kScaleW(150), kScaleW(40)))
        locationValueLab.text = BHStoredUserProfile.baseline.regionDisplay
        locationValueLab.textAlignment = .right
        locationValueLab.font = .bh_pingFang(size: 14, weight: .regular)
        locationValueLab.textColor = .kHexColor(hexString: "#000000")
        locationBtn.addSubview(locationValueLab)
        self.locationValueLabel = locationValueLab
        
        
        let saveInfoEditorBtn = UIButton.init(frame: CGRectMake(kScaleW(14), tempView.height - kScaleW(18) - kScaleW(50), tempView.width - kScaleW(28), kScaleW(50)))
        saveInfoEditorBtn.layer.cornerRadius = saveInfoEditorBtn.height / 2.0
        saveInfoEditorBtn.layer.masksToBounds = true
        saveInfoEditorBtn.backgroundColor = .kHexColor(hexString: "#A5F500")
        saveInfoEditorBtn.setTitle("保存资料", for: .normal)
        saveInfoEditorBtn.setTitleColor(.kHexColor(hexString: "#000000"), for: .normal)
        saveInfoEditorBtn.titleLabel?.font = .bh_pingFang(size: 16, weight: .regular)
        saveInfoEditorBtn.addTarget(self, action: #selector(saveInfoEditorBtnClick(_:)), for: .touchUpInside)
        tempView.addSubview(saveInfoEditorBtn)
        
        
        var signatureViewHeight = saveInfoEditorBtn.top - locationBtn.bottom - kScaleW(12)
        if signatureViewHeight > kScaleW(160) {
            signatureViewHeight = kScaleW(160)
        }
        
        let signatureView = UIView(frame: CGRectMake(0, locationBtn.bottom, tempView.width, signatureViewHeight))
        tempView.addSubview(signatureView)
        let leftSignatureTipLab = UILabel.init(frame: CGRectMake(kScaleW(14), 0, kScaleW(40), kScaleW(40)))
        leftSignatureTipLab.text = "签名"
        leftSignatureTipLab.textAlignment = .left
        leftSignatureTipLab.font = .bh_pingFang(size: 14, weight: .regular)
        leftSignatureTipLab.textColor = .kHexColor(hexString: "#000000")
        signatureView.addSubview(leftSignatureTipLab)
        
        let signatureContentView = UIView.init(frame: CGRectMake(kScaleW(14), leftSignatureTipLab.bottom, signatureView.width - kScaleW(28), signatureViewHeight - kScaleW(40)))
        signatureContentView.layer.cornerRadius = kScaleW(14)
        signatureContentView.layer.masksToBounds = true
        signatureContentView.backgroundColor = .kHexColor(hexString: "#F0F0F0")
        signatureView.addSubview(signatureContentView)
        
        let signatureContentInputTipTextView = UITextView(frame: CGRectMake(kScaleW(7), kScaleW(7), signatureContentView.width - kScaleW(14), signatureContentView.height - kScaleW(14)))
        signatureContentInputTipTextView.isUserInteractionEnabled = false
        signatureContentInputTipTextView.backgroundColor = .clear
        signatureContentInputTipTextView.text = "说点什么吧～"
        signatureContentInputTipTextView.textColor = .kHexColor(hexString: "#777777")
        signatureContentInputTipTextView.font = .bh_pingFang(size: 14, weight: .regular)
        signatureContentInputTipTextView.textAlignment = .left
        signatureContentView.addSubview(signatureContentInputTipTextView)

        let signatureContentInputTextView = UITextView(frame: CGRectMake(kScaleW(7), kScaleW(7), signatureContentView.width - kScaleW(14), signatureContentView.height - kScaleW(14)))
        signatureContentInputTextView.isUserInteractionEnabled = true
        signatureContentInputTextView.backgroundColor = .clear
        signatureContentInputTextView.text = ""
        signatureContentInputTextView.textColor = .kHexColor(hexString: "#000000")
        signatureContentInputTextView.font = .bh_pingFang(size: 14, weight: .regular)
        signatureContentInputTextView.textAlignment = .left
        signatureContentInputTextView.delegate = self
        signatureContentView.addSubview(signatureContentInputTextView)

        self.signaturePlaceholderTextView = signatureContentInputTipTextView
        self.signatureInputTextView = signatureContentInputTextView
        refreshSignaturePlaceholderVisibility()
        
        return tempView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(editorHeaderIconBtn)
        view.addSubview(editorContentView)
        applyProfileFromStore()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

extension BHMineEditorInfoViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        guard textView === signatureInputTextView else { return }
        refreshSignaturePlaceholderVisibility()
    }

    func refreshSignaturePlaceholderVisibility() {
        let isEmpty = signatureInputTextView?.text?.isEmpty ?? true
        signaturePlaceholderTextView?.isHidden = !isEmpty
    }
}

extension BHMineEditorInfoViewController {

    @objc func nickNameBtnClick(_ senderBtn: UIButton) {
        let alert = UIAlertController(title: "修改昵称", message: nil, preferredStyle: .alert)
        alert.addTextField { [weak self] field in
            field.text = self?.nickNameValueLabel?.text
            field.placeholder = "请输入昵称"
            field.clearButtonMode = .whileEditing
            field.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let self else { return }
            let raw = alert.textFields?.first?.text ?? ""
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            self.nickNameValueLabel?.text = name
        })
        present(alert, animated: true)
    }

}


extension BHMineEditorInfoViewController {

    @objc func personalityBtnClick(_ senderBtn: UIButton) {
        let alert = UIAlertController(title: "选择性格", message: nil, preferredStyle: .actionSheet)
        for title in Self.personalityOptions {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.personalityValueLabel?.text = title
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = senderBtn
            pop.sourceRect = senderBtn.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(alert, animated: true)
    }

}

extension BHMineEditorInfoViewController {

    @objc func hobbySelectBtnClick(_ senderBtn: UIButton) {
        let idx = senderBtn.tag - 410000
        guard idx >= 0 else { return }
        applyHobbyVisualState(index: idx)
    }
}

extension BHMineEditorInfoViewController: PHPickerViewControllerDelegate {

    @objc func changerHeaderIconImageBtnClick(_ senderBtn: UIButton) {
        var cfg = PHPickerConfiguration()
        cfg.filter = .images
        cfg.selectionLimit = 1
        let picker = PHPickerViewController(configuration: cfg)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        let provider = result.itemProvider
        guard provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            DispatchQueue.main.async {
                guard let self, let image = obj as? UIImage else { return }
                self.avatarSourceIsCustom = true
                self.editorHeaderImageView.image = image
                BHMineUserAvatarStore.remoteURL = nil
            }
        }
    }
}

extension BHMineEditorInfoViewController {
    @objc func locationBtnClick(_ senderBtn: UIButton) {
        let vc = BHChinaRegionProvinceViewController()
        vc.onProvinceCityPicked = { [weak self] province, city in
            self?.locationValueLabel?.text = "\(province) \(city)"
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}


extension BHMineEditorInfoViewController{

    private func applyProfileFromStore() {
        let snapshot = BHUserProfileManager.shared.currentProfileSnapshot()
        avatarSourceIsCustom = !snapshot.usesDefaultAvatar
        nickNameValueLabel?.text = snapshot.nickname
        personalityValueLabel?.text = snapshot.personality
        locationValueLabel?.text = snapshot.regionDisplay
        signatureInputTextView?.text = snapshot.signature
        refreshSignaturePlaceholderVisibility()
        editorHeaderImageView.image = BHUserProfileManager.shared.loadAvatarForDisplay()
        applyHobbyVisualState(index: snapshot.hobbyIndex)
    }

    private func applyHobbyVisualState(index: Int) {
        guard let container = hobbySelectContainerView else { return }
        let count = BHUserProfileManager.hobbyTitles.count
        guard count > 0 else { return }
        let idx = min(max(0, index), count - 1)
        selectedHobbyIndex = idx
        let normalBg = UIColor.kHexColor(hexString: "#ECECEC")
        let selectedBg = UIColor.kHexColor(hexString: "#A5F500")
        for case let btn as UIButton in container.subviews {
            let i = btn.tag - 410000
            guard i >= 0 else { continue }
            btn.backgroundColor = (i == idx) ? selectedBg : normalBg
        }
    }

    @objc func saveInfoEditorBtnClick(_ senderBtn: UIButton) {
        let base = BHStoredUserProfile.baseline
        let rawNick = nickNameValueLabel?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawPers = personalityValueLabel?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawRegion = locationValueLabel?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let snapshot = BHStoredUserProfile(
            nickname: rawNick.isEmpty ? base.nickname : rawNick,
            personality: rawPers.isEmpty ? base.personality : rawPers,
            hobbyIndex: selectedHobbyIndex ?? base.hobbyIndex,
            regionDisplay: rawRegion.isEmpty ? base.regionDisplay : rawRegion,
            signature: signatureInputTextView?.text ?? "",
            usesDefaultAvatar: !avatarSourceIsCustom
        )
        BHUserProfileManager.shared.save(snapshot: snapshot, avatarImage: avatarSourceIsCustom ? editorHeaderImageView.image : nil)
        view.cd_showDefaultToast("保存成功")
        
        self.navigationController?.popViewController(animated: true)
    }
}
