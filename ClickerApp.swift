import UIKit

// MARK: - Модель игры
class ClickerGame {
    private(set) var score: Int = 0
    private(set) var clickValue: Int = 1
    private(set) var autoClickers: Int = 0
    private var autoClickTimer: Timer?
    
    init() {
        startAutoClicks()
    }
    
    func click() {
        score += clickValue
    }
    
    func upgradeClick() {
        let cost = clickValue * 10
        if score >= cost {
            score -= cost
            clickValue += 1
        }
    }
    
    func buyAutoClicker() {
        let cost = (autoClickers + 1) * 50
        if score >= cost {
            score -= cost
            autoClickers += 1
        }
    }
    
    func resetGame() {
        score = 0
        clickValue = 1
        autoClickers = 0
    }
    
    var upgradeCost: Int { clickValue * 10 }
    var autoClickerCost: Int { (autoClickers + 1) * 50 }
    
    private func startAutoClicks() {
        autoClickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.autoClickers > 0 else { return }
            self.score += self.autoClickers
            NotificationCenter.default.post(name: .init("AutoClickUpdate"), object: nil)
        }
    }
}

// MARK: - Главный ViewController
class ViewController: UIViewController {
    private let game = ClickerGame()
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.text = "Очки: 0"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    private let clickButton: UIButton = {
        let button = UIButton()
        button.setTitle("🎯 КЛИКНУТЬ!", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .heavy)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let upgradeButton: UIButton = {
        let button = UIButton()
        button.setTitle("Улучшить клик (10)", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemOrange
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let autoClickerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Купить автокликер (50)", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("🔄 Сбросить", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 10
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUI),
            name: Notification.Name("AutoClickUpdate"),
            object: nil
        )
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Градиентный фон
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemPurple.cgColor,
            UIColor.systemIndigo.cgColor
        ]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Добавляем элементы
        let stackView = UIStackView(arrangedSubviews: [
            scoreLabel,
            clickButton,
            upgradeButton,
            autoClickerButton,
            resetButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        // Констрейнты
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            clickButton.widthAnchor.const极(equalToConstant: 200),
            clickButton.heightAnchor.constraint(equalToConstant: 60),
            
            upgradeButton.widthAnchor.constraint(equalToConstant: 200),
            upgradeButton.heightAnchor.constraint(equal极Constant: 50),
            
            autoClickerButton.widthAnchor.constraint(equalToConstant: 200),
            autoClickerButton.heightAnchor.constraint(equalToConstant: 50),
            
            resetButton.widthAnchor.constraint(equalToConstant: 120),
            resetButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        updateButtons()
    }
    
    private func setupActions() {
        clickButton.addTarget(self, action: #selector(handleClick), for: .touchUpInside)
        upgradeButton.addTarget(self, action: #selector(handleUpgrade), for: .touchUpInside)
        autoClickerButton.addTarget(self, action: #selector(handleAutoClick极), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(handleReset), for: .touchUpInside)
    }
    
    @objc private func handleClick() {
        game.click()
        updateUI()
        
        // Анимация клика
        UIView.animate(withDuration: 0.1, animations: {
            self.clickButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.clickButton.transform = .identity
            }
        }
    }
    
    @objc private func handleUpgrade() {
        game.upgradeClick()
        updateUI()
    }
    
    @objc private func handleAutoClicker() {
        game.buyAutoClicker()
        updateUI()
    }
    
    @objc private func handleReset() {
        game.resetGame()
        updateUI()
    }
    
    @objc private func updateUI() {
        scoreLabel.text = "Очки: \(game.score)"
        upgradeButton.setTitle("Улучшить клик (\(game.upgradeCost))", for: .normal)
        autoClickerButton.setTitle("Автокликер (\(game.autoClickerCost))", for: .normal)
        
        // Обновляем доступность кнопок
        upgradeButton.alpha = game.score >= game.upgradeCost ? 1.0 : 0.6
        upgradeButton.isEnabled = game.score >= game.upgradeCost
        
        autoClickerButton.alpha = game.score >= game.autoClickerCost ? 1.0 : 0.6
        autoClickerButton.isEnabled = game.score >= game.autoClickerCost
        
        // Добавляем эмодзи к счету
        let emoji: String
        switch game.score {
        case 0..<10: emoji = "👶"
        case 10..<50: emoji = "😊"
        case 50..<100: emoji = "🎯"
        case 100..<200: emoji = "🔥"
        default: emoji = "🚀"
        }
        scoreLabel.text = "\(emoji) Очки: \(game.score)"
    }
    
    private func updateButtons() {
        updateUI()
    }
}

// MARK: - AppDelegate
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, 
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

// MARK: - Главная функция
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
