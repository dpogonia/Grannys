//
//  FilterViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit
import UniformTypeIdentifiers

class FilterViewController: UIViewController {
    
    weak var delegate: FilterViewControllerDelegate?
    
    private var allTags: [String] = []
    
    private var selectedTags: Set<String> = []
    
    private var selectedDifficulty: String?
    
    private var allIngredients: [String] = []
    private var selectedIngredients: Set<String> = []
    
    private var isDifficultyExpanded = false
    private var isTagsExpanded = false
    private var isIngredientsExpanded = false
    private var isTranslationExpanded = false
    private var isDataExpanded = false
    private var isAppLanguageExpanded = false
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private var difficultySegmentedControl: UISegmentedControl?
    
    private func createDifficultyControl() -> UISegmentedControl {
        let items = [
            tr("settings_difficulty_easy"),
            tr("settings_difficulty_medium"),
            tr("settings_difficulty_hard")
        ]
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
    
    
    init(selectedTags: Set<String> = [], selectedDifficulty: String? = nil, selectedIngredients: Set<String> = []) {
        super.init(nibName: nil, bundle: nil)

        // ПАТТЕРН MEMENTO: Восстановление сохраненного состояния фильтров
        if let memento = FilterCaretaker.shared.restoreFilterState() {
            self.selectedTags = memento.tagsSet
            self.selectedDifficulty = memento.selectedDifficulty
            self.selectedIngredients = memento.ingredientsSet
        } else {
            self.selectedTags = selectedTags
            self.selectedDifficulty = selectedDifficulty
            self.selectedIngredients = selectedIngredients
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        setupTableView()
        loadAllTags()
        loadAllIngredients()
        setupLayout()
    }
    
    private var availableLanguages: [AppLanguage] = AppLanguage.allCases
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tintColor = .grannyPink
    }
    
    private func setupView() {
        view.backgroundColor = .systemGroupedBackground
        title = tr("settings_title")
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
        clearButton.tintColor = .grannyPink
        applyButton.tintColor = .grannyPink
        
        // Справа оставляем только кнопку применения настроек
        navigationItem.rightBarButtonItem = applyButton
        
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
    
    private func loadAllIngredients() {
        // Используем локальные рецепты, чтобы список ингредиентов появлялся сразу и работал оффлайн
        let recipes = RecipesRepository.shared.getAllRecipes()
        
        var namesSet = Set<String>()
        for recipe in recipes {
            for ingredient in recipe.ingredients {
                let trimmed = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                namesSet.insert(trimmed)
            }
        }
        
        allIngredients = Array(namesSet).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        tableView.reloadData()
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
        // ПАТТЕРН MEMENTO: Сохранение состояния фильтров
        let memento = FilterMemento(
            selectedTags: selectedTags,
            selectedDifficulty: selectedDifficulty,
            selectedIngredients: selectedIngredients
        )
        FilterCaretaker.shared.saveFilterState(memento: memento)

        // ПАТТЕРН OBSERVER: Уведомление наблюдателей о применении фильтров
        delegate?.didApplyFilters(selectedTags: selectedTags, selectedDifficulty: selectedDifficulty, selectedIngredients: selectedIngredients)
        navigationController?.dismiss(animated: true)
    }
    
    @objc private func didTapCancelButton() {
        navigationController?.dismiss(animated: true)
    }
    
    @objc private func didTapClearButton() {
        selectedTags.removeAll()
        selectedIngredients.removeAll()
        selectedDifficulty = nil
        difficultySegmentedControl?.selectedSegmentIndex = UISegmentedControl.noSegment
        tableView.reloadData()

        // ПАТТЕРН MEMENTO: Очистка сохраненного состояния фильтров
        FilterCaretaker.shared.clearFilterState()

        delegate?.didApplyFilters(selectedTags: selectedTags, selectedDifficulty: selectedDifficulty, selectedIngredients: selectedIngredients)
        navigationController?.dismiss(animated: true)
    }
    
    private enum DataExportFormat {
        case json
        case csv
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tr("common_ok"), style: .default))
        present(alert, animated: true)
    }
    
    private func exportRecipes(as format: DataExportFormat) {
        let activeRecipes = RecipesRepository.shared.getAllRecipes(archived: false)
        let archivedRecipes = RecipesRepository.shared.getAllRecipes(archived: true)
        let allRecipes = activeRecipes + archivedRecipes
        
        guard !allRecipes.isEmpty else {
            showAlert(title: tr("export_nothing_title"), message: tr("export_nothing_message"))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            
            do {
                let url: URL
                switch format {
                case .json:
                    url = try RecipeExportImportService.exportRecipesToJSON(allRecipes)
                case .csv:
                    url = try RecipeExportImportService.exportRecipesToCSV(allRecipes)
                }
                
                DispatchQueue.main.async {
                    self.presentShareSheet(for: url)
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(title: tr("export_failed_title"), message: error.localizedDescription)
                }
            }
        }
    }
    
