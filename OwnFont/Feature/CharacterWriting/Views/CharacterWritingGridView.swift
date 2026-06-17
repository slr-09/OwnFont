//
//  CharacterWritingGridView.swift
//  OwnFont
//

import Combine
import UIKit
import SnapKit

final class CharacterWritingGridView: UIView {

    // MARK: - Types
    enum Action {
        case back
        case clearAll
        case penSelected, eraserSelected
        case undo, clear
    }

    // MARK: - Publisher
    let actionPublisher = PassthroughSubject<Action, Never>()

    // MARK: - Nav Bar
    private let navBarView: UIView = {
        let v = UIView()
        v.backgroundColor = .surface
        return v
    }()

    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .surfaceSecondary
        btn.layer.cornerRadius = 18
        btn.tintColor = .textPrimary
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        return btn
    }()

    private let navTitleLabel: UILabel = {
        let l = UILabel()
        l.text = L.characterWritingTitle
        l.font = .cardHeader
        l.textColor = .textPrimary
        return l
    }()

    private let clearAllCategoryButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .surfaceSecondary
        btn.layer.cornerRadius = 18
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: "trash.slash", withConfiguration: cfg), for: .normal)
        btn.tintColor = .systemRed
        return btn
    }()

    private let counterBadge: UIView = {
        let v = UIView()
        v.backgroundColor = .indigoLight
        v.layer.cornerRadius = 12
        return v
    }()

    private let counterLabel: UILabel = {
        let l = UILabel()
        l.font = .caption
        l.textColor = .indigo
        return l
    }()

    // MARK: - Progress
    private let progressView = CategoryProgressView()

    // MARK: - Collection View
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .surface
        cv.alwaysBounceVertical = true
        cv.register(CharacterWritingGridCell.self, forCellWithReuseIdentifier: CharacterWritingGridCell.reuseID)
        return cv
    }()

    // MARK: - Tool Bar
    private let toolBarView: UIView = {
        let v = UIView()
        v.backgroundColor = .surface
        return v
    }()

    private lazy var penButton = makeToolButton(iconName: "pencil", isActive: true)
    private lazy var eraserButton = makeToolButton(iconName: "eraser")
    private lazy var undoButton = makeToolButton(iconName: "arrow.uturn.backward")
    private lazy var clearButton = makeToolButton(iconName: "trash")

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .surface
        setupLayout()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(navBarView)
        navBarView.addSubview(backButton)
        navBarView.addSubview(navTitleLabel)
        navBarView.addSubview(clearAllCategoryButton)
        navBarView.addSubview(counterBadge)
        counterBadge.addSubview(counterLabel)

        addSubview(progressView)
        addSubview(collectionView)
        addSubview(toolBarView)

        let toolsStack = UIStackView(arrangedSubviews: [penButton, eraserButton, undoButton, clearButton])
        toolsStack.spacing = 8
        toolBarView.addSubview(toolsStack)

        navBarView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(52)
        }
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }
        navTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        clearAllCategoryButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }
        counterBadge.snp.makeConstraints { make in
            make.trailing.equalTo(clearAllCategoryButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        counterLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        }

        toolBarView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(80)
        }
        toolsStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(16)
        }
        [penButton, eraserButton, undoButton, clearButton].forEach { btn in
            btn.snp.makeConstraints { make in make.size.equalTo(48) }
        }

        progressView.snp.makeConstraints { make in
            make.top.equalTo(navBarView.snp.bottom).offset(10)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(toolBarView.snp.top)
        }
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        clearAllCategoryButton.addTarget(self, action: #selector(handleClearAll), for: .touchUpInside)
        penButton.addTarget(self, action: #selector(handlePen), for: .touchUpInside)
        eraserButton.addTarget(self, action: #selector(handleEraser), for: .touchUpInside)
        undoButton.addTarget(self, action: #selector(handleUndo), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(handleClear), for: .touchUpInside)
    }

    @objc private func handleBack()      { actionPublisher.send(.back) }
    @objc private func handleClearAll()  { actionPublisher.send(.clearAll) }
    @objc private func handlePen()       { actionPublisher.send(.penSelected) }
    @objc private func handleEraser()    { actionPublisher.send(.eraserSelected) }
    @objc private func handleUndo()      { actionPublisher.send(.undo) }
    @objc private func handleClear()     { actionPublisher.send(.clear) }

    // MARK: - Public Interface
    func updateCounter(current: Int, total: Int) {
        counterLabel.text = "\(current) / \(total)"
    }

    func updateProgress(completed: Int, total: Int) {
        progressView.update(completed: completed, total: total)
    }

    func setActiveTool(isPen: Bool) {
        penButton.backgroundColor = isPen ? .primary : .surfaceSecondary
        penButton.tintColor = isPen ? .white : .iconInactive
        eraserButton.backgroundColor = isPen ? .surfaceSecondary : .primary
        eraserButton.tintColor = isPen ? .iconInactive : .white
    }

    // MARK: - Helper
    private func makeToolButton(iconName: String, isActive: Bool = false) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = isActive ? .primary : .surfaceSecondary
        btn.layer.cornerRadius = 16
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        btn.setImage(UIImage(systemName: iconName, withConfiguration: cfg), for: .normal)
        btn.tintColor = isActive ? .white : .iconInactive
        return btn
    }
}
