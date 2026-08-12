import SwiftUI

#if !SWIFTPM
@main
struct LocalMindApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
#endif
