//
//  RecipeDetailViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

protocol RecipeDetailViewControllerDelegate: AnyObject {
    func didUpdateRecipe()
    func didDeleteRecipe()
}

class RecipeDetailViewController: UIViewController {
    
    private var recipe: Recipe
    
    weak var delegate: RecipeDetailViewControllerDelegate?
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
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
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private let ingredientsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.text = "Ingredients:"
        return label
    }()
    
    private let ingredientsTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        return textView
    }()
    
    private let instructionsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.text = "Instructions:"
        return label
    }()
    
    private let instructionsTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        return textView
    }()
    
    private let categoriesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.text = "Categories:"
        return label
    }()
    
    private let categoriesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.alignment = .leading
        return stackView
    }()
    
    private let tagsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.text = "Tags:"
        return label
    }()
    
    private let tagsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.alignment = .leading
        return stackView
    }()
    
    private lazy var cameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(scale: .large), forImageIn: .normal)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(didTapCameraButton), for: .touchUpInside)
        return button
    }()
    
    init(recipe: Recipe) {
        self.recipe = recipe
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        setupLayout()
        configure()
    }
    
    @objc private func didTapCameraButton() {
        presentImagePicker()
    }
    
    private let transitionDelegate = TransitionDelegate()
    
    @objc private func didTapEditButton() {
        let editVC = RecipeEditViewController(recipe: recipe)
        editVC.delegate = self
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    @objc private func didTapDeleteButton() {
        let alert = UIAlertController(
            title: "Delete recipe?",
            message: "Recipe will be moved to archive",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            RecipesRepository.shared.archiveRecipe(self.recipe)
            self.delegate?.didDeleteRecipe()
            self.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func presentImagePicker() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            })
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .photoLibrary)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Search Unsplash", style: .default) { [weak self] _ in
            self?.presentUnsplashSearch()
        })
        
        if recipe.imageData != nil || (recipe.imageURL != nil && !recipe.imageURL!.isEmpty) {
            alert.addAction(UIAlertAction(title: "Delete Photo", style: .destructive) { [weak self] _ in
                self?.deletePhoto()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = cameraButton
            popover.sourceRect = cameraButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func deletePhoto() {
        var updatedRecipe = recipe
        updatedRecipe.imageData = nil
        updatedRecipe.imageURL = nil
        RecipesRepository.shared.saveRecipe(updatedRecipe)
        recipe = updatedRecipe
        configure()
        delegate?.didUpdateRecipe()
    }
    
    private func presentUnsplashSearch() {
        let searchQuery = recipe.name
        let searchVC = UnsplashImageSearchViewController(searchQuery: searchQuery)
        searchVC.delegate = self
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        title = ""
    }
    
    private lazy var favoriteButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: recipe.isFavorite ? "heart.fill" : "heart"),
            style: .plain,
            target: self,
            action: #selector(didTapFavoriteButton)
        )
        button.tintColor = recipe.isFavorite ? .systemRed : .label
        return button
    }()
    
    private func setupNavigationBar() {
        let copyButton = UIBarButtonItem(
            image: UIImage(systemName: "doc.on.doc"),
            style: .plain,
            target: self,
            action: #selector(didTapCopyRecipeButton)
        )
        
        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(didTapEditButton)
        )
        
        navigationItem.rightBarButtonItems = [
            editButton,
            favoriteButton,
            copyButton
        ]
    }
    
    @objc private func didTapFavoriteButton() {
        RecipesRepository.shared.toggleFavorite(recipe)
        
        if let updatedRecipe = RecipesRepository.shared.getRecipe(by: recipe.id) {
            recipe = updatedRecipe
            updateFavoriteButton()
            delegate?.didUpdateRecipe()
        }
    }
    
    private func updateFavoriteButton() {
        favoriteButton.image = UIImage(systemName: recipe.isFavorite ? "heart.fill" : "heart")
        favoriteButton.tintColor = recipe.isFavorite ? .systemRed : .label
    }
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(recipeImageView)
        contentView.addSubview(cameraButton)
        contentView.addSubview(nameLabel)
        contentView.addSubview(ingredientsLabel)
        contentView.addSubview(ingredientsTextView)
        contentView.addSubview(instructionsLabel)
        contentView.addSubview(instructionsTextView)
        contentView.addSubview(categoriesLabel)
        contentView.addSubview(categoriesStackView)
        contentView.addSubview(tagsLabel)
        contentView.addSubview(tagsStackView)
        
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
            recipeImageView.heightAnchor.constraint(equalToConstant: 300),
            
            cameraButton.trailingAnchor.constraint(equalTo: recipeImageView.trailingAnchor, constant: -16),
            cameraButton.bottomAnchor.constraint(equalTo: recipeImageView.bottomAnchor, constant: -16),
            cameraButton.widthAnchor.constraint(equalToConstant: 40),
            cameraButton.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: recipeImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            ingredientsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
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
            
            categoriesLabel.topAnchor.constraint(equalTo: instructionsTextView.bottomAnchor, constant: 24),
            categoriesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoriesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            categoriesStackView.topAnchor.constraint(equalTo: categoriesLabel.bottomAnchor, constant: 8),
            categoriesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoriesStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            tagsLabel.topAnchor.constraint(equalTo: categoriesStackView.bottomAnchor, constant: 24),
            tagsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tagsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            tagsStackView.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: 8),
            tagsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tagsStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            tagsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func configure() {
        nameLabel.text = recipe.name
        
        if let image = recipe.image {
            recipeImageView.image = image
            recipeImageView.backgroundColor = .clear
        } else if let imageURL = recipe.imageURL, !imageURL.isEmpty {
            RecipesAPIService.shared.loadImage(from: imageURL) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let image):
                        self?.recipeImageView.image = image
                        self?.recipeImageView.backgroundColor = .clear
                    case .failure:
                        self?.recipeImageView.image = UIImage(named: "default")
                        self?.recipeImageView.backgroundColor = .secondarySystemBackground
                    }
                }
            }
        } else {
            recipeImageView.image = UIImage(named: "default")
            recipeImageView.backgroundColor = .secondarySystemBackground
        }
        
        let ingredientsText = recipe.ingredients.map { $0.displayText }.joined(separator: "\n")
        ingredientsTextView.text = ingredientsText.isEmpty ? "No ingredients" : ingredientsText
        
        instructionsTextView.text = recipe.recipeInstructions ?? "No instructions"
        
        categoriesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if !recipe.categories.isEmpty {
            categoriesLabel.isHidden = false
            createWrappingBadges(items: recipe.categories.map { $0.name },
                                 stackView: categoriesStackView,
                                 badgeCreator: createCategoryBadge)
        } else {
            categoriesLabel.isHidden = true
        }
        
        if !recipe.tags.isEmpty {
            tagsLabel.isHidden = false
            createWrappingBadges(items: recipe.tags,
                                 stackView: tagsStackView,
                                 badgeCreator: createTagBadge)
        } else {
            tagsLabel.isHidden = true
        }
    }
    
    private func createWrappingBadges(items: [String],
                                      stackView: UIStackView,
                                      badgeCreator: (String) -> UIView) {
        let screenWidth = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        let availableWidth = screenWidth - 32 - 32
        let spacing: CGFloat = 8
        
        var currentRowStackView: UIStackView?
        var currentRowWidth: CGFloat = 0
        
        for item in items {
            let badge = badgeCreator(item)
            badge.setContentHuggingPriority(.required, for: .horizontal)
            badge.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            let font = UIFont.systemFont(ofSize: 14, weight: .medium)
            let attributes = [NSAttributedString.Key.font: font]
            let estimatedWidth = (item as NSString).size(withAttributes: attributes).width + 24 + spacing
            
            if currentRowStackView == nil || (currentRowWidth + estimatedWidth > availableWidth && currentRowWidth > 0) {
                currentRowStackView = UIStackView()
                currentRowStackView!.translatesAutoresizingMaskIntoConstraints = false
                currentRowStackView!.axis = .horizontal
                currentRowStackView!.spacing = spacing
                currentRowStackView!.distribution = .fill
                currentRowStackView!.alignment = .leading
                stackView.addArrangedSubview(currentRowStackView!)
                currentRowWidth = 0
            }
            
            currentRowStackView!.addArrangedSubview(badge)
            currentRowWidth += estimatedWidth
        }
    }
    
    private func createCategoryBadge(categoryName: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemBlue.cgColor
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = categoryName
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        label.numberOfLines = 1
        
        containerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6)
        ])
        
        return containerView
    }
    
    private func createTagBadge(tagName: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = tagName
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 1
        
        containerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6)
        ])
        
        return containerView
    }
    
    @objc private func didTapCopyRecipeButton() {
        var recipeText = recipe.name + "\n\n"
        
        if !recipe.ingredients.isEmpty {
            recipeText += "Ingredients:\n"
            recipeText += recipe.ingredients.map { $0.displayText }.joined(separator: "\n")
            recipeText += "\n\n"
        }
        
        if let instructions = recipe.recipeInstructions, !instructions.isEmpty {
            recipeText += "Instructions:\n" + instructions
        }
        
        UIPasteboard.general.string = recipeText
        
        let alert = UIAlertController(title: nil, message: "Recipe copied to clipboard", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension RecipeDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let editedImage = info[.editedImage] as? UIImage
        let originalImage = info[.originalImage] as? UIImage
        let selectedImage = editedImage ?? originalImage
        
        if let image = selectedImage {
            recipeImageView.image = image
            recipeImageView.backgroundColor = .clear
            
            var updatedRecipe = recipe
            updatedRecipe.imageData = image.jpegData(compressionQuality: 0.8)
            RecipesRepository.shared.saveRecipe(updatedRecipe)
            recipe = updatedRecipe
            delegate?.didUpdateRecipe()
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension RecipeDetailViewController: RecipeEditViewControllerDelegate {
    func didSaveRecipe() {
        if let updatedRecipe = RecipesRepository.shared.getRecipe(by: recipe.id) {
            recipe = updatedRecipe
            configure()
            updateFavoriteButton()
            delegate?.didUpdateRecipe()
        }
    }
}

extension RecipeDetailViewController: UnsplashImageSearchViewControllerDelegate {
    func didSelectImage(image: UIImage, imageURL: String) {
        recipeImageView.image = image
        recipeImageView.backgroundColor = .clear
        
        var updatedRecipe = recipe
        updatedRecipe.imageData = image.jpegData(compressionQuality: 0.8)
        updatedRecipe.imageURL = imageURL
        RecipesRepository.shared.saveRecipe(updatedRecipe)
        recipe = updatedRecipe
        delegate?.didUpdateRecipe()
    }
}

