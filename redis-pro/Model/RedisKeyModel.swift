//
//  RedisKeyModel.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import Foundation

class RedisKeyModel:ObservableObject, Identifiable, Equatable, CustomStringConvertible {
    @Published var key: String
    @Published var type: String
    @Published var ttl: Int = -1
    
    var id:String {
        key
    }
    
    init(key:String, type:String) {
        self.key = key
        self.type = type
    }
    
    public static func == (lhs: RedisKeyModel, rhs: RedisKeyModel) -> Bool {
           // 需要比较的值
           return lhs.id == rhs.id
       }
    
    var description: String {
        return "RedisKeyModel:[key:\(key), type:\(type), ttl:\(ttl)]"
    }
}
