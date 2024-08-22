import Foundation

@objcMembers class A: NSObject {
    let a: Int
    
    init(a: Int) {
        self.a = a
    }
    
//    public override func isEqual(_ object: Any?) -> Bool {
//        guard let obj = object as? A else { return false }
//        return a == obj.a
//    }
}

let a = A(a: 1)
let b = A(a: 1)
print(a == b)
