# HoshiJsonMacro - Swift Decode

## Swift 序列化/反序列化库

> 纯Swift实现，功能和易用性媲美YYModel！

### 反序列化功能

1. 自动驼峰命名转下划线命名
2. 支持自定义变量名映射
3. 支持默认值和可选类型
4. 支持结构体和类，可以嵌套
5. 支持使用json字符串和swift/OC字典进行反序列化
6. 支持自定义反序列化过程
7. 支持`[String:Any]`作为实例变量
8. 兼容bool值和int值
9. 兼容String和int值

### 序列化功能

1. 支持自动转换为json字符串和dict
2. 支持序列化`[String:Any]`

### 其他功能

1. 自动为类生成description，可直接打印所有参数
2. 自动生成`==`和`isEqual(_:)`方法，且支持指定不参与比较的属性
3. 自动根据成员变量生成`public init`方法(`HoshiInit`宏提供)，且支持默认值。注：目前必须显示声明变量类型，以后会优化
4. 支持copy方法

*Demo中顺便附带了一个使用泛型实现的纯swift观察者模式*
