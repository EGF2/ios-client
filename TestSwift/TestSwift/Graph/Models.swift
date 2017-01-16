//
//  Models.swift
//  TestSwift
//
//  Created by LuzanovRoman on 10.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

class BaseObject: NSObject {
    var id: String?
    var createdAt: Date?
    var deletedAt: Date?
    var modifiedAt: Date?

    func requiredFields() -> [String] {
        return [
            "modifiedAt",
            "id",
            "createdAt"
        ]
    }
}

class UserName: NSObject {
    var family: String?
    var given: String?
    var use: String?

    func requiredFields() -> [String] {
        return [
            "use",
            "given",
            "family"
        ]
    }
}

class Address: NSObject {
    var city: String?
}

class User: BaseObject {
    var dateOfBirth: Date?
    var image: String?
    var imageObject: File?
    var gender: String?
    var email: String?
    var name: UserName?
    var addresses = [Address]()

    func editableFields() -> [String] {
        return [
            "name"
        ]
    }

    override func requiredFields() -> [String] {
        return super.requiredFields() + [
            "name",
            "email"
        ]
    }
}

class Dimension: NSObject {
    var width: Int = 0
    var height: Int = 0
}

class Resize: NSObject {
    var url: String?
    var dimensions: Dimension?
}

class File: BaseObject {
    var uploadUrl: String?
    var mimeType: String?
    var title: String?
    var user: String?
    var url: String?
    var size: Int = 0
    var hosted: Bool = false
    var uploaded: Bool = false
    var resizes = [Resize]()

    override func requiredFields() -> [String] {
        return super.requiredFields() + [
            "url",
            "mimeType",
            "user"
        ]
    }
}

class Post: BaseObject {
    var designer: String?
    var image: String?
    var imageObject: File?
}

class DesignerRole: BaseObject {
    var user: String?
    var userObject: User?
}

class Product: BaseObject {
    var designer: String?
    var designerObject: DesignerRole?
    var coverImage: String?
    var coverImageObject: File?
    var collection: String?
    var collectionObject: Collection?
}

class Collection: BaseObject {
    var designer: String?
    var designerObject: DesignerRole?
    var coverImage: String?
    var coverImageObject: File?
}

class Message: BaseObject {
    var from: String?
    var fromObject: User?
    var to: String?
    var toObject: User?
    var subject: String?
    var text: String?
}
