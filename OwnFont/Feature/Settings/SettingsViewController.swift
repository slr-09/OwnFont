//
//  SettingsViewController.swift
//  OwnFont

import UIKit
import SnapKit
import StoreKit

final class SettingsViewController: UIViewController {

    private static let appStoreID = "6762008881"
    private static let contactURL = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSf80vR1xE9waLX6KWGxY5pvSHv_ucNrjCkrHFAf2QcF5XvpHg/viewform")

    private enum Section: Int, CaseIterable {
        case general, support

        var title: String {
            switch self {
            case .general: return L.settingsSectionGeneral
            case .support: return L.settingsSectionSupport
            }
        }
    }

    private enum SupportRow: Int { case review, contact }

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
        navigationItem.title = L.settingsTitle
        setupLayout()
        tableView.dataSource = self
        tableView.delegate   = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Actions

    private func openReview() {
        if !Self.appStoreID.isEmpty,
           let url = URL(string: "https://apps.apple.com/app/id\(Self.appStoreID)?action=write-review") {
            UIApplication.shared.open(url)
        } else if let scene = view.window?.windowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func openContact() {
        guard let url = Self.contactURL else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .general: return 1
        case .support: return 2
        case .none:    return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .surface
        cell.textLabel?.font = .body
        cell.textLabel?.textColor = .textPrimary

        switch Section(rawValue: indexPath.section) {
        case .general:
            cell.textLabel?.text = L.settingsLanguage
            cell.accessoryType = .disclosureIndicator
        case .support:
            switch SupportRow(rawValue: indexPath.row) {
            case .review:
                cell.textLabel?.text = L.settingsReview
                cell.accessoryType = .disclosureIndicator
            case .contact:
                cell.textLabel?.text = L.settingsContact
                cell.accessoryType = .disclosureIndicator
            case .none:
                break
            }
        case .none:
            break
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section) {
        case .general:
            navigationController?.pushViewController(LanguageSelectionViewController(), animated: true)
        case .support:
            switch SupportRow(rawValue: indexPath.row) {
            case .review:  openReview()
            case .contact: openContact()
            case .none:    break
            }
        case .none:
            break
        }
    }
}
