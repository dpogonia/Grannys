//
//  UnsplashImageSearchViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

protocol UnsplashImageSearchViewControllerDelegate: AnyObject {
    func didSelectImage(image: UIImage, imageURL: String)
}

class UnsplashImageSearchViewController: UIViewController {
    
    weak var delegate: UnsplashImageSearchViewControllerDelegate?
    private let searchQuery: String
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search images"
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.register(UnsplashImageCell.self, forCellWithReuseIdentifier: "UnsplashImageCell")
        return collectionView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No images found"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private var photos: [UnsplashPhoto] = []
    private var isLoading = false
    
    init(searchQuery: String) {
        self.searchQuery = searchQuery
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
        setupCollectionView()
        setupSearchBar()
        performSearch(query: searchQuery)
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        title = "Search Images"
        
    }
    
    private func setupLayout() {
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.text = searchQuery
    }
    
    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        activityIndicator.startAnimating()
        emptyStateLabel.isHidden = true
        photos = []
        collectionView.reloadData()
        
        RecipesAPIService.shared.searchUnsplashImages(query: query) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let photos):
                    self?.photos = photos
                    self?.emptyStateLabel.isHidden = !photos.isEmpty
                    self?.collectionView.reloadData()
                case .failure(let error):
                    print("Unsplash search error: \(error.localizedDescription)")
                    self?.emptyStateLabel.isHidden = false
                    let errorMessage: String
                    if let nsError = error as NSError?, nsError.code == 401 {
                        errorMessage = "Unsplash API key required.\nGet a free key at https://unsplash.com/developers\nand add it to RecipesAPIService.swift"
                    } else {
                        errorMessage = "Failed to load images. Check your internet connection."
                    }
                    self?.showError(message: errorMessage)
                }
            }
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension UnsplashImageSearchViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UnsplashImageCell", for: indexPath) as! UnsplashImageCell
        let photo = photos[indexPath.item]
        cell.configure(with: photo)
        return cell
    }
}

extension UnsplashImageSearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = photos[indexPath.item]
        let imageURL = photo.urls.regular
        
        activityIndicator.startAnimating()
        RecipesAPIService.shared.loadImage(from: imageURL) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let image):
                    self?.delegate?.didSelectImage(image: image, imageURL: imageURL)
                    self?.navigationController?.popViewController(animated: true)
                case .failure:
                    self?.showError(message: "Failed to load image")
                }
            }
        }
    }
}

extension UnsplashImageSearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 8
        let spacing: CGFloat = 8
        let width = (collectionView.bounds.width - padding * 2 - spacing) / 2
        return CGSize(width: width, height: width * 1.2)
    }
}

extension UnsplashImageSearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let query = searchBar.text {
            performSearch(query: query)
        }
    }
}

class UnsplashImageCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private var currentLoadOperation: Operation?
    
    func configure(with photo: UnsplashPhoto) {
        imageView.image = nil
        currentLoadOperation?.cancel()
        currentLoadOperation = nil
        
        let thumbnailURL = photo.urls.small
        
        currentLoadOperation = ImageLoadQueueManager.shared.loadImage(urlString: thumbnailURL) { [weak self] result in
            guard let self = self else { return }
            
            if case .success(let image) = result {
                self.imageView.image = image
            }
            
            self.currentLoadOperation = nil
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Отмена загрузки при переиспользовании ячейки
        currentLoadOperation?.cancel()
        currentLoadOperation = nil
        
        imageView.image = nil
    }
}
