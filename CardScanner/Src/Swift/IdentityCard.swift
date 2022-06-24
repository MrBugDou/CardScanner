import Foundation
import UIKit

public struct IdentityCard {
    
    public struct Front {
        /// 身份证号
        public private(set) var number: String
        /// 姓名
        public private(set) var name: String
        /// 性别
        public private(set) var gender: String
        /// 民族
        public private(set) var nation: String
        /// 住址
        public private(set) var address: String
    }
    
    public struct Back {
        /// 签发机关
        public private(set) var issue: String
        /// 有效期限
        public private(set) var valid: String
    }
    
    /// 正面
    public var front: IdentityCard.Front?
    
    /// 背面
    public var back: IdentityCard.Back?
    
    public init(json: [String: String]) {
        
        if let number = json["number"],
           let name = json["name"],
           let gender = json["gender"],
           let nation = json["nation"],
           let address = json["address"] {
            front = .init(number: number, name: name, gender: gender, nation: nation, address: address)
        }
        
        if let issue = json["issue"],
           let valid = json["valid"] {
            back = .init(issue: issue, valid: valid)
        }
        
    }
    
}
