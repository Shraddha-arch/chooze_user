import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:efood_multivendor/controller/order_controller.dart';
import 'package:efood_multivendor/controller/user_controller.dart';
import 'package:efood_multivendor/data/model/response/order_model.dart';
import 'package:efood_multivendor/helper/route_helper.dart';
import 'package:efood_multivendor/util/app_constants.dart';
import 'package:efood_multivendor/util/dimensions.dart';
import 'package:efood_multivendor/util/images.dart';
import 'package:efood_multivendor/view/base/custom_app_bar.dart';
import 'package:efood_multivendor/view/base/custom_button.dart';
import 'package:efood_multivendor/view/screens/checkout/widget/payment_failed_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:pay/pay.dart';

import '../../../controller/coupon_controller.dart';
import '../../../data/model/body/place_order_body.dart';
import '../../../data/model/response/address_model.dart';
import '../../../data/model/response/cart_model.dart';
import '../../../helper/date_converter.dart';
import '../../base/custom_snackbar.dart';

class PaymentScreen extends StatefulWidget {
  final OrderModel orderModel;
  PaymentScreen({@required this.orderModel});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedUrl = '';
  double value = 0.0;
  bool _isLoading = true;
  PullToRefreshController pullToRefreshController;
  MyInAppBrowser browser;
  bool isCheckedGooglePay = false;
  bool isCheckedPhonePe = false;
  bool isCheckedOther = false;
  String payID;
  String amount;

  @override
  void initState() {
    super.initState();
    selectedUrl =
        '${AppConstants.BASE_URL}/payment-mobile?customer_id=${widget.orderModel.userId}&order_id=${widget.orderModel.id}';

    payID = widget.orderModel.id.toString();
    amount = widget.orderModel.orderAmount.toString();
    // _initData();
  }

