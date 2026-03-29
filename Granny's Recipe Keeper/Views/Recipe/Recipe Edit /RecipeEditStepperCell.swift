

import UIKit

class RecipeEditStepperCell: UITableViewCell {
    static let identifier = "RecipeEditStepperCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17)
        label.textColor = .label
        return label
    }()
    
    private let minusButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("−", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .regular)
        return button
    }()
    
    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .regular)
        return button
    }()
    
    private let valueContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private var unit: String?
    private var step: Int = 1
    private var minValue: Int = 0
    private var maxValue: Int = 10_000
    
    private var repeatTimer: Timer?
    private var repeatingIncrement: Int = 0
    
    private(set) var currentValue: Int = 0 {
        didSet {
            updateValueLabel()
            onValueChanged?(currentValue)
        }
    }
    
    var onValueChanged: ((Int) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(minusButton)
        contentView.addSubview(valueContainerView)
        contentView.addSubview(plusButton)
        valueContainerView.addSubview(valueLabel)
        
        minusButton.addTarget(self, action: #selector(didTapMinus), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
        
        let minusLongPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        let plusLongPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        minusLongPress.minimumPressDuration = 0.4
        plusLongPress.minimumPressDuration = 0.4
        minusButton.addGestureRecognizer(minusLongPress)
        plusButton.addGestureRecognizer(plusLongPress)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            plusButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            plusButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 32),
            
            valueContainerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            valueContainerView.trailingAnchor.constraint(equalTo: plusButton.leadingAnchor, constant: -12),
            valueContainerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
            valueContainerView.heightAnchor.constraint(equalToConstant: 36),
            
            minusButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            minusButton.trailingAnchor.constraint(equalTo: valueContainerView.leadingAnchor, constant: -12),
            minusButton.widthAnchor.constraint(equalToConstant: 32),
            
            valueLabel.leadingAnchor.constraint(equalTo: valueContainerView.leadingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: valueContainerView.trailingAnchor, constant: -8),
            valueLabel.topAnchor.constraint(equalTo: valueContainerView.topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: valueContainerView.bottomAnchor),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
    
    func configure(title: String, value: Int?, unit: String?, step: Int = 1, minValue: Int = 0, maxValue: Int = 10_000) {
        titleLabel.text = title
        self.unit = unit
        self.step = max(step, 1)
        self.minValue = minValue
        self.maxValue = maxValue
        
        if let value = value, value >= minValue {
            currentValue = min(value, maxValue)
        } else {
            currentValue = minValue
            updateValueLabel()
        }
    }
    
    private func updateValueLabel() {
        if currentValue <= 0 && minValue == 0 {
            valueLabel.text = "—"
            valueLabel.textColor = .secondaryLabel
        } else {
            if let unit = unit, !unit.isEmpty {
                valueLabel.text = "\(currentValue) \(unit)"
            } else {
                valueLabel.text = "\(currentValue)"
            }
            valueLabel.textColor = .label
        }
    }
    
    @objc private func didTapMinus() {
        let newValue = max(minValue, currentValue - step)
        if newValue != currentValue {
            currentValue = newValue
        }
    }
    
    @objc private func didTapPlus() {
        let newValue = min(maxValue, currentValue + step)
        if newValue != currentValue {
            currentValue = newValue
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.view === minusButton || gesture.view === plusButton else { return }
        
        switch gesture.state {
        case .began:
            repeatTimer?.invalidate()
            repeatingIncrement = (gesture.view === plusButton) ? step : -step
            repeatTimer = Timer.scheduledTimer(timeInterval: 0.12, target: self, selector: #selector(handleRepeatTimer), userInfo: nil, repeats: true)
        case .ended, .cancelled, .failed:
            repeatTimer?.invalidate()
            repeatTimer = nil
            repeatingIncrement = 0
        default:
            break
        }
    }
    
    @objc private func handleRepeatTimer() {
        guard repeatingIncrement != 0 else { return }
        let newValue: Int
        if repeatingIncrement > 0 {
            newValue = min(maxValue, currentValue + step)
        } else {
            newValue = max(minValue, currentValue - step)
        }
        if newValue != currentValue {
            currentValue = newValue
        }
    }
}

