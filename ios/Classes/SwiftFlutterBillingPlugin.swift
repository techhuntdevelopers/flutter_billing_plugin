import Flutter
import UIKit

var isProductPurchased : Bool = Bool()
var secretKey : String = "a59d0387edeb46e594fc00be5463ab7f"

// let verifyReceiptURL = "https://sandbox.itunes.apple.com/verifyReceipt" //sendbox
var verifyReceiptURL = "https://buy.itunes.apple.com/verifyReceipt" //production
var isProductRestored : Bool = false

var channel: FlutterMethodChannel!

public class SwiftFlutterBillingPlugin: NSObject, FlutterPlugin {
    
    var exDate : Date = Date()
    var isfail : Bool = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "flutter_billing", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterBillingPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "init") {
            var productIds = Array<String>()
            let arguments = call.arguments as! [String:Any]
            productIds = arguments["product_ids"] as! [String]
            secretKey = arguments["secret_key"] as! String
            var isSendbox = arguments["is_sendbox"] as! Bool

            if(isSendbox) {
                verifyReceiptURL = "https://sandbox.itunes.apple.com/verifyReceipt"
            } else {
                verifyReceiptURL = "https://buy.itunes.apple.com/verifyReceipt"
            }
            for product in productIds {
                print("init",product)
            }
            InAppPurchaseManager.sharedManager.start(productIDs: productIds,withHandler: DemoTransactionHandler())
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.handlePurchaseNotification(_:)),
                                                   name: .IAPHelperPurchaseNotification,
                                                   object: nil)
            self.receiptValidation()
        } else if (call.method == "get_price") {
            let arguments = call.arguments as! [String:Any]
            let productId = arguments["product_id"] as! String
            print("get_price",productId)
            self.fetchProductPrice()
        } else if (call.method == "buy_product") {
            let arguments = call.arguments as! [String:Any]
            let productId = arguments["product_id"] as! String
            print("buy_product",productId)
            self.buyProduct()
        } else if (call.method == "check_restore") {
            print("check_restore", "RESTORE")
            InAppPurchaseManager.sharedManager.restoringPurchases()
        } else {
            result(FlutterMethodNotImplemented);
        }
    }
    
    @objc func handlePurchaseNotification(_ notification: Notification)
    {
        isfail = true
        if let identifier : String = notification.object as? String
        {
            if identifier.prefix(4) == "Fail" {
                // failed
                channel.invokeMethod("error", arguments: false)
            }
            else
            {
                isProductPurchased = true
                channel.invokeMethod("success", arguments: false)
                //successfully purchased callback
            }
        }
    }
    
    func buyProduct()
    {
        guard let product = InAppPurchaseManager.sharedManager.availableProducts()?[0] else {
            return
        }
        
        let price = product.price
        InAppPurchaseManager.sharedManager.purchaseProduct(product) { (receipts, error) in
            if let error = error {
                print(String(describing: error))
            } else if let receipts = receipts {
                print("Congrats! Here are you receipts for your purchases: \(receipts)")
            }
        }
    }
    
    func fetchProductPrice()
    {
        guard let product = InAppPurchaseManager.sharedManager.availableProducts()?[0] else {
            return
        }
        
        let price = product.price
        var localizedPrice: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceLocale
            return formatter.string(from: price)!
        }
        print("fetchPrice",localizedPrice)
        channel.invokeMethod("price", arguments:localizedPrice)
    }
    
    public func receiptValidation() {
        let receiptFileURL = Bundle.main.appStoreReceiptURL
        let receiptData = try? Data(contentsOf: receiptFileURL!)
        let recieptString = receiptData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue:0))
        if recieptString != nil
        {
            let jsonDict: [String: AnyObject] = ["receipt-data" : recieptString! as AnyObject, "password" :secretKey as AnyObject]
            
            do {
                let requestData = try JSONSerialization.data(withJSONObject: jsonDict, options:JSONSerialization.WritingOptions.prettyPrinted)
                let storeURL = URL(string: verifyReceiptURL)!
                var storeRequest = URLRequest(url: storeURL)
                storeRequest.httpMethod = "POST"
                storeRequest.httpBody = requestData
                
                let session = URLSession(configuration: URLSessionConfiguration.default)
                let task = session.dataTask(with: storeRequest, completionHandler: { [weak self] (data,response, error) in
                    do {
                        if data != nil
                        {
                            let jsonResponse = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers)
                            if let datee = self?.getExpirationDateFromResponse(jsonResponse as! NSDictionary) {
                                
                                self?.exDate = datee
                                DispatchQueue.main.async {
                                    self?.setvc()
                                }
                            }
                            else
                            {
                                DispatchQueue.main.async {
                                    self?.setvc()
                                }
                            }
                        }
                        else
                        {
                            DispatchQueue.main.async {
                                self?.setvc()
                            }
                        }
                    } catch let parseError {
                        print(parseError)
                        DispatchQueue.main.async {
                            self?.setvc()
                        }
                    }
                })
                task.resume()
            } catch let parseError {
                print(parseError)
                self.setvc()
            }
        }
        else
        {
            self.setvc()
        }
    }
    
    func getExpirationDateFromResponse(_ jsonResponse: NSDictionary) -> Date? {
        print(jsonResponse)
        if let receiptInfo: NSArray = jsonResponse["latest_receipt_info"] as? NSArray {
            
            let lastReceipt = receiptInfo.lastObject as! NSDictionary
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
            
            if let expiresDate = lastReceipt["expires_date"] as? String {
                return formatter.date(from: expiresDate)
            }
            
            return nil
        }
        else {
            return nil
        }
    }
    
    func setvc()
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
        let date1 : String = formatter.string(from: Date())
        let dt : Date = formatter.date(from: date1)!
        switch exDate.compare(dt)
        {
        case .orderedAscending :
            print("isProductPurchased", "false")
            channel.invokeMethod("isProductPurchased", arguments: false)
            isProductPurchased = false
        case .orderedDescending  :
            print("\(exDate) > \(dt)")
            print("isProductPurchased", "true")
            channel.invokeMethod("isProductPurchased", arguments: true)
            isProductPurchased = true
            break
        case .orderedSame:
            print("Date()")
            print("isProductPurchased", "false")
            channel.invokeMethod("isProductPurchased", arguments: false)
            isProductPurchased = false
        }
        
    }
}
