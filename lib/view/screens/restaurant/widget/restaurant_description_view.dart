import 'package:efood_multivendor/controller/auth_controller.dart';
import 'package:efood_multivendor/controller/location_controller.dart';
import 'package:efood_multivendor/controller/restaurant_controller.dart';
import 'package:efood_multivendor/controller/splash_controller.dart';
import 'package:efood_multivendor/controller/wishlist_controller.dart';
import 'package:efood_multivendor/data/model/response/address_model.dart';
import 'package:efood_multivendor/data/model/response/restaurant_model.dart';
import 'package:efood_multivendor/helper/price_converter.dart';
import 'package:efood_multivendor/helper/responsive_helper.dart';
import 'package:efood_multivendor/helper/route_helper.dart';
import 'package:efood_multivendor/util/dimensions.dart';
import 'package:efood_multivendor/util/styles.dart';
import 'package:efood_multivendor/view/base/custom_image.dart';
import 'package:efood_multivendor/view/base/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../controller/order_controller.dart';
import 'dart:math' show cos, sqrt, asin;

class RestaurantDescriptionView extends StatelessWidget {
  final Restaurant restaurant;
  RestaurantDescriptionView({@required this.restaurant});

  double distance;
  double km;

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
  // double dd() async{
  //   km = await getDistance();
  // }

  @override
  Widget build(BuildContext context) {
    bool _isAvailable = Get.find<RestaurantController>()
        .isRestaurantOpenNow(restaurant.active, restaurant.schedules);
    Color _textColor =
        ResponsiveHelper.isDesktop(context) ? Colors.white : null;
    var lat = Get.find<LocationController>().getUserAddress().latitude;
    var long = Get.find<LocationController>().getUserAddress().longitude;
    // double km = getDistance();
    print('user lat  $lat  ');
    print('user long  $long ');
    print('restaurent lat  ${restaurant.latitude}');
    print('restaurent long  ${restaurant.longitude}');

    km = calculateDistance(double.parse(lat), double.parse(long),
        double.parse(restaurant.latitude), double.parse(restaurant.longitude));
    print('user lat  $lat and $long');
    // if (distance != null) {
    //   // print('distance  ${distance / 1000}');

    // }
    print('km $km ');

    return Column(children: [
      Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
          child: Stack(children: [
            CustomImage(
              image:
                  '${Get.find<SplashController>().configModel.baseUrls.restaurantImageUrl}/${restaurant.logo}',
              height: ResponsiveHelper.isDesktop(context) ? 80 : 60,
              width: ResponsiveHelper.isDesktop(context) ? 100 : 70,
              fit: BoxFit.cover,
            ),
            _isAvailable
                ? SizedBox()
                : Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(Dimensions.RADIUS_SMALL)),
                        color: Colors.black.withOpacity(0.6),
                      ),
                      child: Text(
                        'closed_now'.tr,
                        textAlign: TextAlign.center,
                        style: robotoRegular.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeSmall),
                      ),
                    ),
                  ),
          ]),
        ),
        SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            restaurant.name,
            style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeLarge, color: _textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
          Text(
            restaurant.address ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor),
          ),
          SizedBox(
              height: ResponsiveHelper.isDesktop(context)
                  ? Dimensions.PADDING_SIZE_EXTRA_SMALL
                  : 0),
          Row(children: [
            Text('minimum_order'.tr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: Theme.of(context).disabledColor,
                )),
            SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
            Text(
              PriceConverter.convertPrice(restaurant.minimumOrder),
              style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: Theme.of(context).primaryColor),
            ),
          ]),
        ])),
        SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
        InkWell(
          onTap: () => Get.toNamed(
              RouteHelper.getSearchRestaurantProductRoute(restaurant.id)),
          child: ResponsiveHelper.isDesktop(context)
              ? Container(
                  padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                  decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
                      color: Theme.of(context).primaryColor),
                  child: Center(child: Icon(Icons.search, color: Colors.white)),
                )
              : Icon(Icons.search, color: Theme.of(context).primaryColor),
        ),
        SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
        GetBuilder<WishListController>(builder: (wishController) {
          bool _isWished =
              wishController.wishRestIdList.contains(restaurant.id);
          return InkWell(
            onTap: () {
              if (Get.find<AuthController>().isLoggedIn()) {
                _isWished
                    ? wishController.removeFromWishList(restaurant.id, true)
                    : wishController.addToWishList(null, restaurant, true);
              } else {
                showCustomSnackBar('you_are_not_logged_in'.tr);
              }
            },
            child: ResponsiveHelper.isDesktop(context)
                ? Container(
                    padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                    decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
                        color: Theme.of(context).primaryColor),
                    child: Center(
                        child: Icon(
                            _isWished ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white)),
                  )
                : Icon(
                    _isWished ? Icons.favorite : Icons.favorite_border,
                    color: _isWished
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).disabledColor,
                  ),
          );
        }),
      ]),
      SizedBox(
          height: ResponsiveHelper.isDesktop(context)
              ? 30
              : Dimensions.PADDING_SIZE_SMALL),
      Row(children: [
        Expanded(child: SizedBox()),
        InkWell(
          onTap: () =>
              Get.toNamed(RouteHelper.getRestaurantReviewRoute(restaurant.id)),
          child: Column(children: [
            Row(children: [
              Icon(Icons.star, color: Theme.of(context).primaryColor, size: 20),
              SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
              Text(
                restaurant.avgRating.toStringAsFixed(1),
                style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall, color: _textColor),
              ),
            ]),
            SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
            Text(
              '${restaurant.ratingCount} ${'ratings'.tr}',
              style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: _textColor),
            ),
          ]),
        ),
        Expanded(child: SizedBox()),
        InkWell(
          onTap: () => Get.toNamed(RouteHelper.getMapRoute(
            AddressModel(
              id: restaurant.id,
              address: restaurant.address,
              latitude: restaurant.latitude,
              longitude: restaurant.longitude,
              contactPersonNumber: '',
              contactPersonName: '',
              addressType: '',
            ),
            'restaurant',
          )),
          child: Column(children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on,
                    color: Theme.of(context).primaryColor, size: 20),
                Text(
                  km.toStringAsFixed(1) + 'km',
                  style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall, color: _textColor),
                )
              ],
            ),
            SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
            Text('location'.tr,
                style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall, color: _textColor)),
          ]),
        ),
        Expanded(child: SizedBox()),
        Column(children: [
          Row(children: [
            Icon(Icons.timer, color: Theme.of(context).primaryColor, size: 20),
            SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
            Text(
              '${restaurant.deliveryTime} ${'min'.tr}',
              style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: _textColor),
            ),
          ]),
          SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
          Text('delivery_time'.tr,
              style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: _textColor)),
        ]),
        (restaurant.delivery && restaurant.freeDelivery)
            ? Expanded(child: SizedBox())
            : SizedBox(),
        (restaurant.delivery && restaurant.freeDelivery)
            ? Column(children: [
                Icon(Icons.money_off,
                    color: Theme.of(context).primaryColor, size: 20),
                SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                Text('free_delivery'.tr,
                    style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall, color: _textColor)),
              ])
            : SizedBox(),
        Expanded(child: SizedBox()),
      ]),
    ]);
  }
}
