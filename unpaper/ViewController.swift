import Foundation
import os.log
import TDLibKit
import UIKit

class LoggerImpl: TDLibKit.Logger {
    private let logger = Logger()

    func log(_ message: String, type: TDLibKit.LoggerMessageType? = .none) {
        logger.log("\(message)")
    }
}

class ViewController: UIViewController {
    private let logger = LoggerImpl()
    private var client: TdClientImpl!
    private var api: TdApi!
    private var code = ""
    private let indicator = UIActivityIndicatorView(style: .large)

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        self.client = TdClientImpl(completionQueue: .main, logger: logger)
        self.api = TdApi(client: client)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.client = TdClientImpl(completionQueue: .main, logger: logger)
        self.api = TdApi(client: client)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        Task {
            await initApi()
        }
    }

    func setupUI() {
        view.backgroundColor = .white
        indicator.startAnimating()

        let codeTextField = UITextField()
        codeTextField.placeholder = "Code"
        codeTextField.borderStyle = .roundedRect
        codeTextField.keyboardType = .numberPad
        codeTextField.addTarget(self, action: #selector(codeTextFieldChanged(sender:)), for: .editingChanged)

        let loginButton = UIButton(type: .system)
        loginButton.setTitle("Login", for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonTapped(sender:)), for: .touchUpInside)

        let rootStackView = UIStackView(arrangedSubviews: [
            indicator,
            codeTextField,
            loginButton
        ])
        rootStackView.isLayoutMarginsRelativeArrangement = true
        rootStackView.layoutMargins = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)
        rootStackView.translatesAutoresizingMaskIntoConstraints = false
        rootStackView.axis = .vertical
        rootStackView.spacing = 24

        view.addSubview(rootStackView)

        NSLayoutConstraint.activate([
            rootStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func codeTextFieldChanged(sender: UITextField) {
        if let text = sender.text {
            code = text
        }
    }

    @objc private func loginButtonTapped(sender: UIButton) {
        Task {
            await login()
        }
    }

    func login() async {
        do {
            _ = try await api.checkAuthenticationCode(code: code)
            _ = try await api.registerUser(firstName: "Vlad", lastName: nil)
            try await logState()
        } catch {
            logger.log("Error: \(error.localizedDescription)")
        }
    }

    func initApi() async {
        indicator.isHidden = false
        api.client.run { _ in }
        let tdlibParams = TdlibParameters(
            apiHash: "905a73c3fef416f0ebe155e44f388059",
            apiId: 102642,
            applicationVersion: "Test version",
            databaseDirectory: "tmp",
            deviceModel: "Test device",
            enableStorageOptimizer: false,
            filesDirectory: "tmp",
            ignoreFileNames: false,
            systemLanguageCode: "en-US",
            systemVersion: "1.0",
            useChatInfoDatabase: true,
            useFileDatabase: true,
            useMessageDatabase: true,
            useSecretChats: false,
            useTestDc: true
        )

        do {
            _ = try await api.setTdlibParameters(parameters: tdlibParams)
            _ = try await api.setDatabaseEncryptionKey(newEncryptionKey: Data("1234".utf8))
            _ = try await api.setAuthenticationPhoneNumber(phoneNumber: "+79172208295", settings: nil)
            try await logState()
            indicator.isHidden = true
        } catch {
            logger.log("Error: \(error.localizedDescription)")
        }
    }

    func logState() async throws {
        let state = try await api.getAuthorizationState()
        logger.log("State: \(state)")
    }
}
