import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:md2_tab_indicator/md2_tab_indicator.dart';

import 'package:discuzq/states/appState.dart';
import 'package:discuzq/widgets/common/discuzText.dart';
import 'package:discuzq/widgets/ui/ui.dart';
import 'package:discuzq/widgets/forum/forumCategoryFilter.dart';
import 'package:discuzq/states/scopedState.dart';
import 'package:discuzq/models/categoryModel.dart';
import 'package:discuzq/utils/global.dart';
import 'package:discuzq/widgets/skeleton/discuzSkeleton.dart';
import 'package:discuzq/widgets/threads/theadsList.dart';
import 'package:discuzq/widgets/categories/discuzCategories.dart';

/// 注意：
/// 从我们的设计上来说，要加载了forum才显示这个组件，所以forum请求自然就在category之前
/// 这样做的目的是为了不要一次性请求过多，来尽量避免阻塞，所以在使用这个组件到其他地方渲染的时候，你也需要这样做
class ForumCategoryTab extends StatefulWidget {
  ///
  /// onAppbarState
  final Function onAppbarState;

  const ForumCategoryTab({Key key, this.onAppbarState}) : super(key: key);
  @override
  _ForumCategoryTabState createState() => _ForumCategoryTabState();
}

class _ForumCategoryTabState extends State<ForumCategoryTab>
    with SingleTickerProviderStateMixin {
  /// states
  /// tab controller
  TabController _tabController;

  /// _loading will be true when request categories, but not tell you success or failed to load
  /// default should be true, so that you can make a loading animation for users
  bool _loading = true;

  /// categories is empty
  bool _isEmptyCategories = false;

  /// 筛选条件状态
  ForumCategoryFilterItem _filterItem;

  @override
  void setState(fn) {
    if (!mounted) {
      return;
    }
    super.setState(fn);
  }

  @override
  void initState() {
    super.initState();

    /// 延迟加载
    Future.delayed(Duration(milliseconds: 400))
        .then((_) => this._initTabController())

        /// 监听用户滑动的分类
        /// 切勿在这个方法中进行setState的操作，这样会很影响性能
        .then((_) => _tabControllerListener());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScopedStateModelDescendant<AppState>(
      rebuildOnChange: false,
      builder: (context, child, state) => _buildForumCategoryTabTab(state));

  ///
  /// 监听用户滑到了哪个分类
  ///
  void _tabControllerListener() {
    _tabController.addListener(() {
      try {
        final AppState state =
            ScopedStateModel.of<AppState>(context, rebuildOnChange: true);
        final CategoryModel cat = state.categories[_tabController.index];

        state.updateFocusedCategories(cat);
      } catch (e) {
        throw e;
      }
    });
  }

  /// 构造tabbar
  Widget _buildForumCategoryTabTab(AppState state) {
    /// 返回加载中的视图
    if (_loading) {
      return const DiscuzSkeleton(
        isCircularImage: false,
        length: Global.requestPageLimit,
        isBottomLinesActive: true,
      );
    }

    /// 返回没有可用分类
    if (_isEmptyCategories) {
      const Center(child: const DiscuzText('暂无可用分类'));
    }

    /// 生成论坛分类和内容区域
    return Column(
      children: <Widget>[
        /// 生成滑动选项
        _buildtabs(state),

        /// 条件筛选组件
        ForumCategoryFilter(
          onChanged: (ForumCategoryFilterItem item) {
            /// todo: 条件切换啦，重新加载当前版块下的数据
            /// 注意，如果选择的条件相同，那么还是要做忽略return
            if (_filterItem == item) {
              return;
            }

            setState(() {
              _filterItem = item;
            });
          },
        ),

        /// tab Content
        /// 生成帖子渲染content区域(tabviews)
        Expanded(
          child: _ForumCategoryTabContent(
            controller: _tabController,
            filter: _filterItem,
            onAppbarState: widget.onAppbarState,
          ),
        )
      ],
    );
  }

  ///
  /// 生成分类Tabs 非Tabcontent
  ///
  Widget _buildtabs(AppState state) => Container(
        width: MediaQuery.of(context).size.width,
        decoration:
            BoxDecoration(color: DiscuzApp.themeOf(context).backgroundColor),
        child: SafeArea(
          top: true,
          bottom: false,
          child: TabBar(
              //生成Tab菜单
              controller: _tabController,
              labelStyle: TextStyle(
                //up to your taste
                fontSize: DiscuzApp.themeOf(context).largeTextSize,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: DiscuzApp.themeOf(context).normalTextSize,
              ),
              indicatorSize: TabBarIndicatorSize.label, //makes it better
              labelColor:
                  DiscuzApp.themeOf(context).primaryColor, //Google's sweet blue
              unselectedLabelColor:
                  DiscuzApp.themeOf(context).textColor, //niceish grey
              isScrollable: true, //up to your taste
              indicatorPadding: const EdgeInsets.all(0),
              indicator: MD2Indicator(
                  //it begins here
                  indicatorHeight: 2,
                  indicatorColor: DiscuzApp.themeOf(context).primaryColor,
                  indicatorSize: MD2IndicatorSize
                      .normal //3 different modes tiny-normal-full
                  ),
              tabs: state.categories
                  .map<Widget>(
                      (CategoryModel e) => Tab(text: e.attributes.name))
                  .toList()),
        ),
      );

  /// 初始化 tab controller
  ///
  /// 该方法将会请求查询分类接口以构造一个 tabs 列表
  ///
  Future<void> _initTabController() async {
    try {
      final AppState state =
          ScopedStateModel.of<AppState>(context, rebuildOnChange: true);

      final bool success = await _getCategories(state);
      if (!success) {
        return;
      }

      /// 没有分类
      if (state.categories == null || state.categories.length == 0) {
        setState(() {
          _isEmptyCategories = true;
        });
      }

      /// 初始化tabber
      _tabController = TabController(
          length: state.categories == null ? 0 : state.categories.length,
          vsync: this);
    } catch (e) {
      throw e;
    }
  }

  ///
  /// _getCategories
  /// force should never be true on didChangeDependencies life cycle
  /// that would make your ui rendering loop and looping to die
  ///
  /// 新逻辑： 先从本地缓存取得分类列表，如果本地存储了分类列表直接取出
  /// 如果没有缓存，那么还是向接口请求
  ///
  Future<bool> _getCategories(AppState state) async {
    setState(() {
      _loading = true;
      _isEmptyCategories = false;

      /// 仅需要复原 _initTabController会再次处理
    });

    List<CategoryModel> categories =
        await DiscuzCategories(context: context).getCategories();

    categories.insert(
        0, CategoryModel(attributes: CategoryModelAttributes(name: '全部')));

    state.updateCategories(categories);
    setState(() {
      _loading = false;
    });

    ///
    /// 异步请求，不在乎结果，因为本地有可用数据
    _requestCategories(state);

    return Future.value(true);
  }

  /// request Categories Data
  ///
  Future<bool> _requestCategories(
    AppState state,
  ) async {
    List<CategoryModel> categories =
        await DiscuzCategories(context: context).requestCategories();

    setState(() {
      _loading = false;
    });

    categories.insert(
        0, CategoryModel(attributes: CategoryModelAttributes(name: '全部')));

    /// 重新更新状态
    state.updateCategories(categories);

    return Future.value(true);
  }
}

///
///
/// 构造ThreadList列表
class _ForumCategoryTabContent extends StatefulWidget {
  ///
  /// 滑动控制
  final TabController controller;

  ///
  /// 筛选器
  final ForumCategoryFilterItem filter;

  ///
  /// 状态变化
  final Function onAppbarState;

  _ForumCategoryTabContent(
      {@required this.controller, @required this.filter, this.onAppbarState});

  @override
  __ForumCategoryTabContentState createState() =>
      __ForumCategoryTabContentState();
}

class __ForumCategoryTabContentState extends State<_ForumCategoryTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScopedStateModelDescendant<AppState>(
        rebuildOnChange: false,
        builder: (context, child, state) => TabBarView(
              controller: widget.controller,
              children: state.categories
                  .map<Widget>((CategoryModel cat) => ThreadsList(
                        category: cat,
                        onAppbarState: widget.onAppbarState,

                        /// 初始化的时候，用户没有选择，则默认使用第一个筛选条件
                        filter:
                            widget.filter ?? ForumCategoryFilter.conditions[0],
                      ))
                  .toList(),
            ));
  }
}
