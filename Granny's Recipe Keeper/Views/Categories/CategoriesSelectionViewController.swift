//
//  CategoriesSelectionViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

protocol CategoriesSelectionViewControllerDelegate: AnyObject {
    func didAddRecipe()
}

class CategoriesSelectionViewController: UIViewController {
    
    var apiRecipe: APIRecipe?
    
    weak var delegate: CategoriesSelectionViewControllerDelegate?
    
    private var allCategories: [Category] = []
    
    private var selectedCategories: Set<UUID> = []
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        loadCategories()
        setupTableView()
        setupConstraints()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        title = "Select Categories"
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(didTapSave)
        )
    }
    
    @objc private func didTapSave() {
        guard let apiRecipe = apiRecipe else {
            dismiss(animated: true)
            return
        }
        
        let categories = allCategories.filter { selectedCategories.contains($0.id) }
        
        let recipe = RecipesAPIService.shared.convertToRecipe(apiRecipe, categories: categories)
        
        if let imageURL = apiRecipe.image, !imageURL.isEmpty {
            
            RecipesAPIService.shared.loadImage(from: imageURL) { [weak self] result in
                DispatchQueue.main.async {
                    var finalRecipe = recipe
                    
                    if case .success(let image) = result {
                        finalRecipe.imageData = image.jpegData(compressionQuality: 0.8)
                    }
                    
                    RecipesRepository.shared.saveRecipe(finalRecipe)
                    
                    self?.delegate?.didAddRecipe()
                    
                    self?.navigationController?.popToRootViewController(animated: true)
                }
            }
        } else {
            RecipesRepository.shared.saveRecipe(recipe)
            delegate?.didAddRecipe()
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    private func loadCategories() {
        allCategories = RecipesRepository.shared.getAllCategories()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension CategoriesSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allCategories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let category = allCategories[indexPath.row]
        cell.textLabel?.text = category.name
        cell.accessoryType = selectedCategories.contains(category.id) ? .checkmark : .none
        return cell
    }
}

extension CategoriesSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let category = allCategories[indexPath.row]
        if selectedCategories.contains(category.id) {
            selectedCategories.remove(category.id)
        } else {
            selectedCategories.insert(category.id)
        }
        
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}