  void _initData() async {
    browser = MyInAppBrowser(
        orderID: widget.orderModel.id.toString(),
        orderAmount: widget.orderModel.orderAmount);

    if (Platform.isAndroid) {
      await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);

      bool swAvailable = await AndroidWebViewFeature.isFeatureSupported(
          AndroidWebViewFeature.SERVICE_WORKER_BASIC_USAGE);
      bool swInterceptAvailable =
          await AndroidWebViewFeature.isFeatureSupported(
              AndroidWebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);

      if (swAvailable && swInterceptAvailable) {
        AndroidServiceWorkerController serviceWorkerController =
            AndroidServiceWorkerController.instance();
        await serviceWorkerController
            .setServiceWorkerClient(AndroidServiceWorkerClient(
          shouldInterceptRequest: (request) async {
            print(request);
            return null;
          },
        ));
      }
    }

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.black,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          browser.webViewController.reload();
        } else if (Platform.isIOS) {
          browser.webViewController.loadUrl(
              urlRequest:
                  URLRequest(url: await browser.webViewController.getUrl()));
        }
      },
    );
    browser.pullToRefreshController = pullToRefreshController;

    await browser.openUrlRequest(
      urlRequest: URLRequest(url: Uri.parse(selectedUrl)),
      options: InAppBrowserClassOptions(
        crossPlatform: InAppBrowserOptions(
          hideUrlBar: true,
          hideToolbarTop: true,
          hideProgressBar: true,
          // hidden: true
        ),
        inAppWebViewGroupOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
              useShouldOverrideUrlLoading: true, useOnLoadResource: true),
        ),
      ),
    );
  }

  // List<PaymentItem> _paymentItems = [];

  void onGooglePayResult(paymentResult) {
    print('payment info  ${paymentResult} ');
    // Send the resulting Google Pay token to your server / PSP
  }

  // String defaultGooglePay = '''{
  //     "provider": "google_pay",
  //     "data": {
  //       "environment": "TEST",
  //       "apiVersion": 2,
  //       "apiVersionMinor": 0,
  //       "allowedPaymentMethods": [
  //         {
  //           "type": "CARD",
  //           "tokenizationSpecification": {
  //             "type": "PAYMENT_GATEWAY",
  //             "parameters": {
  //               "gateway": "example",
  //               "gatewayMerchantId": "gatewayMerchantId"
  //             }
  //           },
  //           "parameters": {
  //             "allowedCardNetworks": ["VISA", "MASTERCARD"],
  //             "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
  //             "billingAddressRequired": true,
  //             "billingAddressParameters": {
  //               "format": "FULL",
  //               "phoneNumberRequired": true
  //             }
  //           }
  //         }
  //       ],
  //       "merchantInfo": {
  //         "merchantId": "01234567890123456789",
  //         "merchantName": "Example Merchant Name"
  //       },
  //       "transactionInfo": {
  //         "countryCode": "IN",
  //         "currencyCode": "INR"
  //       }
  //     }
  //   }''';
  String defaultGooglePay = '''{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "example",
            "gatewayMerchantId": "gatewayMerchantId"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["VISA", "MASTERCARD"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": true,
          "billingAddressParameters": {
            "format": "FULL",
            "phoneNumberRequired": true
          }
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "01234567890123456789",
      "merchantName": "Example Merchant Name"
    },
    "transactionInfo": {
      "countryCode": "US",
      "currencyCode": "USD"
    }
  }
}''';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _exitApp(),
      child: Scaffold(
        // backgroundColor: Theme.of(context).primaryColor,
        appBar:
            CustomAppBar(title: 'payment'.tr, onBackPressed: () => _exitApp()),
        // body: Center(
        //   child: Container(
        //     width: Dimensions.WEB_MAX_WIDTH,
        //     child: Stack(
        //       children: [
        //         // _isLoading
        //         //     ? Center(
        //         //         child: CircularProgressIndicator(
        //         //             valueColor: AlwaysStoppedAnimation<Color>(
        //         //                 Theme.of(context).primaryColor)),
        //         //       )
        //         //     :
        //         Container(
        //           child: Center(
        //             child: ElevatedButton(
        //                 onPressed: () {
        //                   print('rayzorpay');
        //                   // browser = MyInAppBrowser(
        //                   //     orderID: widget.orderModel.id.toString(),
        //                   //     orderAmount: widget.orderModel.orderAmount);
        //                   _initData();
        //                 },
        //                 child: Text('Google Pay')),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
        body: SingleChildScrollView(
            child: Column(
          children: [
            gpayWidget(),
            // GooglePayButton(
            //     paymentConfiguration:
            //         PaymentConfiguration.fromJsonString(defaultGooglePay),
            //     onPaymentResult: (data) {
            //       print(data);
            //     },
            //     paymentItems: [
            //       PaymentItem(amount: '100'),
            //     ]),
            GooglePayButton(
              paymentConfiguration:
                  PaymentConfiguration.fromJsonString(defaultGooglePay),
              // paymentConfiguration: 'assets/json_file/gpay.json',
              paymentItems: [
                PaymentItem(
                  label: '${widget.orderModel.id.toString()}',
                  amount: '${widget.orderModel.orderAmount.toString()}',
                  status: PaymentItemStatus.final_price,
                )
              ],
              type: GooglePayButtonType.pay,
              margin: const EdgeInsets.only(top: 15.0),
              onPaymentResult: onGooglePayResult,
              loadingIndicator: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            upiWidget(),
          ],
        )),
      ),
    );
  }

  gpayWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16),
          child: Text(
            'Preferred Payment',
            style: TextStyle(
                fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.only(top: 16, left: 16, right: 16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                      margin: EdgeInsets.only(right: 10),
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Image.asset(Images.gpay)),
                  Text(
                    'Google Pay',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 16),
                  ),
                  Spacer(),
                  Checkbox(
                    checkColor: Colors.white,
                    fillColor: MaterialStateProperty.all(Color(0xff2DA94F)),
                    value: isCheckedGooglePay,
                    shape: CircleBorder(),
                    onChanged: (bool value) {
                      setState(() {
                        isCheckedGooglePay = value;
                        isCheckedPhonePe = false;
                        isCheckedOther = false;
                      });
                    },
                  )
                ],
              ),
              isCheckedGooglePay
                  ? InkWell(
                      onTap: () {
                        print('gpay');
                        _initData();
                      },
                      child: Container(
                        height: 50,
                        margin: EdgeInsets.only(left: 40, right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xff2DA94F),
                        ),
                        child: Center(
                          child: Text(
                            'PAY VIA GOOGLEPAY',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  : SizedBox.shrink()
            ],
          ),
        )
      ],
    );
  }

  upiWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16),
          child: Text(
            'UPI',
            style: TextStyle(
                fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.only(top: 16, left: 16, right: 16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                      margin: EdgeInsets.only(right: 10),
                      height: 35,
                      width: 35,
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Image.asset(Images.phonepe)),
                  Text(
                    'PhonePe UPI',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 16),
                  ),
                  Spacer(),
                  Checkbox(
                    checkColor: Colors.white,
                    fillColor: MaterialStateProperty.all(Color(0xff6739B7)),
                    value: isCheckedPhonePe,
                    shape: CircleBorder(),
                    onChanged: (bool value) {
                      setState(() {
                        isCheckedPhonePe = value;
                        isCheckedGooglePay = false;
                        isCheckedOther = false;
                      });
                    },
                  )
                ],
              ),
              isCheckedPhonePe
                  ? InkWell(
                      onTap: () {
                        print('phonpe');
                        _initData();
                      },
                      child: Container(
                        height: 50,
                        margin: EdgeInsets.only(left: 40, right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xff6739B7),
                        ),
                        child: Center(
                          child: Text(
                            'PAY VIA PHONEPE',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
              Row(
                children: [
                  Container(
                      margin: EdgeInsets.only(right: 10),
                      height: 35,
                      width: 35,
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Image.asset(
                        Images.log_out,
                        color: Theme.of(context).primaryColor,
                      )),
                  Text(
                    'Other',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 16),
                  ),
                  Spacer(),
                  Checkbox(
                    checkColor: Colors.white,
                    fillColor: MaterialStateProperty.all(
                        Theme.of(context).primaryColor),
                    value: isCheckedOther,
                    shape: CircleBorder(),
                    onChanged: (bool value) {
                      setState(() {
                        isCheckedOther = value;
                        isCheckedGooglePay = false;
                        isCheckedPhonePe = false;
                      });
                    },
                  )
                ],
              ),
              isCheckedOther
                  ? InkWell(
                      onTap: () {
                        print('other');
                        _initData();
                      },
                      child: Container(
                        height: 50,
                        margin: EdgeInsets.only(left: 40, right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).primaryColor,
                        ),
                        child: Center(
                          child: Text(
                            'Other',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
              // GetBuilder<OrderController>(
              //   builder: (orderController) {
              //     return Container(
              //       width: Dimensions.WEB_MAX_WIDTH,
              //       alignment: Alignment.center,
              //       padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
              //       child: !orderController.isLoading
              //           ? CustomButton(
              //               buttonText: 'confirm_order'.tr,
              //               onPressed: () {
              //                 // bool _isAvailable = true;
              //                 // DateTime _scheduleStartDate = DateTime.now();
              //                 // DateTime _scheduleEndDate = DateTime.now();
              //                 // if (orderController.timeSlots == null ||
              //                 //     orderController.timeSlots.length == 0) {
              //                 //   _isAvailable = false;
              //                 // } else {
              //                 //   DateTime _date =
              //                 //       orderController.selectedDateSlot == 0
              //                 //           ? DateTime.now()
              //                 //           : DateTime.now().add(Duration(days: 1));
              //                 //   DateTime _startTime = orderController
              //                 //       .timeSlots[orderController.selectedTimeSlot]
              //                 //       .startTime;
              //                 //   DateTime _endTime = orderController
              //                 //       .timeSlots[orderController.selectedTimeSlot]
              //                 //       .endTime;
              //                 //   _scheduleStartDate = DateTime(
              //                 //       _date.year,
              //                 //       _date.month,
              //                 //       _date.day,
              //                 //       _startTime.hour,
              //                 //       _startTime.minute + 1);
              //                 //   _scheduleEndDate = DateTime(
              //                 //       _date.year,
              //                 //       _date.month,
              //                 //       _date.day,
              //                 //       _endTime.hour,
              //                 //       _endTime.minute + 1);
              //                 //   for (CartModel cart in _cartList) {
              //                 //     if (!DateConverter.isAvailable(
              //                 //           cart.product.availableTimeStarts,
              //                 //           cart.product.availableTimeEnds,
              //                 //           time: restController
              //                 //                   .restaurant.scheduleOrder
              //                 //               ? _scheduleStartDate
              //                 //               : null,
              //                 //         ) &&
              //                 //         !DateConverter.isAvailable(
              //                 //           cart.product.availableTimeStarts,
              //                 //           cart.product.availableTimeEnds,
              //                 //           time: restController
              //                 //                   .restaurant.scheduleOrder
              //                 //               ? _scheduleEndDate
              //                 //               : null,
              //                 //         )) {
              //                 //       _isAvailable = false;
              //                 //       break;
              //                 //     }
              //                 //   }
              //                 // }
              //                 // if (!_isCashOnDeliveryActive &&
              //                 //     !_isDigitalPaymentActive &&
              //                 //     !_isWalletActive) {
              //                 //   showCustomSnackBar(
              //                 //       'no_payment_method_is_enabled'.tr);
              //                 // } else if (_orderAmount <
              //                 //     restController.restaurant.minimumOrder) {
              //                 //   showCustomSnackBar(
              //                 //       '${'minimum_order_amount_is'.tr} ${restController.restaurant.minimumOrder}');
              //                 // } else if ((orderController.selectedDateSlot ==
              //                 //             0 &&
              //                 //         _todayClosed) ||
              //                 //     (orderController.selectedDateSlot == 1 &&
              //                 //         _tomorrowClosed)) {
              //                 //   showCustomSnackBar('restaurant_is_closed'.tr);
              //                 // } else if (orderController.timeSlots == null ||
              //                 //     orderController.timeSlots.length == 0) {
              //                 //   if (restController.restaurant.scheduleOrder) {
              //                 //     showCustomSnackBar('select_a_time'.tr);
              //                 //   } else {
              //                 //     showCustomSnackBar('restaurant_is_closed'.tr);
              //                 //   }
              //                 // } else if (!_isAvailable) {
              //                 //   showCustomSnackBar(
              //                 //       'one_or_more_products_are_not_available_for_this_selected_time'
              //                 //           .tr);
              //                 // } else if (orderController.orderType !=
              //                 //         'take_away' &&
              //                 //     orderController.distance == -1 &&
              //                 //     _deliveryCharge == -1) {
              //                 //   showCustomSnackBar(
              //                 //       'delivery_fee_not_set_yet'.tr);
              //                 // } else if (orderController.paymentMethodIndex ==
              //                 //         2 &&
              //                 //     Get.find<UserController>().userInfoModel !=
              //                 //         null &&
              //                 //     Get.find<UserController>()
              //                 //             .userInfoModel
              //                 //             .walletBalance <
              //                 //         _total) {
              //                 //   showCustomSnackBar(
              //                 //       'you_do_not_have_sufficient_balance_in_wallet'
              //                 //           .tr);
              //                 // } else {
              //                 //   List<Cart> carts = [];
              //                 //   for (int index = 0;
              //                 //       index < _cartList.length;
              //                 //       index++) {
              //                 //     CartModel cart = _cartList[index];
              //                 //     List<int> _addOnIdList = [];
              //                 //     List<int> _addOnQtyList = [];
              //                 //     cart.addOnIds.forEach((addOn) {
              //                 //       _addOnIdList.add(addOn.id);
              //                 //       _addOnQtyList.add(addOn.quantity);
              //                 //     });
              //                 //     carts.add(Cart(
              //                 //       cart.isCampaign ? null : cart.product.id,
              //                 //       cart.isCampaign ? cart.product.id : null,
              //                 //       cart.discountedPrice.toString(),
              //                 //       '',
              //                 //       cart.variation,
              //                 //       cart.quantity,
              //                 //       _addOnIdList,
              //                 //       cart.addOns,
              //                 //       _addOnQtyList,
              //                 //     ));
              //                 //   }
              //                 //   AddressModel _address =
              //                 //       _addressList[orderController.addressIndex];
              //                   orderController.placeOrder(
              //                       PlaceOrderBody(
              //                         cart: carts,
              //                         couponDiscountAmount:
              //                             Get.find<CouponController>().discount,
              //                         distance: orderController.distance,
              //                         couponDiscountTitle:
              //                             Get.find<CouponController>()
              //                                         .discount >
              //                                     0
              //                                 ? Get.find<CouponController>()
              //                                     .coupon
              //                                     .title
              //                                 : null,
              //                         scheduleAt: !restController
              //                                 .restaurant.scheduleOrder
              //                             ? null
              //                             : (orderController.selectedDateSlot ==
              //                                         0 &&
              //                                     orderController
              //                                             .selectedTimeSlot ==
              //                                         0)
              //                                 ? null
              //                                 : DateConverter.dateToDateAndTime(
              //                                     _scheduleStartDate),
              //                         orderAmount: _total,
              //                         orderNote: _noteController.text,
              //                         orderType: orderController.orderType,
              //                         paymentMethod: orderController
              //                                     .paymentMethodIndex ==
              //                                 0
              //                             ? 'cash_on_delivery'
              //                             : orderController
              //                                         .paymentMethodIndex ==
              //                                     1
              //                                 ? 'digital_payment'
              //                                 : orderController
              //                                             .paymentMethodIndex ==
              //                                         2
              //                                     ? 'wallet'
              //                                     : 'digital_payment',
              //                         couponCode: (Get.find<CouponController>()
              //                                         .discount >
              //                                     0 ||
              //                                 (Get.find<CouponController>()
              //                                             .coupon !=
              //                                         null &&
              //                                     Get.find<CouponController>()
              //                                         .freeDelivery))
              //                             ? Get.find<CouponController>()
              //                                 .coupon
              //                                 .code
              //                             : null,
              //                         restaurantId:
              //                             _cartList[0].product.restaurantId,
              //                         address: _address.address,
              //                         latitude: _address.latitude,
              //                         longitude: _address.longitude,
              //                         addressType: _address.addressType,
              //                         contactPersonName: _address
              //                                 .contactPersonName ??
              //                             '${Get.find<UserController>().userInfoModel.fName} '
              //                                 '${Get.find<UserController>().userInfoModel.lName}',
              //                         contactPersonNumber:
              //                             _address.contactPersonNumber ??
              //                                 Get.find<UserController>()
              //                                     .userInfoModel
              //                                     .phone,
              //                         discountAmount: _discount,
              //                         taxAmount: _tax,
              //                         road: _streetNumberController.text.trim(),
              //                         house: _houseController.text.trim(),
              //                         floor: _floorController.text.trim(),
              //                         dmTips: _tipController.text.trim(),
              //                       ),
              //                       _callback,
              //                       _total);
              //                 }
              //               )
              //           : Center(child: CircularProgressIndicator()),
              //     );
              //   },
              // ),
            ],
          ),
        )
      ],
    );
  }

  Future<bool> _exitApp() async {
    return Get.dialog(
        PaymentFailedDialog(orderID: widget.orderModel.id.toString()));
  }
}

