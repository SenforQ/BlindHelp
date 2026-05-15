//
//  BHFigureMessageViewController.swift
//  BlindHelp
//

import UIKit

/// 与 NPC 私信：每名用户仅能发出一条正文，不设自动回复。
final class BHFigureMessageViewController: BHBaseViewController, UITextFieldDelegate, UITableViewDataSource,
    UITableViewDelegate, UIGestureRecognizerDelegate {

    private let figureId: Int

    private var displayNameFallback: String

    private let tableView = UITableView(frame: .zero, style: .plain)

    private let inputShell = UIView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .custom)

    private var outgoingLine: String?

    private lazy var dismissKeyboardTap: UITapGestureRecognizer = {
        let gr = UITapGestureRecognizer(target: self, action: #selector(surfaceTappedToDismissKeyboard))
        gr.cancelsTouchesInView = false
        gr.delegate = self
        return gr
    }()

    init(figureId: Int) {
        self.figureId = figureId
        displayNameFallback =
            BHFigureResourceCatalog.profile(figureId: figureId)?.nickname ?? "旅友"
        super.init(nibName: nil, bundle: nil)
        title = displayNameFallback
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupBodyView() {
        baseBackgroundTopImgV.isHidden = true
        view.backgroundColor = .kHexColor(hexString: "#F2F2F7")

        kdNavBar.navTitleLab.text = displayNameFallback
        kdNavBar.isHidden = false

        outgoingLine = BHFigureChatHistoryStore.savedMessageBody(for: figureId)
        refreshNavTitleFromCatalog()

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .none
        tableView.estimatedRowHeight = kScaleW(56)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BHFigureOutgoingBubbleCell.self, forCellReuseIdentifier: BHFigureOutgoingBubbleCell.reuseId)
        tableView.sectionHeaderHeight = CGFloat.leastNonzeroMagnitude
        tableView.sectionFooterHeight = CGFloat.leastNonzeroMagnitude
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delaysContentTouches = false

        inputShell.backgroundColor = .white
        inputShell.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        inputShell.layer.shadowOffset = CGSize(width: 0, height: -kScaleW(1))
        inputShell.layer.shadowOpacity = 1
        inputShell.layer.shadowRadius = kScaleW(2)
        inputShell.translatesAutoresizingMaskIntoConstraints = false

        inputField.font = .bh_pingFang(size: kScaleW(15), weight: .regular)
        inputField.placeholder = "说点什么…"
        inputField.borderStyle = .none
        inputField.textColor = .black
        inputField.backgroundColor = .kHexColor(hexString: "#F0F0F0")
        inputField.layer.cornerRadius = kScaleW(20)
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: kScaleW(14), height: 10))
        inputField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: kScaleW(14), height: 10))
        inputField.leftViewMode = .always
        inputField.rightViewMode = .always
        inputField.returnKeyType = .done
        inputField.delegate = self
        inputField.addTarget(self, action: #selector(inputFieldEdited), for: .editingChanged)
        inputField.translatesAutoresizingMaskIntoConstraints = false

        sendButton.setTitle("发送", for: .normal)
        sendButton.titleLabel?.font = .bh_pingFang(size: kScaleW(15), weight: .medium)
        sendButton.setTitleColor(.black, for: .normal)
        sendButton.setTitleColor(UIColor.black.withAlphaComponent(0.38), for: .disabled)
        sendButton.layer.cornerRadius = kScaleW(20)
        sendButton.layer.masksToBounds = true
        sendButton.configuration = nil
        sendButton.backgroundColor = .kHexColor(hexString: "#A6F500")
        sendButton.adjustsImageWhenHighlighted = false
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.contentEdgeInsets = UIEdgeInsets(
            top: kScaleW(8),
            left: kScaleW(16),
            bottom: kScaleW(8),
            right: kScaleW(16)
        )
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        inputShell.addSubview(inputField)
        inputShell.addSubview(sendButton)

        view.addSubview(tableView)
        view.addSubview(inputShell)

        refreshSendChromeForOneShotGate()
        view.addGestureRecognizer(dismissKeyboardTap)
    }

    override func setupSubConstraints() {
        let guide = view.keyboardLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: kdNavBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputShell.topAnchor),

            inputShell.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputShell.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputShell.bottomAnchor.constraint(equalTo: guide.topAnchor),
            inputShell.heightAnchor.constraint(greaterThanOrEqualToConstant: kScaleW(56)),

            inputField.leadingAnchor.constraint(equalTo: inputShell.leadingAnchor, constant: kScaleW(14)),
            inputField.bottomAnchor.constraint(equalTo: inputShell.safeAreaLayoutGuide.bottomAnchor, constant: -kScaleW(8)),
            inputField.topAnchor.constraint(equalTo: inputShell.safeAreaLayoutGuide.topAnchor, constant: kScaleW(10)),
            inputField.heightAnchor.constraint(equalToConstant: kScaleW(42)),

            sendButton.leadingAnchor.constraint(equalTo: inputField.trailingAnchor, constant: kScaleW(10)),
            sendButton.trailingAnchor.constraint(equalTo: inputShell.trailingAnchor, constant: -kScaleW(14)),
            sendButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            sendButton.heightAnchor.constraint(equalToConstant: kScaleW(40)),
            sendButton.widthAnchor.constraint(greaterThanOrEqualToConstant: kScaleW(60)),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshNavTitleFromCatalog()
    }

    private func refreshNavTitleFromCatalog() {
        let name =
            BHFigureResourceCatalog.profile(figureId: figureId)?.nickname ?? displayNameFallback
        displayNameFallback = name
        kdNavBar.navTitleLab.text = name
    }

    private func trimmedInput() -> String {
        inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    @objc private func inputFieldEdited() {
        applySendAndFieldChrome()
    }

    private func applySendAndFieldChrome() {
        let locked = BHFigureChatHistoryStore.hasSent(for: figureId)
        inputField.isEnabled = !locked
        let hasChars = !trimmedInput().isEmpty
        if locked {
            sendButton.isEnabled = false
            sendButton.backgroundColor = .kHexColor(hexString: "#C8C8C8")
            return
        }
        sendButton.isEnabled = hasChars
        sendButton.backgroundColor =
            hasChars ? .kHexColor(hexString: "#A6F500") : .kHexColor(hexString: "#BFE086")
    }

    private func refreshSendChromeForOneShotGate() {
        applySendAndFieldChrome()
        if BHFigureChatHistoryStore.hasSent(for: figureId) {
            inputField.placeholder = "对方收到你的留言后可以继续聊天…"
            inputField.text = ""
        } else {
            inputField.placeholder = "说点什么…"
        }
        tableView.reloadData()
        scrollOutgoingVisibleIfNeeded()
    }

    @objc private func sendButtonTapped() {
        guard !BHFigureChatHistoryStore.hasSent(for: figureId) else {
            inputField.endEditing(false)
            view.cd_showDefaultToast("请等待对方回复后再发送")
            return
        }

        let text = trimmedInput()
        guard !text.isEmpty else {
            view.cd_showDefaultToast("请输入要发送的内容")
            return
        }

        BHFigureChatHistoryStore.persistSend(figureId: figureId, body: text)
        outgoingLine = text
        inputField.text = ""
        inputField.endEditing(false)
        refreshSendChromeForOneShotGate()
        view.cd_showDefaultToast("已发送")
    }

    @objc private func surfaceTappedToDismissKeyboard() {
        view.endEditing(false)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let hit = touch.view else { return true }
        if hit.isDescendant(of: kdNavBar.navLeftBtn) { return false }
        if hit.isDescendant(of: inputShell) { return false }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    private func scrollOutgoingVisibleIfNeeded() {
        guard outgoingLine != nil else { return }
        tableView.layoutIfNeeded()
        if tableView.numberOfRows(inSection: 0) > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        outgoingLine == nil ? 0 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let line = outgoingLine else {
            return UITableViewCell()
        }
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: BHFigureOutgoingBubbleCell.reuseId,
                for: indexPath
            ) as! BHFigureOutgoingBubbleCell
        cell.configure(text: line)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        outgoingLine != nil ? CGFloat.leastNonzeroMagnitude : kScaleW(120)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if outgoingLine != nil {
            return nil
        }
        let footer = UIView()
        footer.backgroundColor = .clear
        let hint = UILabel()
        hint.text = "你已向对方发起会话，本条消息对方阅读后可能不会立即回复。\n向对方发送第一句话吧（仅一条）。"
        hint.font = .bh_pingFang(size: kScaleW(13), weight: .regular)
        hint.textColor = .kHexColor(hexString: "#888888")
        hint.textAlignment = .center
        hint.numberOfLines = 5
        hint.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(hint)
        NSLayoutConstraint.activate([
            hint.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: kScaleW(28)),
            hint.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -kScaleW(28)),
            hint.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
        ])
        return footer
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if BHFigureChatHistoryStore.hasSent(for: figureId) {
            view.cd_showDefaultToast("请等待对方回复后再发送")
            textField.resignFirstResponder()
            return true
        }
        if trimmedInput().isEmpty {
            textField.resignFirstResponder()
            return true
        }
        sendButtonTapped()
        return true
    }
}

// MARK: - 右侧气泡 Cell

private final class BHFigureOutgoingBubbleCell: UITableViewCell {

    static let reuseId = "BHFigureOutgoingBubbleCell"

    private let bubble = UIView()

    private let bodyLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        bubble.backgroundColor = .kHexColor(hexString: "#A6F500")
        bubble.layer.cornerRadius = kScaleW(14)
        bubble.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner,
            .layerMinXMaxYCorner,
        ]
        bubble.layer.masksToBounds = true

        bodyLabel.font = .bh_pingFang(size: kScaleW(15), weight: .regular)
        bodyLabel.textColor = .black
        bodyLabel.numberOfLines = 0

        bubble.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(bubble)
        bubble.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            bubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: kScaleW(56)),
            bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -kScaleW(14)),
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: kScaleW(12)),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -kScaleW(4)),
            bubble.widthAnchor.constraint(lessThanOrEqualToConstant: kScaleW(274)),

            bodyLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: kScaleW(10)),
            bodyLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: kScaleW(14)),
            bodyLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -kScaleW(14)),
            bodyLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -kScaleW(10)),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String) {
        bodyLabel.text = text
    }
}
