import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth


@main
struct DemoAppApp: App {
    init() {
        FirebaseApp.configure()
        let _ = Auth.auth()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

