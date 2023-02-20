import 'package:efood_multivendor/controller/auth_controller.dart';
import 'package:efood_multivendor/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tawk/flutter_tawk.dart';
import 'package:get/get.dart';

class ChatSupportScreen extends StatefulWidget {
  ChatSupportScreen({Key key}) : super(key: key);

  @override
  _ChatSupportScreenState createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  bool _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = Get.find<AuthController>().isLoggedIn();
    getinfo();
    if (_isLoggedIn && Get.find<UserController>().userInfoModel == null) {
      Get.find<UserController>().getUserInfo();
    }
  }

  getinfo() {
    print('user info getting');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<UserController>(builder: (userController) {
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
                placeholder: const Center(
                  child: Text('Loading...'),
                ),
              )
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
                placeholder: const Center(
                  child: Text('Loading...'),
                ),
              );
      }),
    );
  }
}
