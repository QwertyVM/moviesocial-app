import SwiftUI
import MovieSocialApp
import Foundation
import ObjectiveC

#if os(iOS)
private let swizzleBundleIdentifierOnce: Void = {
    let bundleClass: AnyClass = Bundle.self
    if let origBundleId = class_getInstanceMethod(bundleClass, #selector(getter: Bundle.bundleIdentifier)),
       let swizBundleId = class_getInstanceMethod(bundleClass, #selector(Bundle.movieSocial_bundleIdentifier)) {
        method_exchangeImplementations(origBundleId, swizBundleId)
    }
    
    if let origInfo = class_getInstanceMethod(bundleClass, #selector(getter: Bundle.infoDictionary)),
       let swizInfo = class_getInstanceMethod(bundleClass, #selector(Bundle.movieSocial_infoDictionary)) {
        method_exchangeImplementations(origInfo, swizInfo)
    }
}()

extension Bundle {
    @objc func movieSocial_bundleIdentifier() -> String? {
        if let original = self.movieSocial_bundleIdentifier(), !original.isEmpty {
            return original
        }
        return "com.moviesocial.app"
    }
    
    @objc func movieSocial_infoDictionary() -> [String: Any]? {
        var dict = self.movieSocial_infoDictionary() ?? [:]
        if dict["CFBundleIdentifier"] == nil {
            dict["CFBundleIdentifier"] = "com.moviesocial.app"
        }
        if dict["CFBundleName"] == nil {
            dict["CFBundleName"] = "MovieSocial"
        }
        return dict
    }
}
#endif

struct RunnerApp: App {
    var body: some Scene {
        WindowGroup {
            MovieSocialAppView()
                #if os(macOS)
                .frame(minWidth: 400, idealWidth: 430, maxWidth: 480, minHeight: 700, idealHeight: 844)
                #endif
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}

@main
enum MainLauncher {
    static func main() {
        #if os(iOS)
        _ = swizzleBundleIdentifierOnce
        #endif
        RunnerApp.main()
    }
}
