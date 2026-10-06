import SwiftUI

struct ContentView: View {
    var store: RemontoireStore

    var body: some View {
        RemontoireChrome(store: store)
    }
}

#Preview {
    ContentView(store: RemontoireStore(vault: ArborMemory()))
}
