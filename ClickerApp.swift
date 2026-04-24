import UIKit

class ViewController: UIViewController {
    private var score = 0
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.text = "Score: 0"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    private let clickButton: UIButton = {
        let button = UIButton()
        button.setTitle("🎯 TAP!", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .heavy)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 20
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Используем простой frame-based layout
        scoreLabel.frame = CGRect(x: 0, y: 200, width: view.bounds.width, height: 50)
        clickButton.frame = CGRect(x: (view.bounds.width - 200) / 2, y: 300, width: 200, height: 60)
        
        view.addSubview(scoreLabel)
        view.addSubview(clickButton)
        
        clickButton.addTarget(self, action: #selector(handleClick), for: .touchUpInside)
    }
    
    @objc private func handleClick() {
        score += 1
        scoreLabel.text = "Score: \(score)"
        
        // Анимация кнопки
        UIView.animate(withDuration: 0.1, animations: {
            self.clickButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.clickButton.transform = .identity
            }
        }
    }
}

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

// Главная функция
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
