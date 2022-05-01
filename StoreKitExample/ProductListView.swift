import SwiftUI
import StoreKit

struct ProductListView: View {
    @EnvironmentObject var vm: ViewModel

    var body: some View {
        NavigationView {
            List {
                ProductSection(productType: .consumable, products: vm.consumableProducts)
                
                ProductSection(productType: .nonConsumable, products: vm.nonConsumableProducts)
                
                ProductSection(productType: .autoRenewable, products: vm.autoRenewableProducts)
            }
            .listStyle(.plain)
            .navigationTitle("Products")
        }
    }
    
    struct ProductSection: View {
        let productType: ProductType
        let products: [Product]
        
        var body: some View {
            Section(header: Text(productType.rawValue.uppercased()).font(.title3).bold()) {
                ForEach(products, id: \.id) { product in
                    NavigationLink(destination: ProductView(product: product), label: {
                        VStack(spacing: 5) {
                            HStack {
                                Text(product.displayName)
                                Spacer()
                                Text(product.displayPrice)
                            }
                            .font(.system(size: 18).bold())

                            Text(product.description)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    })
                }
            }
        }
    }
}

struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        ProductListView()
    }
}
