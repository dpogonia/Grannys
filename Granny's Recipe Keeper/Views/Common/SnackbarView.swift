//
//  SnackbarView.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 28.01.2026.
//

import UIKit

// MARK: - SnackbarView
// UI компонент для отображения уведомлений с кнопкой Undo
class SnackbarView: UIView {

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 1
        return label
    }()

    private let undoButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("UNDO", for: .normal)
        button.setTitleColor(.systemYellow, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        return button
    }()

    private var undoAction: (() -> Void)?
    private var hideTimer: Timer?

    init(message: String, undoAction: @escaping () -> Void) {
        super.init(frame: .zero)
        self.messageLabel.text = message
        self.undoAction = undoAction
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(white: 0.2, alpha: 0.95)
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.3

        addSubview(messageLabel)
        addSubview(undoButton)

        undoButton.addTarget(self, action: #selector(didTapUndo), for: .touchUpInside)

        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            undoButton.leadingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 16),
            undoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            undoButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            undoButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),

            heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc private func didTapUndo() {
        undoAction?()
        hide(animated: true)
    }

    func show(in view: UIView, duration: TimeInterval = 4.0) {
        view.addSubview(self)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        // Анимация появления
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }

        // Автоматическое скрытие через duration секунд
        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.hide(animated: true)
        }
    }

    func hide(animated: Bool) {
        hideTimer?.invalidate()
        hideTimer = nil

        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(translationX: 0, y: 20)
            }) { _ in
                self.removeFromSuperview()
            }
        } else {
            removeFromSuperview()
        }
    }

    deinit {
        hideTimer?.invalidate()
    }
}

// MARK: - UIViewController Extension
extension UIViewController {
    func showSnackbar(message: String, undoAction: @escaping () -> Void) {
        let snackbar = SnackbarView(message: message, undoAction: undoAction)
        snackbar.show(in: view)
    }
}
