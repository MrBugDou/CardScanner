import Foundation

private class BundleClass {}

public extension Bundle {
    /// 框架 bundle
    static var coreBundle: Bundle {
        let mainBundle: Bundle = .init(for: BundleClass.self)
        if let resourcePath = mainBundle.path(forResource: "CoreBundle", ofType: "bundle") {
            return Bundle(path: resourcePath) ?? mainBundle
        }
        return mainBundle
    }
}
