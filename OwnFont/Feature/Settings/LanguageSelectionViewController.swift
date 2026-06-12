//
//  LanguageSelectionViewController.swift
//  OwnFont
//

import UIKit
import SnapKit

final class LanguageSelectionViewController: UIViewController {

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .background
        tv.separatorColor = .borderLight
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        navigationItem.title = L.settingsLanguage
        setupLayout()
        tableView.dataSource = self
        tableView.delegate   = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

// MARK: - UITableViewDataSource

extension LanguageSelectionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        LanguageManager.Language.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let language = LanguageManager.Language.allCases[indexPath.row]
        cell.textLabel?.text = language.displayName
        cell.textLabel?.font = .body
        cell.textLabel?.textColor = .textPrimary
        cell.backgroundColor = .surface
        cell.tintColor = .primary
        cell.accessoryType = language == LanguageManager.shared.current ? .checkmark : .none
        return cell
    }
}

// MARK: - UITableViewDelegate

extension LanguageSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let language = LanguageManager.Language.allCases[indexPath.row]
        guard language != LanguageManager.shared.current else { return }
        LanguageManager.shared.setLanguage(language)
    }
}
