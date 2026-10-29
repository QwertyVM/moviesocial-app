import SwiftUI

public struct MovieSocialAppView: View {
    @State private var environment = AppEnvironment()
    
    public init() {}
    
    public var body: some View {
        RootTabView(environment: environment)
            .preferredColorScheme(.dark)
    }
}
