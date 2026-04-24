import UIKit

class ViewController: UIViewController {
    private let apiUrl = "https://jetong.ru/rele/api.php"
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Нажмите кнопку"
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private let fetchButton: UIButton = {
        let button = UIButton()
        button.setTitle("🔄 Получить данные", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        statusLabel.frame = CGRect(x: 20, y: 200, width: view.bounds.width - 40, height: 100)
        fetchButton.frame = CGRect(x: (view.bounds.width - 200) / 2, y: 320, width: 200, height: 50)
        activityIndicator.frame = CGRect(x: (view.bounds.width - 20) / 2, y: 380, width: 20, height: 20)
        
        view.addSubview(statusLabel)
        view.addSubview(fetchButton)
        view.addSubview(activityIndicator)
    }
    
    private func setupActions() {
        fetchButton.addTarget(self, action: #selector(fetchData), for: .touchUpInside)
    }
    
    @objc private func fetchData() {
        activityIndicator.startAnimating()
        fetchButton.isEnabled = false
        statusLabel.text = "Загрузка..."
        
        guard let url = URL(string: apiUrl) else {
            statusLabel.text = "Ошибка: неверный URL"
            fetchButton.isEnabled = true
            activityIndicator.stopAnimating()
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.fetchButton.isEnabled = true
                
                if let error = error {
                    self?.statusLabel.text = "Ошибка: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.statusLabel.text = "Нет данных"
                    return
                }
                
                if let responseText = String(data: data, encoding: .utf8) {
                    self?.statusLabel.text = "Ответ сервера:\n\(responseText)"
                } else {
                    self?.statusLabel.text = "Не могу прочитать ответ"
                }
            }
        }
        
        task.resume()
        
        // Анимация кнопки
        UIView.animate(withDuration: 0.1, animations: {
            self.fetchButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.fetchButton.transform = .identity
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

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
