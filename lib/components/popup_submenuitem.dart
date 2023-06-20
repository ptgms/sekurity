import 'package:flutter/material.dart';

/// An item with sub menu for using in popup menus
/// 
/// [title] is the text which will be displayed in the pop up
/// [items] is the list of items to populate the sub menu
/// [onSelected] is the callback to be fired if specific item is pressed
/// 
/// Selecting items from the submenu will automatically close the parent menu
/// Closing the sub menu by clicking outside of it, will automatically close the parent menu
class PopupSubMenuItem<T> extends PopupMenuEntry<T> {
  const PopupSubMenuItem({super.key, 
    required this.title,
    required this.items,
    required this.onSelected,
  });

  final String title;
  final List<PopupMenuEntry<T>> items;
  final Function(T) onSelected;

  @override
  double get height => kMinInteractiveDimension; //Does not actually affect anything

  @override
  State createState() => _PopupSubMenuState<T>();
  
  @override
  bool represents(T? value) {
    return false;
  }
}

/// The [State] for [PopupSubMenuItem] subclasses.
class _PopupSubMenuState<T> extends State<PopupSubMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: "",
      onCanceled: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      onSelected: (T value) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        widget.onSelected.call(value);
      },
      offset: const Offset(10, 10),
      itemBuilder: (BuildContext context) {
        return widget.items;
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 12.0, bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: Text(widget.title),
            ),
            Icon(
              Icons.arrow_right,
              size: 24.0,
              color: Theme.of(context).iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }
}
