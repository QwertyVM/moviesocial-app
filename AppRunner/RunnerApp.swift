import SwiftUI
import MovieSocialApp

@main
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
