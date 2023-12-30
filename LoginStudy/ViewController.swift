//
//  ViewController.swift
//  LoginStudy
//
//  Created by 박다혜 on 12/28/23.
//

import UIKit
import AuthenticationServices

class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .gray
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var appleLoginButton: ASAuthorizationAppleIDButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        appleLoginButton.addTarget(self, action: #selector(appleLoginButtonClicked), for: .touchUpInside)
    }

    @IBAction func faceIDButtonClicked(_ sender: Any) {
        AuthenticationManager.shared.auth()
    }

    @objc
    func appleLoginButtonClicked() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email, .fullName]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }


}

//애플로 로그인 성공한 경우 -> 메인 페이지로 이동 등..

// 처음 시도 : 계속, email, fullname 제공
// 두번째 시도 : email, fullname nil값으로 온다
// 사용자 정보를 계속 제공해주지 않는다.

extension ViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:

            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email

            guard let token = appleIDCredential.identityToken,
                  let tokenToString = String(data: token, encoding: .utf8) else {
                print("Token error")
                return
            }

            print(userIdentifier)
            print(fullName ?? "No fullname")
            print(email ?? "No email")
            print(tokenToString)

            if email?.isEmpty ?? true {
                let result = decode(jwtToken: tokenToString)["email"] as? String ?? ""
                print(result)
            }

            // 이메일, 토큰, 이름 -> UserDefaults에 저장, API로 서버에 POST
            // 서버에 Request 후 Response를 받게 되면 성공시 화면 전환

            UserDefaults.standard.set(userIdentifier, forKey: "User")

            DispatchQueue.main.async {
                self.present(MainViewController(), animated: true)
            }

        case let passwordCredential as ASPasswordCredential:
            let userName = passwordCredential.user
            let password = passwordCredential.password

            print(userName)
            print(password)

        default:
            break
        }
    }

}

extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }

}

private func decode(jwtToken jwt: String) -> [String: Any] {

    func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 = base64 + padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }

    func decodeJWTPart(_ value: String) -> [String: Any]? {
            guard let bodyData = base64UrlDecode(value),
                  let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
                return nil
            }

            return payload
        }

        let segments = jwt.components(separatedBy: ".")
        return decodeJWTPart(segments[1]) ?? [:]
    }
