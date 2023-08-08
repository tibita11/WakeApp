//
//  SNSLinkManager.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/08/08.
//

import UIKit

enum SNSPlatform {
    case notion
    case web
    
    var scheme: String {
        switch self {
        case .notion:
            return "notion://"
        case .web:
            return "https://"
        }
    }
}

class SNSLinkManager {
    func transitionToPrivacyPolicy() {
        let notionScheme = SNSPlatform.notion.scheme
        let webScheme = SNSPlatform.web.scheme
        guard let url = URL(string: notionScheme),
              let privacyPolicy = Bundle.main.object(forInfoDictionaryKey: "PRIVACY_POLICY") as? String else {
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            guard let privacyPoricyURL = URL(string: notionScheme + privacyPolicy) else {
                return
            }
            UIApplication.shared.open(privacyPoricyURL)

        } else {
            guard let privacyPoricyURL = URL(string: webScheme + privacyPolicy) else {
                return
            }
            UIApplication.shared.open(privacyPoricyURL)
        }
    }
}
