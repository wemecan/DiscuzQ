import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

import 'package:discuzq/utils/global.dart';
import 'package:discuzq/widgets/common/discuzButton.dart';
import 'package:discuzq/widgets/common/discuzIcon.dart';
import 'package:discuzq/widgets/common/discuzText.dart';
import 'package:discuzq/widgets/common/discuzToast.dart';
import 'package:discuzq/models/userModel.dart';
import 'package:discuzq/widgets/common/discuzAvatar.dart';

class ShareApp {
  static Future<bool> show(
          {@required BuildContext context, @required UserModel user}) =>
      showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) => _ShareAppView(
                user: user,
              ));
}

class _ShareAppView extends StatelessWidget {
  final UserModel user;

  const _ShareAppView({Key key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) => _buildShareComponent(context: context);

  Widget _buildShareComponent({BuildContext context}) => user == null
      ? const SizedBox()
      : Container(
          width: double.infinity,
          height: 300,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Theme.of(context).backgroundColor,
              borderRadius: BorderRadius.all(Radius.circular(15))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const DiscuzAvatar(),
              const DiscuzText(
                '邀请好友加入',
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(
                height: 35,
              ),
              DiscuzButton(
                label: '复制我的邀请口令',
                icon: const DiscuzIcon(
                  SFSymbols.square_on_square,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await ClipboardManager.copyToClipBoard(
                      "${Global.domain}/open-circle/${user.id.toString()}");
                  DiscuzToast.toast(context: context, message: '复制成功');
                  Navigator.pop(context);
                },
              )
            ],
          ),
        );
}
