//
//  FilterViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

// MARK: - FilterViewControllerDelegate
// Протокол для уведомления о применении фильтров
protocol FilterViewControllerDelegate: AnyObject {
    // Фильтры были применены
    // selectedTags - выбранные теги (например, {"вегетарианский", "без глютена"})
    // selectedDifficulty - выбранная сложность (nil = любая)
    func didApplyFilters(selectedTags: Set<String>, selectedDifficulty: String?)
}

// MARK: - FilterViewController
// FilterViewController - это экран для фильтрации рецептов
// Позволяет выбрать теги (вегетарианский, без глютена и т.д.) и сложность (легко, средне, сложно)
// После применения фильтров показываются только рецепты, соответствующие критериям
class FilterViewController: UIViewController {
    
    // Делегат для уведомления о применении фильтров
    weak var delegate: FilterViewControllerDelegate?
    
    // Все доступные теги из всех рецептов
    private var allTags: [String] = []
    
    // Выбранные теги для фильтрации (можно выбрать несколько)
    private var selectedTags: Set<String> = []
    
    // Выбранная сложность (nil = любая сложность)
    private var selectedDifficulty: String?
    
    // Состояние раскрытости секций (развёрнуты ли секции)
    // false = секция свёрнута (скрыта), true = развёрнута (видна)
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
    
    // ЗАГРУЗКА ВСЕХ ТЕГОВ ДЛЯ ФИЛЬТРАЦИИ
    // Используем глобальный TagsManager для получения всех тегов
    private func loadAllTags() {
        // Получаем все теги из глобального менеджера
        // Это включает:
        // - Стандартные теги (Vegetarian, Vegan и т.д.)
        // - Пользовательские теги (добавленные пользователем)
        // - Теги из всех рецептов
        allTags = TagsManager.shared.getAllTagsFromRecipes()
    }
    
    private func updateDifficultyControl() {
        // Обновление будет происходить при создании нового контрола
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
        delegate?.didApplyFilters(selectedTags: selectedTags, selectedDifficulty: selectedDifficulty)
        navigationController?.dismiss(animated: true)
    }
    
    @objc private func didTapCancelButton() {
        navigationController?.dismiss(animated: true)
    }
    
    // При сбросе фильтров окно должно закрываться автоматически
    @objc private func didTapClearButton() {
        // Очищаем все выбранные фильтры
        selectedTags.removeAll()
        selectedDifficulty = nil
        // Обновляем segmented control если он существует
        difficultySegmentedControl?.selectedSegmentIndex = UISegmentedControl.noSegment
        tableView.reloadData()
        
        // Применяем пустые фильтры и закрываем окно
        // Теперь не нужно нажимать галочку отдельно - окно закроется автоматически
        delegate?.didApplyFilters(selectedTags: selectedTags, selectedDifficulty: selectedDifficulty)
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FilterViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Difficulty section and Tags section
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Difficulty section
            return isDifficultyExpanded ? 1 : 0
        case 1: // Tags section
            return isTagsExpanded ? allTags.count : 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil // Используем кастомные headers
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
        
        // Добавляем стрелочку
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
        
        // Добавляем tap gesture для переключения состояния
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
        case 0: // Difficulty section
            // Очищаем ячейку перед добавлением segmented control
            // Проблема: когда ячейка переиспользуется из секции Tags, textLabel с текстом тега остаётся видимым и накладывается на segmented control поэтому очищаем все свойства ячейки перед настройкой
            
            // Удаляем все subviews (включая старые segmented controls, если есть)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            // Очищаем textLabel и detailTextLabel (чтобы текст тега не остался)
            // textLabel и detailTextLabel - это стандартные свойства UITableViewCell
            // Они могут содержать текст из предыдущего использования ячейки
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
            
            // Создаём новый segmented control для выбора сложности
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
            
        case 1: // Tags section
            // Очищаем ячейку перед настройкой
            // При переиспользовании ячеек нужно очищать все свойства иначе могут остаться элементы из предыдущего использования
            
            // Удаляем все subviews (на случай, если ячейка использовалась для segmented control)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            // Очищаем textLabel и detailTextLabel
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
            
            // Настраиваем ячейку для отображения тега
            let tag = allTags[indexPath.row]
            cell.textLabel?.text = tag
            cell.textLabel?.font = .systemFont(ofSize: 17)
            // Показываем галочку, если тег выбран
            cell.accessoryType = selectedTags.contains(tag) ? .checkmark : .none
            cell.selectionStyle = .default
            
            return cell
            
        default:
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
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
