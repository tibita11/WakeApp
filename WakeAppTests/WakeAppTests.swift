//
//  WakeAppTests.swift
//  WakeAppTests
//
//  Created by 鈴木楓香 on 2023/05/27.
//

import XCTest
@testable import WakeApp

final class AuthenticationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEmailValidator() {
        XCTContext.runActivity(named: "空欄の場合") { _ in
            XCTContext.runActivity(named: "値がない場合") { _ in
                let result = EmailValidator(value: "").validate()
                XCTAssertFalse(result.isValid)
            }
            
            XCTContext.runActivity(named: "空白だけの場合") { _ in
                let result = EmailValidator(value: "   ").validate()
                XCTAssertFalse(result.isValid)
            }
        }
        
        XCTContext.runActivity(named: "空白の場合") { _ in
            XCTContext.runActivity(named: "空白が全角の場合") { _ in
                let result = EmailValidator(value: "　aaa").validate()
                XCTAssertFalse(result.isValid)
            }
            XCTContext.runActivity(named: "空白が半角の場合") { _ in
                let result = EmailValidator(value: " aaa").validate()
                XCTAssertFalse(result.isValid)
            }
        }
        
        XCTContext.runActivity(named: "成功の場合") { _ in
            let result = EmailValidator(value: "aaa").validate()
            XCTAssertTrue(result.isValid)
        }
        
    }
    
    func testPasswordValidator() {
        XCTContext.runActivity(named: "空欄の場合") { _ in
            XCTContext.runActivity(named: "値がない場合") { _ in
                let result = PasswordValidator(value: "").validate()
                XCTAssertFalse(result.isValid)
            }
            
            XCTContext.runActivity(named: "空白だけの場合") { _ in
                let result = PasswordValidator(value: "   ").validate()
                XCTAssertFalse(result.isValid)
            }
        }
        
        XCTContext.runActivity(named: "空白の場合") { _ in
            XCTContext.runActivity(named: "空白が全角の場合") { _ in
                let result = PasswordValidator(value: "　aaaaaaaaaaaa").validate()
                XCTAssertFalse(result.isValid)
            }
            XCTContext.runActivity(named: "空白が半角の場合") { _ in
                let result = PasswordValidator(value: " aaaaaaaaaaaa").validate()
                XCTAssertFalse(result.isValid)
            }
        }
        
        XCTContext.runActivity(named: "12文字以下の場合") { _ in
            let result = PasswordValidator(value: "aaaaaaaaaaa").validate()
            XCTAssertFalse(result.isValid)
        }
        
        XCTContext.runActivity(named: "成功の場合") { _ in
            let result = PasswordValidator(value: "aaaaaaaaaaaa").validate()
            XCTAssertTrue(result.isValid)
        }
        
    }
    
    func testUserNameValidator() {
        XCTContext.runActivity(named: "空欄の場合") { _ in
            XCTContext.runActivity(named: "値がない場合") { _ in
                let result = UserNameValidator(value: "").validate()
                XCTAssertFalse(result.isValid)
            }
            
            XCTContext.runActivity(named: "空白だけの場合") { _ in
                let result = UserNameValidator(value: "   ").validate()
                XCTAssertFalse(result.isValid)
            }
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
