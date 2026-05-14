//
//  BHChinaRegionCityViewController.swift
//  BlindHelp
//

import UIKit

/// 第二层：列出所选省名下的市（或同级名称）。
final class BHChinaRegionCityViewController: BHBaseViewController, UITableViewDataSource, UITableViewDelegate {

    private let province: BHProvinceSnapshot
    private let finished: (_ province: String, _ city: String) -> Void
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(province: BHProvinceSnapshot, finished: @escaping (_ province: String, _ city: String) -> Void) {
        self.province = province
        self.finished = finished
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        title = province.provinceName
        kdNavBar.navTitleLab.text = "选择\(province.provinceName)"
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
        province.cityNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "c", for: indexPath)
        var conf = cell.defaultContentConfiguration()
        conf.text = province.cityNames[indexPath.row]
        cell.contentConfiguration = conf
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cityName = province.cityNames[indexPath.row]
        finished(province.provinceName, cityName)
    }
}
