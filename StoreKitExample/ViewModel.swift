import Foundation
import StoreKit

typealias ProductType = Product.ProductType
typealias ProductStatus = Product.SubscriptionInfo.Status
typealias RenewalInfo = Product.SubscriptionInfo.RenewalInfo
typealias ExpirationReason = Product.SubscriptionInfo.RenewalInfo.ExpirationReason

class ViewModel: ObservableObject {

    @Published private(set) var consumableProducts: [Product] = []
    @Published private(set) var nonConsumableProducts: [Product] = []
    @Published private(set) var autoRenewableProducts: [Product] = []
    @Published private(set) var purchasedIds: Set<String> = []
    
    @Published private(set) var purchasedConsumableProducts: [Product] = []
    @Published private(set) var purchasedNonConsumableProducts: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    
    var task: Task<Void, Error>? = nil
    
    init() {
        task = listenForTransaction()
    }

    deinit {
        task?.cancel()
    }
    
    func listenForTransaction() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.checkResult(result)
            }
        }
    }
    
    @MainActor
    func fetchProducts() async {
        do {
            let products = try await Product.products(for: [
                "com.apple.mac",
                "com.apple.pad",
                "com.apple.phone",
                "com.apple.watch",
                "com.amzn.backpack",
                "com.amzn.scooter",
                "com.amzn.headphone",
                "com.sub.home",
                "com.sub.living"
            ])
            
            for product in products {
                switch product.type {
                case .consumable:
                    self.consumableProducts.append(product)
                    
                case .nonConsumable:
                    self.nonConsumableProducts.append(product)
                    
                case .autoRenewable:
                    self.autoRenewableProducts.append(product)
                    
                default:
                    print("Unknown product: \(product.id)")
                }
            }
        }
        catch {
            print("\(error)")
        }
    }
    
    @MainActor
    @discardableResult
    private func checkResult(_ result: VerificationResult<Transaction>) async -> Transaction? {
        switch result {
        case .verified(let transaction):
            
            if transaction.revocationDate == nil {
                purchasedIds.insert(transaction.productID)
            } else {
                purchasedIds.remove(transaction.productID)
            }
            
            await transaction.finish()
            return transaction
                
        case .unverified(_, _):
            print("Transaction failed verification.")
            return nil
        }
    }
    
    func purchase(product: Product, quantity: Int = 1) async -> Transaction? {
        do {
            let result = try await product.purchase(options: [
                .quantity(quantity)
            ])
            
            switch result {
            case .success(let result):
                return await checkResult(result)
                
            case .userCancelled:
                print("User cancelled purchase.")
                
            case .pending:
                print("The purchase is pending. Please check your email for reason.")
                
            @unknown default:
                break
            }
        }
        catch {
            print("\(error)")
        }
        
        return nil
    }
    
    func isPurchased(productID: String) async -> Bool {
        // Get the most recent transaction receipt for this product.
        // If there is no latest transaction, the product has not been purchased.
        guard let result = await Transaction.latest(for: productID) else {
            return false
        }

        switch result {
        case .verified(let transaction):
            // Ignore revoked transactions, they're no longer purchased.

            // For subscriptions, a user can upgrade in the middle of their subscription period.
            // The lower service tier will then have the 'isUpgraded' flag set and
            // there will be a new transaction for the higher service tier.
            // Ignore the lower service tier transactions which have been upgraded.
            return transaction.revocationDate == nil && !transaction.isUpgraded
            
        case .unverified(_, _):
            return false
        }
    }
    
    @MainActor
    func refreshPurchasedProducts() async {
        var consumables: [Product] = []
        var nonconsumables: [Product] = []
        var subscriptions: [Product] = []

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                switch transaction.productType {
                case .consumable:
                    if let product = consumableProducts.first(where: { $0.id == transaction.productID }) {
                        consumables.append(product)
                    }
                    
                case .nonConsumable:
                    if let product = nonConsumableProducts.first(where: { $0.id == transaction.productID }) {
                        nonconsumables.append(product)
                    }
                    
                case .autoRenewable:
                    if let subscription = autoRenewableProducts.first(where: { $0.id == transaction.productID }) {
                        subscriptions.append(subscription)
                    }
                    
                default:
                    break
                }
            }
        }
        
        self.purchasedConsumableProducts = consumables
        self.purchasedNonConsumableProducts = nonconsumables
        self.purchasedSubscriptions = subscriptions
    }

}
