//
//  UnsplashImageSearchProtocols.swift
//  Granny's Recipe Keeper
//
//  Protocols separated from implementation
//

import UIKit

protocol UnsplashImageSearchViewControllerDelegate: AnyObject {
    func didSelectImage(image: UIImage, imageURL: String)
}
