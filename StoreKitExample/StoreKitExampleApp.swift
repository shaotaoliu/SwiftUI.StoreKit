import SwiftUI

@main
struct StoreKitExampleApp: App {
    private let vm = ViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .onAppear {
                    UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
                }
                .task() {
                    await vm.fetchProducts()
                }
        }
    }
}