    private func presentShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(activityVC, animated: true)
    }
    
    private func presentImportPicker() {
        if #available(iOS 14.0, *) {
            var types: [UTType] = [UTType.json]
            types.append(UTType.commaSeparatedText)
            types.append(UTType.plainText)
            
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
            picker.delegate = self
            picker.allowsMultipleSelection = false
            present(picker, animated: true)
        } else {
            let types = ["public.json", "public.comma-separated-values-text", "public.text"]
            let picker = UIDocumentPickerViewController(documentTypes: types, in: .import)
            picker.delegate = self
            picker.allowsMultipleSelection = false
            present(picker, animated: true)
        }
    }
    
    private func importRecipes(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            
            var importedRecipes: [Recipe] = []
            
            do {
                let ext = url.pathExtension.lowercased()
                if ext == "json" {
                    importedRecipes = try RecipeExportImportService.importRecipes(fromJSONAt: url)
                } else {
                    importedRecipes = try RecipeExportImportService.importRecipes(fromCSVAt: url)
                }
                
                for recipe in importedRecipes {
                    RecipesRepository.shared.saveRecipe(recipe)
                }
                
                DispatchQueue.main.async {
                    let count = importedRecipes.count
                    let message: String
                    if count == 1 {
                        message = tr("import_completed_single")
                    } else {
                        message = String(format: tr("import_completed_many"), count)
                    }
                    self.showAlert(title: tr("import_completed_title"), message: message)
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(title: tr("import_failed_title"), message: error.localizedDescription)
                }
            }
        }
    }
}

extension FilterViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // 0: Difficulty, 1: Tags, 2: Ingredients, 3: Translation, 4: Data, 5: App language
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return isDifficultyExpanded ? 1 : 0
        case 1:
            return isTagsExpanded ? allTags.count : 0
        case 2:
            return isIngredientsExpanded ? allIngredients.count : 0
        case 3:
            return isTranslationExpanded ? availableLanguages.count : 0
        case 4:
            return isDataExpanded ? 3 : 0
        case 5:
            // Переключатель языка UI: EN / RU
            return isAppLanguageExpanded ? 2 : 0
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
            sectionTitle = tr("settings_section_difficulty")
            isExpanded = isDifficultyExpanded
        case 1:
            sectionTitle = tr("settings_section_tags")
            isExpanded = isTagsExpanded
        case 2:
            sectionTitle = tr("settings_section_ingredients")
            isExpanded = isIngredientsExpanded
        case 3:
            sectionTitle = tr("settings_section_translation")
            isExpanded = isTranslationExpanded
        case 4:
            sectionTitle = tr("settings_section_data")
            isExpanded = isDataExpanded
        case 5:
            sectionTitle = tr("settings_section_app_language")
            isExpanded = isAppLanguageExpanded
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
        case 2:
            isIngredientsExpanded.toggle()
        case 3:
            isTranslationExpanded.toggle()
        case 4:
            isDataExpanded.toggle()
        case 5:
            isAppLanguageExpanded.toggle()
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
            
        case 2:
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
            
            let ingredient = allIngredients[indexPath.row]
            cell.textLabel?.text = ingredient
            cell.textLabel?.font = .systemFont(ofSize: 17)
            cell.accessoryType = selectedIngredients.contains(ingredient) ? .checkmark : .none
            cell.selectionStyle = .default
            
            return cell
            
        case 3:
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
            
            let language = availableLanguages[indexPath.row]
            cell.textLabel?.text = language.displayName
            cell.textLabel?.font = .systemFont(ofSize: 17)
            
            let current = TranslationSettings.shared.preferredLanguage
            cell.accessoryType = (language == current) ? .checkmark : .none
            cell.selectionStyle = .default
            
            return cell
            
        case 4:
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = tr("settings_export_json")
            case 1:
                cell.textLabel?.text = tr("settings_export_csv")
            case 2:
                cell.textLabel?.text = tr("settings_import")
            default:
                break
            }
            
            return cell
            
        case 5:
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
            cell.selectionStyle = .default
            
            let uiLanguages: [AppLanguage] = [.english, .russian]
            guard indexPath.row < uiLanguages.count else { return cell }
            let lang = uiLanguages[indexPath.row]
            cell.textLabel?.text = lang.displayName
            cell.textLabel?.font = .systemFont(ofSize: 17)
            
            let current = LocalizationManager.shared.currentLanguage
            cell.accessoryType = (lang == current) ? .checkmark : .none
            
            return cell
            
        default:
            return cell
        }
    }
}

extension FilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Haptics.selection()
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row < allTags.count {
            let tag = allTags[indexPath.row]
            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
        } else if indexPath.section == 2 && indexPath.row < allIngredients.count {
            let ingredient = allIngredients[indexPath.row]
            if selectedIngredients.contains(ingredient) {
                selectedIngredients.remove(ingredient)
            } else {
                selectedIngredients.insert(ingredient)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
        } else if indexPath.section == 3 && indexPath.row < availableLanguages.count {
            let selectedLanguage = availableLanguages[indexPath.row]
            TranslationSettings.shared.preferredLanguage = selectedLanguage
            
            // Обновляем чекмарки для всех языков
            var indexPaths: [IndexPath] = []
            for row in 0..<availableLanguages.count {
                indexPaths.append(IndexPath(row: row, section: 3))
            }
            tableView.reloadRows(at: indexPaths, with: .none)
        } else if indexPath.section == 4 {
            switch indexPath.row {
            case 0:
                exportRecipes(as: .json)
            case 1:
                exportRecipes(as: .csv)
            case 2:
                presentImportPicker()
            default:
                break
            }
        } else if indexPath.section == 5 {
            let uiLanguages: [AppLanguage] = [.english, .russian]
            guard indexPath.row < uiLanguages.count else { return }
            
            LocalizationManager.shared.currentLanguage = uiLanguages[indexPath.row]
            
            // Обновляем заголовок и секции, зависящие от языка UI
            title = tr("settings_title")
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 60
        }
        return UITableView.automaticDimension
    }
}

extension FilterViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        importRecipes(from: url)
        if shouldStopAccessing {
            url.stopAccessingSecurityScopedResource()
        }
    }
}

