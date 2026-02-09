//
//  MpesaEnvironment.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 2/2/2026.
//

import Foundation

/// M-Pesa API environment configuration.
public enum MpesaEnvironment {
    case sandbox
    case production

    var baseURL: URL {
        switch self {
        case .sandbox:
            return URL(string: "https://sandbox.safaricom.co.ke")!
        case .production:
            return URL(string: "https://api.safaricom.co.ke")!
        }
    }
}
