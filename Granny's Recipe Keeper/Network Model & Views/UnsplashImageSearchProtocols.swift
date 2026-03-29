
import UIKit

protocol UnsplashImageSearchViewControllerDelegate: AnyObject {
    func didSelectImage(image: UIImage, imageURL: String)
}
