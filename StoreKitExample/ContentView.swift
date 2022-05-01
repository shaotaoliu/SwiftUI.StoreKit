import SwiftUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        TabView {
            ProductListView()
                .tabItem {
                    Image(systemName: "command.circle")
                    Text("Products")
                }
            
            PurchaseListView()
                .tabItem {
                    Image(systemName: "line.3.horizontal.circle")
                    Text("Purchases")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
