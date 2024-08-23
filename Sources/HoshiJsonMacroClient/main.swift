import Foundation
import HoshiJsonMacro

@HoshiJson struct GridLinkMemberExtra {
    var price: Int = 0
    var priceText: String = ""
}

let dict: [String:Any] = ["price": HSJsonObj(100), "price_text": HSJsonObj("100元")]
let dict2: [String:Any] = ["price": 100, "price_text": "100元"]
let extra = GridLinkMemberExtra(dict: dict2)
print(extra)
