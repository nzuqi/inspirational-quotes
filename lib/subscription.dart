import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:inspr/common.dart';

/// ID for a specific product you want to query
const String productID = 'inspr.pro.annual';

/// Is the API vailable on the device
bool subscriptionAvailable = true;

final InAppPurchase inAppPurchase = InAppPurchase.instance;
late StreamSubscription<List<PurchaseDetails>> subscription;

/// Products for sale
List<ProductDetails> products = [];

/// Store current subscription data
dynamic subscriptionData;

/// Past purchases
List<PurchaseDetails> purchases = [];

/// Initialize data
void initializePurchases() async {
  // Check availability of In App Purchases
  subscriptionAvailable = await inAppPurchase.isAvailable();
  if (subscriptionAvailable) {
    await _getProduct();
    // await getPastPurchases();
    // verifyPurchase();
  }
}

/// Get product subscription
Future<void> _getProduct() async {
  ProductDetailsResponse response =
      await inAppPurchase.queryProductDetails({productID});
  products = response.productDetails;
  // get & store the current product info
  for (var p in products) {
    subscriptionData = p;
    // print('${p.title}: ${p.description} (cost is ${p.price})');
  }
}

/// Gets past purchases
// Future<void> getPastPurchases() async {
//   QueryPurchaseDetailsResponse response = await inAppPurchase.queryPastPurchases();
//   for (PurchaseDetails purchase in response.pastPurchases) {
//     if (Platform.isIOS) {
//       InAppPurchaseConnection.instance.completePurchase(purchase);
//     }
//   }
//   purchases = response.pastPurchases;
//   print("Past Purchases >> ");
//   print(response.pastPurchases);
// }

/// Returns purchase of specific product ID
PurchaseDetails _hasPurchased(String productID) {
  return purchases.firstWhere((purchase) => purchase.productID == productID);
}

/// Verify purchase
dynamic verifyPurchase() {
  PurchaseDetails purchase = _hasPurchased(productID);
  // print("Purchase >>>>>>>>>>>>>>>>>>>>>============= ");
  // print(purchase.verificationData);
  String expiryTime = getSubscriptionExpiry();
  Map<String, dynamic> _data = {};
  if (purchase.status == PurchaseStatus.purchased) {
    _data = {
      'orderid': purchase.purchaseID,
      'purchasetime': purchase.transactionDate,
      'expirytime': expiryTime,
      'productid': purchase.productID,
      'status': true,
    };
    isSubscribed = true;
  } else {
    isSubscribed = false;
  }
  // print(_data);
  return _data;
}

//subscribe now
void buyProduct(ProductDetails prod) {
  final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
  try {
    inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    // inAppPurchase.buyConsumable(purchaseParam: purchaseParam, autoConsume: false);
  } catch (e) {
    print("Error >> ");
    print(e.toString());
  }
}
