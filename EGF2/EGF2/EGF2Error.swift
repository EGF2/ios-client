//
//  EGF2Error.swift
//  EGF2
//
//  Created by LuzanovRoman on 25.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

enum EGF2ErrorCode: Int {
    case serverError = 1
    case networkError = 2
    case wrongResponse = 3
    case wrongJSONObject = 4
    case unknownObjectType = 5
    case invalidGraphObject = 6
    case invalidDataInCoreData = 7
    case wrongMethodParameter = 8
    
}

class EGF2Error: NSError {
    
    static func userInfo(withErrorCode code: EGF2ErrorCode) -> [String: String] {
        switch code {
        case .serverError:
            return [NSLocalizedDescriptionKey: "Server has returned an error"]
            
        case .networkError:
            return [NSLocalizedDescriptionKey: "A network error"]
            
        case .wrongResponse:
            return [NSLocalizedDescriptionKey: "Has got wrong response"]
            
        case .wrongJSONObject:
            return [NSLocalizedDescriptionKey: "Has got wrong JSON object"]
            
        case .unknownObjectType:
            return [NSLocalizedDescriptionKey: "Unknown object type"]
            
        case .invalidGraphObject:
            return [NSLocalizedDescriptionKey: "Invalid graph object"]
            
        case .invalidDataInCoreData:
            return [NSLocalizedDescriptionKey: "Core data object has invalid data"]
            
        case .wrongMethodParameter:
            return [NSLocalizedDescriptionKey: "Wrong method parameter"]
        }
    }
    
    init(code: EGF2ErrorCode, reason: String? = nil) {
        var userInfo = EGF2Error.userInfo(withErrorCode: code)
        
        if let value = reason {
            userInfo[NSLocalizedFailureReasonErrorKey] = value
        }
        super.init(domain: "EGF2", code: code.rawValue, userInfo: userInfo)
    }
    
    init(code: EGF2ErrorCode, userInfo: [String: Any]) {
        super.init(domain: "EGF2", code: code.rawValue, userInfo: EGF2Error.userInfo(withErrorCode: code) + userInfo)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
