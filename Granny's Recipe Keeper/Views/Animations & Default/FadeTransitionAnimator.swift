//
//  FadeTransitionAnimator.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

class FadeTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let duration: TimeInterval = 0.3
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to),
              let _ = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        let toView = toViewController.view!
        
        toView.alpha = 0
        containerView.addSubview(toView)
        
        UIView.animate(withDuration: duration, animations: {
            toView.alpha = 1
        }) { finished in
            transitionContext.completeTransition(finished)
        }
    }
}

class SlideTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let duration: TimeInterval = 0.35
    private let isPresenting: Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to),
              let fromViewController = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        let toView = toViewController.view!
        let fromView = fromViewController.view!
        
        if isPresenting {
            toView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height)
            containerView.addSubview(toView)
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                toView.transform = .identity
                fromView.alpha = 0.7
            }) { finished in
                transitionContext.completeTransition(finished)
            }
        } else {
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                fromView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height)
                toView.alpha = 1.0
            }) { finished in
                transitionContext.completeTransition(finished)
            }
        }
    }
}

class TransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideTransitionAnimator(isPresenting: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideTransitionAnimator(isPresenting: false)
    }
}
