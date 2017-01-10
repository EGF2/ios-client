//
//  EGF2GraphAPI.swift
//  EGF2
//
//  Created by LuzanovRoman on 07.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

class EGF2GraphAPI: EGF2API {
    
    // MARK: - Auth operations
    func login(withEmail email: String, password: String, completion: @escaping Completion) {
        execute(withLocalURL: "login", method: .post, parameters: ["email":email, "password":password], completion:  completion)
    }

    func logout(withCompletion completion: @escaping Completion) {
        execute(withLocalURL: "logout", method: .get, parameters: nil, completion:  completion)
    }

    func restorePassword(withEmail email: String, completion: @escaping Completion) {
        execute(withLocalURL: "forgot_password", method: .get, parameters: ["email":email], completion: completion)
    }
    
    func resetPassword(withToken token: String, newPassword: String, completion: @escaping Completion) {
        let parameters = ["reset_token":token, "new_password":newPassword]
        execute(withLocalURL: "reset_password", method: .post, parameters: parameters, completion: completion)
    }
    
    func verifyEmail(withToken token: String, completion: @escaping Completion) {
        execute(withLocalURL: "verify_email", method: .get, parameters: ["token":token], completion: completion)
    }
    
    func resendEmailVerification(withCompletion completion: @escaping Completion) {
        execute(withLocalURL: "resend_email_verification", method: .post, parameters: nil, completion:  completion)
    }
    
    func change(oldPassword: String, withNewPassword newPassword: String, completion: @escaping Completion) {
        let parameters = ["old_password":oldPassword, "new_password":newPassword]
        execute(withLocalURL: "change_password", method: .post, parameters: parameters, completion: completion)
    }
    
    func register(withFirstName firstName: String, lastName: String, email: String, dateOfBirth: Date, password: String, completion: @escaping Completion) {
        let parameters = ["first_name":firstName, "last_name":lastName, "email":email, "date_of_birth": dateOfBirth.toRFC3339String(), "password":password]
        execute(withLocalURL: "register", method: .post, parameters: parameters, completion: completion)
    }
    
    // MARK: - File operations
    func createFile(withTitle title: String, mimeType: String, completion: @escaping Completion) {
        execute(withLocalURL: "new_file", method: .get, parameters: ["title":title, "mime_type":mimeType], completion: completion)
    }
    
    func createImage(withTitle title: String, mimeType: String, kind: String, completion: @escaping Completion) {
        execute(withLocalURL: "new_image", method: .get, parameters: ["title":title, "mime_type":mimeType, "kind": kind], completion: completion)
    }
    
    func uploadFile(withData data: Data, mimeType: String, url: URL, completion: @escaping Completion) {
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        request.setValue(mimeType, forHTTPHeaderField: "Content-type")
        execute(withRequest: request as URLRequest, completion: completion)
    }
    
    // MARK: - Graph operations
    func createObject(withParameters parameters: [String: Any], completion: Completion?) {
        execute(withLocalURL: "", method: .post, parameters: parameters, completion: completion)
    }

    func object(withId id: String, parameters: [String: Any]?, completion: Completion?) {
        execute(withLocalURL: "graph/\(id)", method: .get, parameters: parameters, completion: completion)
    }
    
    func updateObject(withId id: String, parameters: [String: Any], completion: Completion?) {
        execute(withLocalURL: "graph/\(id)", method: .put, parameters: parameters, completion: completion)
    }
    
    func deleteObject(withId id: String, completion: Completion?) {
        execute(withLocalURL: "graph/\(id)", method: .delete, parameters: nil, completion: completion)
    }

    func object(withId id: String, existOnEdge edge: String, forSource source: String, completion: @escaping Completion) {
        execute(withLocalURL: "graph/\(source)/\(edge)/\(id)", method: .get, parameters: nil, completion: completion)
    }
    
    func objects(forSource source: String, onEdge edge: String, parameters: [String: Any]?, completion: Completion?) {
        execute(withLocalURL: "graph/\(source)/\(edge)", method: .get, parameters: parameters, completion: completion)
    }
    
    func addObject(withId id: String, forSource source: String, onEdge edge: String, completion: Completion?) {
        execute(withLocalURL: "graph/\(source)/\(edge)/\(id)", method: .post, parameters: nil, completion: completion)
    }
    
    func deleteObject(withId id: String, forSource source: String, fromEdge edge: String, completion: Completion?) {
        execute(withLocalURL: "graph/\(source)/\(edge)/\(id)", method: .delete, parameters: nil, completion: completion)
    }
    
    func createObject(withParameters parameters: [String: Any], forSource source: String, onEdge edge: String, completion: Completion?) {
        execute(withLocalURL: "graph/\(source)/\(edge)", method: .post, parameters: parameters, completion: completion)
    }

    func search(forObject object: String, after: Int, count: Int, expand: [String]? = nil, fields: [String]? = nil, filters: [String: Any]? = nil, range: [String: Any]? = nil, sort: [String]? = nil, query: String? = nil, completion: @escaping Completion) {
        var parameters: [String: Any] = ["object":object]
        
        if after >= 0 {
            parameters["after"] = after
        }
        if count >= 0 {
            parameters["count"] = count
        }
        if let value = expand {
            parameters["expand"] = value.joined(separator: ",")
        }
        if let value = fields {
            parameters["fields"] = value.joined(separator: ",")
        }
        if let value = filters {
            parameters["filters"] = value.joined(separator: ":")
        }
        if let value = range {
            parameters["range"] = value.joined(separator: ":")
        }
        if let value = sort {
            parameters["sort"] = value.joined(separator: ",")
        }
        if let value = query {
            parameters["q"] = value
        }
        execute(withLocalURL: "search", method: .get, parameters: parameters, completion: completion)
    }
}
