import SwiftUI
import StoreKit

struct PurchaseListView: View {
    @EnvironmentObject var vm: ViewModel

    var body: some View {
        NavigationView {
            List {
                if !vm.purchasedConsumableProducts.isEmpty {
                    ProductSection(productType: .consumable, products: vm.purchasedConsumableProducts)
                }
                
                if !vm.purchasedNonConsumableProducts.isEmpty {
                    ProductSection(productType: .nonConsumable, products: vm.purchasedNonConsumableProducts)
                }
                
                if !vm.purchasedSubscriptions.isEmpty {
                    ProductSection(productType: .autoRenewable, products: vm.purchasedSubscriptions)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Purchases")
        }
        .onAppear {
            Task {
                await vm.refreshPurchasedProducts()
            }
        }
    }
    
    struct ProductSection: View {
        let productType: ProductType
        let products: [Product]
        
        var body: some View {
            Section(header: Text(productType.rawValue.uppercased()).font(.title3).bold()) {
                ForEach(products, id: \.id) { product in
                    NavigationLink(destination: ProductView(product: product), label: {
                        HStack {
                            Image(product.id)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .clipped()
                            
                            Text(product.displayName)
                                .font(.system(size: 18).bold())
                        }
                    })
                }
            }
        }
    }
}

struct PurchaseListView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseListView()
    }
}
