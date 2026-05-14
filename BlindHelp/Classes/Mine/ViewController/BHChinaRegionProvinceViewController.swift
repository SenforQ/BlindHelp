//
//  BHChinaRegionProvinceViewController.swift
//  BlindHelp
//

import UIKit

/// 第一层：列出全国省级行政区，进入市列表。
final class BHChinaRegionProvinceViewController: BHBaseViewController, UITableViewDataSource, UITableViewDelegate {

    private let provinces = BHChinaRegionLoader.provincesSnapshot
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    /// `(省名, 市名)`。
    var onProvinceCityPicked: ((String, String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .kHexColor(hexString: "#F7F7F7")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "c")
        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "选择省份"
        kdNavBar.navTitleLab.text = "选择省份"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(
            x: 0,
            y: kNavBarFullHeight,
            width: view.bounds.width,
            height: view.bounds.height - kNavBarFullHeight
        )
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        provinces.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "c", for: indexPath)
        var conf = cell.defaultContentConfiguration()
        conf.text = provinces[indexPath.row].provinceName
        cell.contentConfiguration = conf
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let province = provinces[indexPath.row]
        let vc = BHChinaRegionCityViewController(province: province) { [weak self] prov, city in
            guard let self else { return }
            self.onProvinceCityPicked?(prov, city)
            Self.popFlowToMineEditor(from: self)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    /// 在市页回调后，`Province`/`City` VCs 均需回到上一层编辑页。
    static func popFlowToMineEditor(from current: UIViewController) {
        guard let nav = current.navigationController else { return }
        guard let mine = nav.viewControllers.reversed().first(where: { $0 is BHMineEditorInfoViewController }) else {
            nav.popToRootViewController(animated: true)
            return
        }
        nav.popToViewController(mine, animated: true)
    }
}
