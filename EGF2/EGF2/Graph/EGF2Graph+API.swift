//
//  EGF2Graph+API.swift
//  EGF2
//
//  Created by LuzanovRoman on 09.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

public class EGF2SearchParameters: NSObject {
    public var object: String
    public var expand: [String]?
    public var fields: [String]?
    public var filters: [String: Any]?
    public var range: [String: Any]?
    public var sort: [String]?
    public var query: String?

    public static func parameters(withObject object: String) -> EGF2SearchParameters {
        return EGF2SearchParameters(withObject: object)
    }

    public init(withObject object: String) {
        self.object = object
    }
}

extension EGF2Graph {

    // MARK: - Fileprivate
    fileprivate func tryToObtainToken(withResponse responseObject: Any?, completion: Completion) {
        if let response = responseObject as? [String: String], let token = response["token"], let type = response["type"] {
            let value = "\(type) \(token)"
            self.api.authorization = value
            self.account.userToken = value
            self.account.save()
            completion(true, nil)
        } else {
            completion(false, EGF2Error(code: .wrongResponse))
        }
    }

    // MARK: - Private
    func jsonKeyToObjectKey(_ jsonKey: String) -> String {
        var objectKey = jsonKey
        var range = objectKey.range(of: "_")

        while let r = range {
            if r.upperBound == jsonKey.endIndex {
                return jsonKey
            }
            if r.upperBound == objectKey.endIndex {
                objectKey = objectKey.replacingCharacters(in: r, with: "")
                break
            }
            let characterRange = objectKey.index(r.lowerBound, offsetBy: 1) ..< objectKey.index(r.lowerBound, offsetBy: 2)
            let replaceRange = objectKey.index(r.lowerBound, offsetBy: 0) ..< objectKey.index(r.lowerBound, offsetBy: 2)
            let character = objectKey.substring(with: characterRange).uppercased()
            objectKey = objectKey.replacingCharacters(in: replaceRange, with: character)
            range = objectKey.range(of: "_")
        }
        return objectKey
    }

    func fixedDictionary(_ jsonDictionary: [String: Any]) -> [String: Any] {
        var newDictionary = [String: Any]()

        for (key, value) in jsonDictionary {
            newDictionary[jsonKeyToObjectKey(key)] = value
        }
        return newDictionary
    }

    func objectType(byId id: String) -> NSObject.Type? {
        if let suffix = id.components(separatedBy: "-").last, suffix.characters.count == 2 {
            return idsWithModelTypes[suffix]
        }
        return nil
    }

    // MARK: - Public
    // MARK: Auth operations
    public func register(withFirstName firstName: String, lastName: String, email: String, dateOfBirth: Date, password: String, completion: @escaping Completion) {
        api.register(withFirstName: firstName, lastName: lastName, email: email, dateOfBirth: dateOfBirth, password: password) { (response, error) in
            guard let _ = error else {
                self.tryToObtainToken(withResponse: response, completion: completion)
                return
            }
            completion(nil, error)
        }
    }

    public func login(withEmail email: String, password: String, completion: @escaping Completion) {
        api.login(withEmail: email, password: password) { (response, error) in
            guard let _ = error else {
                self.tryToObtainToken(withResponse: response, completion: completion)
                return
            }
            completion(nil, error)
        }
    }

    public func logout(withCompletion completion: @escaping Completion) {
        api.logout { (_, error) in
            self.api.authorization = nil
            self.account.reset()
            self.coreDataSave()
            self.deleteAllCoreDataObjects()
            completion(nil, error)
        }
    }

    public func change(oldPassword: String, withNewPassword newPassword: String, completion: @escaping Completion) {
        api.change(oldPassword: oldPassword, withNewPassword: newPassword, completion: completion)
    }

    public func restorePassword(withEmail email: String, completion: @escaping Completion) {
        api.restorePassword(withEmail: email, completion: completion)
    }

    public func resetPassword(withToken token: String, newPassword: String, completion: @escaping Completion) {
        api.resetPassword(withToken: token, newPassword: newPassword, completion: completion)
    }

    public func verifyEmail(withToken token: String, completion: @escaping Completion) {
        api.verifyEmail(withToken: token, completion: completion)
    }

    public func resendEmailVerification(withCompletion completion: @escaping Completion) {
        api.resendEmailVerification(withCompletion: completion)
    }

    // MARK: Graph operations
    public func search(forObject object: String, after: Int, count: Int, expand: [String]? = nil, fields: [String]? = nil, filters: [String: Any]? = nil, range: [String: Any]? = nil, sort: [String]? = nil, query: String? = nil, completion: @escaping ObjectsBlock) {
        api.search(forObject: object, after: after, count: count, expand: expand, fields: fields, filters: filters, range: range, sort: sort, query: query) { (response, error) in
            if let _ = error {
                completion(nil, 0, error)
                return
            }
            guard let dictionary = response as? [String: Any],
                let dictionaries = dictionary["results"] as? [[String: Any]],
                let count = dictionary["count"] as? Int else {
                    completion(nil, 0, EGF2Error(code: .wrongResponse))
                    return
            }
            var objects = [NSObject]()

            for value in dictionaries {
                guard let id = value["id"] as? String else {
                    completion(nil, 0, EGF2Error(code: .wrongJSONObject))
                    return
                }
                guard let type = self.objectType(byId: id) else {
                    completion(nil, 0, EGF2Error(code: .unknownObjectType, reason: "Unknown type for object with id: \(id)"))
                    return
                }
                objects.append(self.objectWith(type: type, dictionary: self.fixedDictionary(value)))
            }
            completion(objects, count, nil)
        }
    }

    public func search(withParameters parameters: EGF2SearchParameters, after: Int, count: Int, completion: @escaping ObjectsBlock) {
        search(forObject: parameters.object, after: after, count: count, expand: parameters.expand, fields: parameters.fields, filters: parameters.filters, range: parameters.range, sort: parameters.sort, query: parameters.query, completion: completion)
    }
}
