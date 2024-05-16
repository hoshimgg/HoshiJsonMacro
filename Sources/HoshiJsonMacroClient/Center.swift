//
//  Center.swift
//
//
//  Created by 星空凛 on 2024/5/13.
//

import Foundation
import HoshiJsonMacro

class Center {
    var observers: [any ObserverP] = []
    
    func onDataChannel(cmd: String, jsonStr: String) {
        observers.removeAll { $0.lifeFlag == nil }
        for ob in observers where ob.cmd == cmd {
            let model = ob.type.init(jsonStr: jsonStr)
            ob.action(model)
        }
    }
    
    func onDataChannel(cmd: String, dict: [String:Any]) {
        observers.removeAll { $0.lifeFlag == nil }
        for ob in observers where ob.cmd == cmd {
            let model = ob.type.init(dict: dict)
            ob.action(model)
        }
    }
    
    func observerDC<T: HoshiDecodable>(cmd: String, cn: String, lifeFlag: AnyObject, class classType: T.Type, action: @escaping (T) -> Void) {
        let observer = Obersver(cmd: cmd, lifeFlag: lifeFlag, type: classType, block: action)
        observers.append(observer)
    }
}

protocol ObserverP {
    associatedtype T: HoshiDecodable
    var cmd: String { get }
    var lifeFlag: AnyObject? { get }
    var type: T.Type { get }
    func action(_: HoshiDecodable)
}

struct Obersver<T: HoshiDecodable>: ObserverP {
    let cmd: String
    weak var lifeFlag: AnyObject?
    let type: T.Type
    let block: (T) -> Void
    
    func action(_ model: HoshiDecodable) {
        guard let model = model as? T else { return }
        block(model)
    }
}

