import Foundation
import HoshiJsonMacro

@HoshiInit
@objcMembers public class BLMultiChatCellInfo: NSObject {
    public let position: Int
    public let style: CellStyle
    public var name: String = ""
    public var avatarUrl: String = ""
    public var giftText: String = ""
    public var isAdmin: Bool = false
    public var isMute: Bool = false
    public var uid: Int = 0
    public var isMystery: Bool = false
    public var muteFromUID: String = ""
    public var oppositeAnchorUID: Int = 0  // test
}

@objc(BLMultiChatCellStyle) public enum CellStyle: Int {
    case empty  // 空麦位
    case seating  // 入座中
    case seated  // 有人
}

let info = BLMultiChatCellInfo(position: 2, style: .seating, name: "haha")
print(info.name)

print("= .a  // test".components(separatedBy: "//").first ?? "")