class MyInAppBrowser extends InAppBrowser {
  final String orderID;
  final double orderAmount;
  MyInAppBrowser(
      {@required this.orderID,
      @required this.orderAmount,
      int windowId,
      UnmodifiableListView<UserScript> initialUserScripts})
      : super(windowId: windowId, initialUserScripts: initialUserScripts);

  bool _canRedirect = true;

  @override
  Future onBrowserCreated() async {
    print("\n\nBrowser Created!\n\n");
  }

  @override
  Future onLoadStart(url) async {
    print("\n\nStarted: $url\n\n");
    _redirect(url.toString());
  }

  @override
  Future onLoadStop(url) async {
    pullToRefreshController?.endRefreshing();
    print("\n\nStopped: $url\n\n");
    _redirect(url.toString());
  }

  @override
  void onLoadError(url, code, message) {
    pullToRefreshController?.endRefreshing();
    print("Can't load [$url] Error: $message");
  }

  @override
  void onProgressChanged(progress) {
    if (progress == 100) {
      pullToRefreshController?.endRefreshing();
    }
    print("Progress: $progress");
  }

  @override
  void onExit() {
    if (_canRedirect) {
      Get.dialog(PaymentFailedDialog(orderID: orderID));
    }
    print("\n\nBrowser closed!\n\n");
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      navigationAction) async {
    print("\n\nOverride ${navigationAction.request.url}\n\n");
    return NavigationActionPolicy.ALLOW;
  }

  @override
  void onLoadResource(response) {
    print("Started at: " +
        response.startTime.toString() +
        "ms ---> duration: " +
        response.duration.toString() +
        "ms " +
        (response.url ?? '').toString());
  }

  @override
  void onConsoleMessage(consoleMessage) {
    print("""
    console output:
      message: ${consoleMessage.message}
      messageLevel: ${consoleMessage.messageLevel.toValue()}
   """);
  }

  void _redirect(String url) {
    if (_canRedirect) {
      bool _isSuccess =
          url.contains('success') && url.contains(AppConstants.BASE_URL);
      bool _isFailed =
          url.contains('fail') && url.contains(AppConstants.BASE_URL);
      bool _isCancel =
          url.contains('cancel') && url.contains(AppConstants.BASE_URL);
      if (_isSuccess || _isFailed || _isCancel) {
        _canRedirect = false;
        close();
      }
      if (_isSuccess) {
        Get.offNamed(
            RouteHelper.getOrderSuccessRoute(orderID, 'success', orderAmount));
      } else if (_isFailed || _isCancel) {
        Get.offNamed(
            RouteHelper.getOrderSuccessRoute(orderID, 'fail', orderAmount));
      }
    }
  }
}
