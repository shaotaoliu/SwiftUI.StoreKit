import SwiftUI
import StoreKit

struct ProductView: View {
    @EnvironmentObject var vm: ViewModel
    @State var isPurchased = false
    @State var status: ProductStatus?
    let product: Product
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(product.displayPrice)
                    .font(.system(size: 20).bold())
                
                if let info = product.subscription {
                    subscriptionInfo(info)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding()
            
            Image(product.id)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
            
            Text(product.description)
            
            Button(isPurchased ? "Purchased" : "Buy Now") {
                Task {
                    if await vm.purchase(product: product) != nil {
                        withAnimation {
                            isPurchased = true
                        }
                    }
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isPurchased ? .green : .blue)
            .cornerRadius(5)
            .disabled(isPurchased)
            
            Spacer()
            
            if let status = status {
                StatusInfoView(product: product, status: status)
            }
        }
        .navigationTitle(product.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                isPurchased = await vm.isPurchased(productID: product.id)
                status = await getStatus(product: product)
            }
        }
        .onChange(of: vm.purchasedIds) { ids in
            Task {
                isPurchased = ids.contains(product.id)
                status = await getStatus(product: product)
            }
        }
    }
    
    func getStatus(product: Product) async -> ProductStatus? {
        guard let statuses = try? await product.subscription?.status else {
            return nil
        }
        
        return statuses.first(where: { $0.state != .expired && $0.state != .revoked })
    }
    
    func subscriptionInfo(_ info: Product.SubscriptionInfo) -> some View {
        
        let plural = info.subscriptionPeriod.value > 1
        let unit = getUnit(unit: info.subscriptionPeriod.unit)
        let text = " / \(info.subscriptionPeriod.value) \(unit)\(plural ? "s" : "")"
        
        return Text(text)
            .font(.system(size: 14))
    }
    
    func getUnit(unit: Product.SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        @unknown default:
            return ""
        }
    }
}

struct ProductView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
