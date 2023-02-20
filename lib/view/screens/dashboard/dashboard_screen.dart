import 'dart:async';

import 'package:efood_multivendor/controller/auth_controller.dart';
import 'package:efood_multivendor/controller/order_controller.dart';
import 'package:efood_multivendor/controller/user_controller.dart';
import 'package:efood_multivendor/helper/responsive_helper.dart';
import 'package:efood_multivendor/util/dimensions.dart';
import 'package:efood_multivendor/view/base/cart_widget.dart';
import 'package:efood_multivendor/view/screens/cart/cart_screen.dart';
import 'package:efood_multivendor/view/screens/dashboard/chat_support_screen.dart';
import 'package:efood_multivendor/view/screens/dashboard/widget/bottom_nav_item.dart';
import 'package:efood_multivendor/view/screens/dashboard/widget/running_order_view_widget.dart';
import 'package:efood_multivendor/view/screens/favourite/favourite_screen.dart';
import 'package:efood_multivendor/view/screens/home/home_screen.dart';
import 'package:efood_multivendor/view/screens/menu/menu_screen.dart';
import 'package:efood_multivendor/view/screens/order/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_tawk/flutter_tawk.dart';

class DashboardScreen extends StatefulWidget {
  final int pageIndex;
  DashboardScreen({@required this.pageIndex});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PageController _pageController;
  int _pageIndex = 0;
  List<Widget> _screens;
  GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
  bool _canExit = GetPlatform.isWeb ? true : false;
  bool _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = Get.find<AuthController>().isLoggedIn();

    if (_isLoggedIn && Get.find<UserController>().userInfoModel == null) {
      Get.find<UserController>().getUserInfo();
    }

    _pageIndex = widget.pageIndex;

    _pageController = PageController(initialPage: widget.pageIndex);

    _screens = [
      HomeScreen(),
      FavouriteScreen(),
      CartScreen(fromNav: true),
      OrderScreen(),
      Container(),
    ];

    Future.delayed(Duration(seconds: 1), () {
      setState(() {});
    });

    /*if(GetPlatform.isMobile) {
      NetworkInfo.checkConnectivity(_scaffoldKey.currentContext);
    }*/
  }

  void _show() async {
    showDialog(
        barrierColor: Colors.transparent,
        context: context,
        builder: (_) => Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Theme.of(context).primaryColor),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  )),
              margin: EdgeInsets.only(top: 65, right: 60, bottom: 60, left: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: GetBuilder<UserController>(builder: (userController) {
                  // print('${userController.userInfoModel.fName}');
                  return (userController.userInfoModel != null)
                      ? Tawk(
                          directChatLink:
                              'https://tawk.to/chat/63e74ba0c2f1ac1e2032ac4d/1govnureh',
                          visitor: TawkVisitor(
                            name:
                                '${userController.userInfoModel.fName} ${userController.userInfoModel.lName} ',
                            email: '${userController.userInfoModel.email}',
                          ),
                          onLoad: () {
                            print('Hello Tawk!');
                          },
                          onLinkTap: (String url) {
                            print(url);
                          },
                          placeholder: const SizedBox())
                      : Tawk(
                          directChatLink:
                              'https://tawk.to/chat/63e74ba0c2f1ac1e2032ac4d/1govnureh',
                          // visitor: TawkVisitor(
                          //   name: 'Dhanraj K',
                          //   email: 'dhanrajjj@gmail.com',
                          // ),
                          onLoad: () {
                            print('Hello Tawk!');
                          },
                          onLinkTap: (String url) {
                            print(url);
                          },
                          placeholder: const SizedBox(),
                        );
                }),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_pageIndex != 0) {
          _setPage(0);
          return false;
        } else {
          if (_canExit) {
            return true;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('back_press_again_to_exit'.tr,
                  style: TextStyle(color: Colors.white)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              margin: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
            ));
            _canExit = true;
            Timer(Duration(seconds: 2), () {
              _canExit = false;
            });
            return false;
          }
        }
      },
      child: Stack(
        children: [
          Scaffold(
            key: _scaffoldKey,
            floatingActionButton:
                GetBuilder<OrderController>(builder: (orderController) {
              return ResponsiveHelper.isDesktop(context)
                  ? SizedBox()
                  : (orderController.isRunningOrderViewShow &&
                          (orderController.runningOrderList != null &&
                              orderController.runningOrderList.length > 0))
                      ? SizedBox.shrink()
                      : FloatingActionButton(
                          elevation: 5,
                          backgroundColor: _pageIndex == 2
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor,
                          onPressed: () => _setPage(2),
                          child: CartWidget(
                              color: _pageIndex == 2
                                  ? Theme.of(context).cardColor
                                  : Theme.of(context).disabledColor,
                              size: 30),
                        );
            }),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: ResponsiveHelper.isDesktop(context)
                ? SizedBox()
                : GetBuilder<OrderController>(builder: (orderController) {
                    return (orderController.isRunningOrderViewShow &&
                            (orderController.runningOrderList != null &&
                                orderController.runningOrderList.length > 0))
                        ? RunningOrderViewWidget()
                        : BottomAppBar(
                            elevation: 5,
                            notchMargin: 5,
                            clipBehavior: Clip.antiAlias,
                            shape: CircularNotchedRectangle(),
                            child: Padding(
                              padding: EdgeInsets.all(
                                  Dimensions.PADDING_SIZE_EXTRA_SMALL),
                              child: Row(children: [
                                BottomNavItem(
                                    iconData: Icons.home,
                                    isSelected: _pageIndex == 0,
                                    onTap: () => _setPage(0)),
                                BottomNavItem(
                                    iconData: Icons.favorite,
                                    isSelected: _pageIndex == 1,
                                    onTap: () => _setPage(1)),
                                Expanded(child: SizedBox()),
                                BottomNavItem(
                                    iconData: Icons.shopping_bag,
                                    isSelected: _pageIndex == 3,
                                    onTap: () => _setPage(3)),
                                BottomNavItem(
                                    iconData: Icons.menu,
                                    isSelected: _pageIndex == 4,
                                    onTap: () {
                                      Get.bottomSheet(MenuScreen(),
                                          backgroundColor: Colors.transparent,
                                          isScrollControlled: true);
                                    }),
                              ]),
                            ),
                          );
                  }),
            body: PageView.builder(
              controller: _pageController,
              itemCount: _screens.length,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _screens[index];
              },
            ),
          ),
          Positioned(
            bottom: 60,
            right: 20,
            // child: FloatingActionButton(
            //   onPressed: () {
            //     Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //             builder: (context) => ChatSupportScreen()));
            //   },
            //   backgroundColor: Theme.of(context).primaryColor,
            //   child: Icon(
            //     Icons.chat_bubble,
            //     color: Colors.white,
            //   ),
            // ),
            child: GestureDetector(
              onTap: () {
                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => ChatSupportScreen()));
                // SmartDialog.show(
                //     builder: (_) => Container(
                //           height: MediaQuery.of(context).size.height / 2,
                //           width: MediaQuery.of(context).size.width / 1.3,
                //           color: Colors.red,
                //         ));
                _show();
              },
              child: Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor),
                child: Center(
                  child: Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setPage(int pageIndex) {
    setState(() {
      _pageController.jumpToPage(pageIndex);
      _pageIndex = pageIndex;
    });
  }
}
