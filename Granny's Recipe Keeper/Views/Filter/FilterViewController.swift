//
//  FilterViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

// ДЗ ТЕМА 32: ПОВЕДЕНЧЕСКИЕ ПАТТЕРНЫ. Observer.

import UIKit

// ДОМАШНЕЕ ЗАДАНИЕ ТЕМА 32: ПОВЕДЕНЧЕСКИЕ ПАТТЕРНЫ
// ПАТТЕРН 3: Наблюдатель через Delegate.
// FilterViewControllerDelegate уведомляет наблюдателей о применении фильтров. Когда пользователь применяет фильтры, все подписанные контроллеры обновляются. Слабая связанность, множественные наблюдатели.

protocol FilterViewControllerDelegate: AnyObject {
    func didApplyFilters(selectedTags: Set<String>, selectedDifficulty: String?)
}

class FilterViewController: UIViewController {
    
    weak var delegate: FilterViewControllerDelegate?
    
    private var allTags: [String] = []
    
    private var selectedTags: Set<String> = []
    
    private var selectedDifficulty: String?
    
    private var isDifficultyExpanded = false
    private var isTagsExpanded = false
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tableView
    }()
    
    private var difficultySegmentedControl: UISegmentedControl?
    
    private func createDifficultyControl() -> UISegmentedControl {
        let items = ["Easy", "Medium", "Hard"]
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(difficultyChanged(_:)), for: .valueChanged)
        
        if let difficulty = selectedDifficulty {
            switch difficulty.lowercased() {
            case "easy":
                control.selectedSegmentIndex = 0
            case "medium":
                control.selectedSegmentIndex = 1
            case "hard":
                control.selectedSegmentIndex = 2
            default:
                control.selectedSegmentIndex = UISegmentedControl.noSegment
            }
        } else {
            control.selectedSegmentIndex = UISegmentedControl.noSegment
        }
        
        return control
    }
    
    
    init(selectedTags: Set<String> = [], selectedDifficulty: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.selectedTags = selectedTags
        self.selectedDifficulty = selectedDifficulty
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        loadAllTags()
        setupLayout()
    }
    
    private func setupView() {
        view.backgroundColor = .systemGroupedBackground
        title = "Filters"
    }
    
    private func setupNavigationBar() {
        let clearButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(didTapClearButton)
        )
        
        let applyButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark"),
            style: .plain,
            target: self,
            action: #selector(didTapApplyButton)
        )
        
        navigationItem.rightBarButtonItems = [applyButton, clearButton]
        
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didTapCancelButton)
        )
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    private func setupLayout() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadAllTags() {
        allTags = TagsManager.shared.getAllTagsFromRecipes()
    }
    
    private func updateDifficultyControl() {
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }
    
    @objc private func difficultyChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedDifficulty = "easy"
        case 1:
            selectedDifficulty = "medium"
        case 2:
            selectedDifficulty = "hard"
        default:
            selectedDifficulty = nil
        }
    }
    
    @objc private func didTapApplyButton() {
        
        // ПАТТЕРН OBSERVER: Уведомление наблюдателей о применении фильтров
        delegate?.didApplyFilters(selectedTags: selectedTags, selectedDifficulty: selectedDifficulty)
        navigationController?.dismiss(animated: true)
    }
    
    @objc private func didTapCancelButton() {
        navigationController?.dismiss(animated: true)
    }
    
    @objc private func didTapClearButton() {
        selectedTags.removeAll()
        selectedDifficulty = nil
        difficultySegmentedControl?.selectedSegmentIndex = UISegmentedControl.noSegment
        tableView.reloadData()
        
        delegate?.didApplyFilters(selectedTags: selectedTags, selectedDifficulty: selectedDifficulty)
        navigationController?.dismiss(animated: true)
    }
}

extension FilterViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return isDifficultyExpanded ? 1 : 0
        case 1:
            return isTagsExpanded ? allTags.count : 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let titleLabel = UILabel()
        titleLabel.textColor = .secondaryLabel
        
        var isExpanded = false
        var sectionTitle = ""
        
        switch section {
        case 0:
            sectionTitle = "Difficulty"
            isExpanded = isDifficultyExpanded
        case 1:
            sectionTitle = "Tags"
            isExpanded = isTagsExpanded
        default:
            return nil
        }
        
        titleLabel.text = sectionTitle
        titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
        
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let chevronLabel = UILabel()
        chevronLabel.text = isExpanded ? "▼" : "▶"
        chevronLabel.font = .systemFont(ofSize: 12)
        chevronLabel.textColor = .secondaryLabel
        
        headerView.addSubview(chevronLabel)
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            chevronLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            chevronLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSectionHeader(_:)))
        headerView.addGestureRecognizer(tapGesture)
        headerView.tag = section
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    @objc private func didTapSectionHeader(_ gesture: UITapGestureRecognizer) {
        guard let headerView = gesture.view else { return }
        let section = headerView.tag
        
        switch section {
        case 0:
            isDifficultyExpanded.toggle()
        case 1:
            isTagsExpanded.toggle()
        default:
            return
        }
        
        tableView.reloadSections([section], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        switch indexPath.section {
        case 0:
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
            
            let control = createDifficultyControl()
            difficultySegmentedControl = control
            cell.contentView.addSubview(control)
            cell.selectionStyle = .none
            
            NSLayoutConstraint.activate([
                control.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                control.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                control.widthAnchor.constraint(equalToConstant: 250),
                control.heightAnchor.constraint(equalToConstant: 32)
            ])
            
            return cell
            
        case 1:
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
            
            let tag = allTags[indexPath.row]
            cell.textLabel?.text = tag
            cell.textLabel?.font = .systemFont(ofSize: 17)
            cell.accessoryType = selectedTags.contains(tag) ? .checkmark : .none
            cell.selectionStyle = .default
            
            return cell
            
        default:
            return cell
        }
    }
}

extension FilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row < allTags.count {
            let tag = allTags[indexPath.row]
            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 60
        }
        return UITableView.automaticDimension
    }
}
