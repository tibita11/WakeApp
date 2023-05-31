//
//  EmailValidation.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/31.
//

import Foundation

protocol Validation {
    var value: String { get }
    func validate() -> ValidationResult
}

enum ValidationResult {
    case valid
    case invalid (Error)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyError
    case blankError
    case lessThen12ChractersError
    
    var errorDescription: String? {
        switch self {
        case .emptyError:
            return "入力してください。"
        case .blankError:
            return "空白を含まずに入力してください。"
        case .lessThen12ChractersError:
            return "12文字以上入力してください。"
        }
    }
}

struct EmptyValidation: Validation {
    var value: String
    func validate() -> ValidationResult {
        if value.isEmpty {
            return ValidationResult.invalid(ValidationError.emptyError)
        }
        return ValidationResult.valid
    }
}

struct BlankValidation: Validation {
    var value: String
    func validate() -> ValidationResult {
        if value.contains(" ") || value.contains("　") {
            return ValidationResult.invalid(ValidationError.blankError)
        }
        return ValidationResult.valid
    }
}

struct LessThen12CharactersValidation: Validation {
    var value: String
    func validate() -> ValidationResult {
        if value.count < 12 {
            return ValidationResult.invalid(ValidationError.lessThen12ChractersError)
        }
        return ValidationResult.valid
    }
}

protocol Validator {
    var validations: [Validation] { get }
    init(value: String)
    func validate() -> ValidationResult
}

extension Validator {
    func validate() -> ValidationResult {
        guard let result = validations.map({ $0.validate() }).first(where: { !$0.isValid} ) else {
            return .valid
        }
        return result
    }
}

/// Emailバリデーションチェックに使用する
struct EmailValidator: Validator {
    var validations: [Validation]
    init(value: String) {
        // バリデーションチェックを増やしたい場合に追加する
        self.validations = [EmptyValidation(value: value),
                            BlankValidation(value: value)]
    }
}

/// Passwordバリデーションチェックに使用する
struct PasswordValidator: Validator {
    var validations: [Validation]
    
    init(value: String) {
        // バリデーションチェックを増やしたい場合に追加する
        self.validations = [EmptyValidation(value: value),
                            BlankValidation(value: value),
                            LessThen12CharactersValidation(value: value)]
    }
}
