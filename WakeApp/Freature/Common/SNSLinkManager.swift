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
    case twitter
    
    var scheme: String {
        switch self {
        case .notion:
            return "notion://"
        case .web:
            return "https://"
        case .twitter:
            return "twitter://"
        }
    }
}

class SNSLinkManager {
    func transitionToPrivacyPolicy() {
        let notionScheme = SNSPlatform.notion.scheme
        let webScheme = SNSPlatform.web.scheme
        guard let url = URL(string: notionScheme),
              let privacyPolicy = Const.privacyPolicy else {
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
    
    func transitionToTermsOfService() {
        let notionScheme = SNSPlatform.notion.scheme
        let webScheme = SNSPlatform.web.scheme
        guard let url = URL(string: notionScheme),
              let termsOfService = Const.termsOfService else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            guard let termsOfServiceURL = URL(string: notionScheme + termsOfService) else {
                return
            }
            UIApplication.shared.open(termsOfServiceURL)

        } else {
            guard let termsOfServiceURL = URL(string: webScheme + termsOfService) else {
                return
            }
            UIApplication.shared.open(termsOfServiceURL)
        }
    }

    func transitionToUsage() {
        let notionScheme = SNSPlatform.notion.scheme
        let webScheme = SNSPlatform.web.scheme
        guard let url = URL(string: notionScheme),
              let usage = Const.usage else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            guard let usageURL = URL(string: notionScheme + usage) else {
                return
            }
            UIApplication.shared.open(usageURL)

        } else {
            guard let usageURL = URL(string: webScheme + usage) else {
                return
            }
            UIApplication.shared.open(usageURL)
        }
    }
    
    func transitionToTwitter() {
        let twitterScheme = SNSPlatform.twitter.scheme
        let webScheme = SNSPlatform.web.scheme
        guard let url = URL(string: twitterScheme),
              let twitterApp = Const.twitterApp,
              let twitterWeb = Const.twitterWeb else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            guard let twitterURL = URL(string: twitterScheme + twitterApp) else {
                return
            }
            UIApplication.shared.open(twitterURL)
            
        } else {
            guard let twitterURL = URL(string: webScheme + twitterWeb) else {
                return
            }
            UIApplication.shared.open(twitterURL)
        }
    }
}
