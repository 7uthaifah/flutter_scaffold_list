library scaffold_list;

import 'dart:async';

import 'package:flutter/material.dart' hide showSearch;
import 'package:flutter/material.dart' as Default show showSearch;

class ScaffoldListView<T> extends ListView {
  ScaffoldListView({
    Key key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry padding,
    Widget Function(BuildContext, T) itemBuilder,
    IndexedWidgetBuilder separatorBuilder,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double cacheExtent,
    List<T> list,
  })  : assert(list != null),
        assert(itemBuilder != null),
        super.separated(
          key: key,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          itemBuilder: (BuildContext context, int index) => itemBuilder(
            context,
            list[index],
          ),
          separatorBuilder: (BuildContext context, int index) =>
              separatorBuilder != null
                  ? separatorBuilder(context, index)
                  : SizedBox(),
          itemCount: list.length,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          cacheExtent: cacheExtent,
        );
}

class ScaffoldListStyle {
  const ScaffoldListStyle({
    this.error = const Center(child: Text('Oops, something went wrong')),
    this.loading = const Center(child: CircularProgressIndicator()),
    this.empty = const Center(child: Text('Empty List')),
    this.noResults = const Center(child: Text('No Results')),
  });

  final Widget error, loading, empty, noResults;
}

class ScaffoldList<T> extends StatefulWidget {
  ScaffoldList({
    Key key,
    @required this.list,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    @required this.itemBuilder,
    this.separatorBuilder,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.filter,
    this.sort,
    this.searchFilter,
    this.searchDelegate,
    this.style = const ScaffoldListStyle(),
  })  : assert(list != null),
        assert(searchDelegate != null ? searchFilter != null : true),
        super(key: key);

  final dynamic list;

  final Axis scrollDirection;
  final bool reverse;
  final ScrollController controller;
  final bool primary;
  final ScrollPhysics physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double cacheExtent;

  final bool Function(T) filter;
  final int Function(T, T) sort;
  final Widget Function(BuildContext, T) itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;

  final bool Function(T, String) searchFilter;
  final SearchDelegate searchDelegate;

  final ScaffoldListStyle style;

  @override
  ScaffoldListState<T> createState() => ScaffoldListState<T>();
}

class ScaffoldListState<T> extends State<ScaffoldList<T>> {
  List<T> _list;

  Future<T> showSearch() async => await Default.showSearch<T>(
        context: context,
        delegate: widget.searchDelegate ??
            ScaffoldListSearchDelegate<T>(
              list: _list ?? [],
              itemBuilder: widget.itemBuilder,
              searchFilter: widget.searchFilter,
              style: widget.style,
            ),
      );

  @override
  Widget build(BuildContext context) => widget.list is Future<List<T>>
      ? FutureBuilder<List<T>>(
          future: widget.list,
          builder: (BuildContext context, AsyncSnapshot<List<T>> snapshot) =>
              _build(
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            hasError: snapshot.hasError,
            list: snapshot.data,
          ),
        )
      : (widget.list is List<T>
          ? _build(isLoading: widget.list == null, list: widget.list)
          : ErrorWidget(
              'type ${widget.list.runtimeType} is not subtype of List<$T> or Future<List<$T>>',
            ));

  Widget _build({
    bool isLoading,
    bool hasError = false,
    List<T> list,
  }) {
    if (widget.filter != null) {
      list = list.where(widget.filter).toList();
    }
    if (widget.sort != null) {
      list = list..sort(widget.sort);
    }

    _list = list;

    return hasError
        ? _buildError()
        : isLoading
            ? _buildLoading()
            : list.isEmpty ? _buildEmpty() : _buildList();
  }

  Widget _buildError() => widget.style.error;

  Widget _buildLoading() => widget.style.loading;

  Widget _buildEmpty() =>
      widget.searchFilter == null ? widget.style.noResults : widget.style.empty;

  Widget _buildList() => ScaffoldListView<T>(
        list: _list,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        controller: widget.controller,
        primary: widget.primary,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        padding: widget.padding,
        itemBuilder: widget.itemBuilder,
        separatorBuilder: widget.separatorBuilder,
        addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.addRepaintBoundaries,
        addSemanticIndexes: widget.addSemanticIndexes,
        cacheExtent: widget.cacheExtent,
      );
}

class ScaffoldListSearchDelegate<T> extends SearchDelegate<T> {
  ScaffoldListSearchDelegate({
    this.list,
    this.itemBuilder,
    this.searchFilter,
    this.style,
  });

  final List<T> list;
  final Function(BuildContext, T) itemBuilder;
  final bool Function(T item, String query) searchFilter;
  final ScaffoldListStyle style;

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) => ScaffoldList<T>(
        list: list,
        filter: (T item) => searchFilter != null
            ? searchFilter(item, query)
            : item.toString().startsWith(query.toString()),
        itemBuilder: (BuildContext context, item) => InkWell(
          child: itemBuilder(context, item),
          onTap: () => close(context, item),
        ),
      );

  @override
  List<Widget> buildActions(BuildContext context) => <Widget>[
        IconButton(
          tooltip: query.isEmpty
              ? MaterialLocalizations.of(context).closeButtonTooltip
              : 'Clear',
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (query.isEmpty) {
              close(context, null);
            } else {
              query = '';
              showSuggestions(context);
            }
          },
        ),
      ];
}
