# SwiftUI.StoreKit

This app shows how to use StoreKit.

Fetch the products:

```Swift
let products = try await Product.products(for: [
    "com.apple.phone",
    "com.apple.watch",
    "com.apple.mac"
])

for product in products {
    print(product.id)
    print(product.displayName)
    print(product.displayPrice)
    print(product.description)
    print(product.price)
}

```

![image](https://user-images.githubusercontent.com/15805568/166134113-bb589da6-ce3f-40d1-94c7-65b57a73d2fe.png)

The following shows how to make a purchase.

```Swift
let result = try await product.purchase()

switch result {
case .success(let status):
    switch status {
    case .verified(let transaction):
        purchasedIds.insert(transaction.productID)
        await transaction.finish()
            
    case .unverified(_, _):
        print("Transaction failed verification.")
    }
    
case .userCancelled:
    print("User cancelled purchase.")
    
case .pending:
    print("The purchase is pending. Please check your email for reason.")
    
@unknown default:
    break
}
```

![image](https://user-images.githubusercontent.com/15805568/166134144-286e0248-6520-4b72-baec-eb4f1514c5ca.png)

The following shows how to check if a product has been purchased.

```Swift
guard let result = await Transaction.latest(for: productID) else {
    return false
}

switch result {
case .verified(_):
    return true
    
case .unverified(_, _):
    return false
}
```

![image](https://user-images.githubusercontent.com/15805568/166134154-3c518462-0703-4e9e-985e-11507feca797.png)
