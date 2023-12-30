//
//  AuthenticationManager.swift
//  LoginStudy
//
//  Created by 박다혜 on 12/29/23.
//

/*
 - 권한요청
 - FaceID 없으면?
    - 다른 인증 방법 권장 혹은 FaceID 등록 권유 (아이폰 잠금을 아예 안해놓거나 비밀번호만 등록한 사람)
    - FaceID 등록하려면 아이폰 암호가 먼저 설정되어야함
 - FaceID 변경됐을때 -> DomainStateData가 변경됨 (안경, 마스크 등은 변경 안됨)
 - FaceID 계속 틀렸을 때. Fallback에 대한 처리 필요. 다른 인증 방법으로 처리
 - FaceId 결과는 메인스레드 보장 안됨
 - 한 화면에서 FaceID 인증 성공하면, 해당 화면에 대해서는 success
 (SwiftUI 에서 state 변경되면 body 렌더링돼서 뷰가 다시 그려지고 초기화..다시 인증해야)
 */

import Foundation
import LocalAuthentication

final class AuthenticationManager {

    static let shared = AuthenticationManager()

    private init() {}

    var selectedPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics // 생체인증 (face, touch)

    // 인증
    func auth() {

        let context = LAContext()
        context.localizedCancelTitle = String(localized: "취소")
        context.localizedFallbackTitle = "비밀번호로 대신 인증하기"

        context.evaluatePolicy(selectedPolicy, localizedReason: "FaceID 인증 필요") { result, error in

            print(result)

            if let error {
                let code = error._code
                let laError = LAError(LAError.Code(rawValue: code)!)
                print(laError)
            }
        }
    }

    // 바이오인증 가능한 상태인지 여부 확인.
    func checkPolicy() -> Bool {
        let context = LAContext()
        let policy: LAPolicy = selectedPolicy

        return context.canEvaluatePolicy(policy, error: nil)
    }

    // 변경 시
    func isFaceIDChanged() -> Bool {
        let context = LAContext()
        context.canEvaluatePolicy(selectedPolicy, error: nil)

        let state = context.evaluatedPolicyDomainState //생체 인증 정보

        // 생체 인증 정보를 UserDefaults에 저장
        // 기존 저장된 DomainState와 새롭게 변경된 DomainState를 비교
        print(state)
        return false //로직 추가
    }

}
