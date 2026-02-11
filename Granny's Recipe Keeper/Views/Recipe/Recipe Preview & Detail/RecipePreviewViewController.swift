//
//  RecipePreviewViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

@available(iOS 13.0, *)
class RecipePreviewViewController: UIViewController, RecipeInfoDisplayable, RecipeImageLoadable {

    private let recipe: Recipe

    private let apiRecipe: APIRecipe?

    weak var delegate: CategoriesSelectionViewControllerDelegate?

    private var savedRecipe: Recipe?

    private var isFavorite: Bool = false

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemBackground
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()

    private let recipeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.tintColor = .systemGray
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    let recipeInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let ingredientsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.text = "Ingredients:"
        return label
    }()

    private let ingredientsTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 14)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    private let instructionsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.text = "Instructions:"
        return label
    }()

    private let instructionsTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 14)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Add Recipe", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.systemBlue.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3
        button.addTarget(self, action: #selector(didTapAddButton), for: .touchUpInside)
        return button
    }()

    init(recipe: Recipe, apiRecipe: APIRecipe? = nil) {
        self.recipe = recipe
        self.apiRecipe = apiRecipe
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfRecipeExists()
        setupView()
        setupNavigationBar()
        setupLayout()
        configure()
    }

    private func checkIfRecipeExists() {
        let allRecipes = RecipesRepository.shared.getAllRecipes()
        if let existingRecipe = allRecipes.first(where: { $0.name == recipe.name }) {
            savedRecipe = existingRecipe
            isFavorite = existingRecipe.isFavorite
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.backgroundColor = .systemBackground
        scrollView.backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground

        if let navController = navigationController {
            navController.view.backgroundColor = .systemBackground
            navController.navigationBar.backgroundColor = .systemBackground
        }
    }

    private func setupView() {
        view.backgroundColor = .systemBackground

        addButton.isHidden = apiRecipe == nil
    }

    private lazy var favoriteButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: isFavorite ? "heart.fill" : "heart"),
            style: .plain,
            target: self,
            action: #selector(didTapFavoriteButton)
        )
        button.tintColor = isFavorite ? .systemRed : .label
        return button
    }()

    private func setupNavigationBar() {
        if navigationController == nil || navigationController?.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"),
                style: .plain,
                target: self,
                action: #selector(didTapBack)
            )
        }

        navigationItem.rightBarButtonItem = favoriteButton
    }

    @objc private func didTapFavoriteButton() {
        if let saved = savedRecipe {
            RecipesRepository.shared.toggleFavorite(saved)
            if let updatedRecipe = RecipesRepository.shared.getRecipe(by: saved.id) {
                savedRecipe = updatedRecipe
                isFavorite = updatedRecipe.isFavorite
                updateFavoriteButton()
            }
        } else {
            isFavorite.toggle()

            let recipeToSave: Recipe

            if let apiRecipe = apiRecipe {
                let allCategories = RecipesRepository.shared.getAllCategories()
                let defaultCategory = allCategories.first
                let convertedRecipe = RecipesAPIService.shared.convertToRecipe(apiRecipe, categories: defaultCategory != nil ? [defaultCategory!] : [])

                recipeToSave = Recipe(
                    id: convertedRecipe.id,
                    name: convertedRecipe.name,
                    recipeInstructions: convertedRecipe.recipeInstructions,
                    imageData: convertedRecipe.imageData,
                    imageURL: convertedRecipe.imageURL,
                    ingredients: convertedRecipe.ingredients,
                    categories: convertedRecipe.categories,
                    isArchived: false,
                    isFavorite: isFavorite,
                    createdAt: Date(),
                    cookingTime: convertedRecipe.cookingTime,
                    servings: convertedRecipe.servings,
                    difficulty: convertedRecipe.difficulty,
                    calories: convertedRecipe.calories,
                    tags: convertedRecipe.tags
                )
            } else {
                recipeToSave = Recipe(
                    id: recipe.id,
                    name: recipe.name,
                    recipeInstructions: recipe.recipeInstructions,
                    imageData: recipe.imageData,
                    imageURL: recipe.imageURL,
                    ingredients: recipe.ingredients,
                    categories: recipe.categories,
                    isArchived: recipe.isArchived,
                    isFavorite: isFavorite,
                    createdAt: recipe.createdAt,
                    cookingTime: recipe.cookingTime,
                    servings: recipe.servings,
                    difficulty: recipe.difficulty,
                    calories: recipe.calories,
                    tags: recipe.tags
                )
            }

            RecipesRepository.shared.saveRecipe(recipeToSave)

            if let updatedRecipe = RecipesRepository.shared.getAllRecipes().first(where: { $0.name == recipeToSave.name }) {
                savedRecipe = updatedRecipe
                isFavorite = updatedRecipe.isFavorite
            }

            updateFavoriteButton()
        }
    }

    private func updateFavoriteButton() {
        favoriteButton.image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")
        favoriteButton.tintColor = isFavorite ? .systemRed : .label
    }

    @objc private func didTapBack() {
        if let navController = navigationController, navController.viewControllers.count > 1 {
            navController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(recipeImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(ingredientsLabel)
        contentView.addSubview(ingredientsTextView)
        contentView.addSubview(instructionsLabel)
        contentView.addSubview(instructionsTextView)
        contentView.addSubview(recipeInfoLabel)
        contentView.addSubview(addButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            recipeImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            recipeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            recipeImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            recipeImageView.heightAnchor.constraint(equalToConstant: 200),

            nameLabel.topAnchor.constraint(equalTo: recipeImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            ingredientsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 16),
            ingredientsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ingredientsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            ingredientsTextView.topAnchor.constraint(equalTo: ingredientsLabel.bottomAnchor, constant: 8),
            ingredientsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ingredientsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            instructionsLabel.topAnchor.constraint(equalTo: ingredientsTextView.bottomAnchor, constant: 24),
            instructionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            instructionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            instructionsTextView.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 8),
            instructionsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            instructionsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            recipeInfoLabel.topAnchor.constraint(equalTo: instructionsTextView.bottomAnchor, constant: 16),
            recipeInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recipeInfoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            addButton.topAnchor.constraint(equalTo: recipeInfoLabel.bottomAnchor, constant: 20),
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 50),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    @objc private func didTapAddButton() {
        guard let apiRecipe = apiRecipe else { return }

        let categoriesVC = CategoriesSelectionViewController()
        categoriesVC.delegate = delegate
        categoriesVC.apiRecipe = apiRecipe
        navigationController?.pushViewController(categoriesVC, animated: true)
    }

    private func configure() {
        nameLabel.text = recipe.name

        // Используем протокол для загрузки изображения
        loadRecipeImage(recipe, into: recipeImageView)

        // Используем протокол для отображения информации о рецепте
        configureRecipeInfo(for: recipe)

        let ingredientsText = recipe.ingredients.map { $0.displayText }.joined(separator: "\n")
        ingredientsTextView.text = ingredientsText.isEmpty ? "No ingredients" : ingredientsText

        if let instructions = apiRecipe?.instructions, !instructions.isEmpty {
            instructionsTextView.text = instructions
        } else if let instructions = recipe.recipeInstructions, !instructions.isEmpty {
            instructionsTextView.text = instructions
        } else {
            instructionsTextView.text = "No instructions provided"
        }
    }

}
