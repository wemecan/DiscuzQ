import 'package:discuzq/widgets/common/discuzText.dart';
import 'package:discuzq/widgets/common/discuzToast.dart';
import 'package:discuzq/widgets/editor/discuzEditorRequestResult.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

import 'package:discuzq/models/postModel.dart';
import 'package:discuzq/models/threadModel.dart';
import 'package:discuzq/widgets/common/discuzIcon.dart';
import 'package:discuzq/widgets/posts/postLikeButton.dart';
import 'package:discuzq/widgets/share/shareNative.dart';
import 'package:discuzq/widgets/ui/ui.dart';
import 'package:discuzq/widgets/editor/discuzEditorHelper.dart';

///
/// 按钮图标的大小
const double _kIconsize = 20;

class ThreadCardQuickActions extends StatelessWidget {
  ///
  /// 首贴
  final PostModel firstPost;

  ///
  /// 关联帖子
  final ThreadModel thread;

  const ThreadCardQuickActions(
      {@required this.firstPost, @required this.thread});
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ///
          /// 点赞按钮
          Expanded(
            child: PostLikeButton(
              size: _kIconsize,
              post: firstPost,
            ),
          ),

          ///
          /// 评论
          _ThreadCardQuickActionsItem(
            icon: SFSymbols.bubble_left_bubble_right,
            count: thread.attributes.postCount,
            onPressed: () async {
              final DiscuzEditorRequestResult res =
                  await DiscuzEditorHelper(context: context)
                      .reply(post: firstPost, thread: thread);
              if (res != null) {
                ////
                /// 这种时候，用户是在卡片操作回复的，仅提示回复成功即可
                DiscuzToast.toast(context: context, message: '回复成功');
              }
            },
          ),

          ///
          /// 分享按钮
          _ThreadCardQuickActionsItem(
            icon: Icons.share,
            hideCounter: true,
            onPressed: () => ShareNative.shareThread(thread: thread),
          )
        ],
      ),
    );
  }
}

class _ThreadCardQuickActionsItem extends StatelessWidget {
  const _ThreadCardQuickActionsItem(
      {Key key,
      @required this.icon,
      @required this.onPressed,
      this.count = 0,
      this.hideCounter = false})
      : super(key: key);

  /// icon
  final IconData icon;

  /// onPressed
  final Function onPressed;

  /// counter
  final int count;

  /// hide counter
  final bool hideCounter;

  @override
  Widget build(BuildContext context) => Expanded(
        child: IconButton(
          icon: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              DiscuzIcon(
                icon,
                size: _kIconsize,
                color: DiscuzApp.themeOf(context).greyTextColor,
              ),
              const SizedBox(
                width: 4,
              ),
              hideCounter
                  ? const SizedBox()
                  : DiscuzText(
                      count.toString(),
                      fontSize: DiscuzApp.themeOf(context).smallTextSize,
                      color: DiscuzApp.themeOf(context).greyTextColor,
                      overflow: TextOverflow.ellipsis,
                    )
            ],
          ),
          onPressed: onPressed,
        ),
      );
}
