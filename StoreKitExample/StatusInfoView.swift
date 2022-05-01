import SwiftUI
import StoreKit

struct StatusInfoView: View {
    
    @EnvironmentObject var vm: ViewModel
    let product: Product
    let status: ProductStatus

    var body: some View {
        Text(statusDescription())
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }

    //Build a string description of the subscription status to display to the user.
    fileprivate func statusDescription() -> String {
        
        guard case .verified(let renewalInfo) = status.renewalInfo,
              case .verified(let transaction) = status.transaction else {
            return "The App Store could not verify your subscription status."
        }

        var description = ""
        
        switch status.state {
        case .subscribed:
            description = "You are currently subscribed to \(product.displayName)."
            
        case .expired:
            if let expirationDate = transaction.expirationDate,
               let expirationReason = renewalInfo.expirationReason {
                description = expirationDescription(expirationReason, expirationDate: expirationDate)
            }
            
        case .revoked:
            if let revokedDate = transaction.revocationDate {
                description = "Your subscription to \(product.displayName) was refunded on \(revokedDate.formatted())."
            }
            
        case .inGracePeriod:
            description = gracePeriodDescription(renewalInfo)
            
        case .inBillingRetryPeriod:
            description = "The App Store could not confirm your billing information for \(product.displayName). Please verify your billing information to resume service."
            
        default:
            break
        }

        if let expirationDate = transaction.expirationDate {
            description += renewalDescription(renewalInfo, expirationDate)
        }
        return description
    }

    fileprivate func gracePeriodDescription(_ renewalInfo: RenewalInfo) -> String {
        var description = "The App Store could not confirm your billing information for \(product.displayName)."
        
        if let date = renewalInfo.gracePeriodExpirationDate {
            description += " Please verify your billing information to continue service after \(date.formatted())"
        }

        return description
    }

    func renewalDescription(_ renewalInfo: RenewalInfo, _ expirationDate: Date) -> String {
        
        if let newProductID = renewalInfo.autoRenewPreference,
           let newProduct = vm.autoRenewableProducts.first(where: { $0.id == newProductID }) {
            return "\nYour subscription to \(newProduct.displayName) will begin when your current subscription expires on \(expirationDate.formatted())."
        }
        
        if renewalInfo.willAutoRenew {
            return "\nNext billing date: \(expirationDate.formatted())."
        }
        
        return ""
    }

    //Build a string description of the 'expirationReason' to display to the user.
    func expirationDescription(_ expirationReason: ExpirationReason, expirationDate: Date) -> String {
        switch expirationReason {
        case .autoRenewDisabled:
            if expirationDate > Date() {
                return "Your subscription will expire on \(expirationDate.formatted())."
            }
            return "Your subscription expired on \(expirationDate.formatted())."

        case .billingError:
            return "Your subscription was not renewed due to a billing error."
            
        case .didNotConsentToPriceIncrease:
            return "Your subscription was not renewed due to a price increase that you disapproved."
            
        case .productUnavailable:
            return "Your subscription was not renewed because the product is no longer available."
            
        default:
            return "Your subscription was not renewed."
        }
    }
}

extension Date {
    
    func formatted() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: self)
    }
}
