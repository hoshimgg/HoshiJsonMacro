import Foundation

let test1 = ClassTestC()
var test2 = ClassTestC()

test2.intA = 4

print(test1.isEqual(test2))

let test3 = ClassTestB()
var test4 = ClassTestB()
test4.customInt_b = 5

print(test3 == test4)
