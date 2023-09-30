import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  int _selectedNavbar = 0;
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
  }

  void _changeSelectedNavbar(int index) {
    setState(() {
      _selectedNavbar = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedNavbar != 0) {
          setState(() {
            _selectedNavbar = 0;
          });
          return false;
        }
        return false;
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: primaryColor,
          elevation: 0,
          child: Icon(
            Icons.add_circle,
            size: 36,
          ),
        ),
        backgroundColor: bgColor,
        body: navigationItems[_selectedNavbar]['widget'] as Widget,
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          child: BottomAppBar(
            clipBehavior: Clip.antiAlias,
            shape: CircularNotchedRectangle(),
            color: Theme.of(context).primaryColor.withAlpha(255),
            child: BottomNavigationBar(
              selectedItemColor: buttonNavbar,
              unselectedItemColor: textColor.withOpacity(0.5),
              currentIndex: _selectedNavbar,
              showUnselectedLabels: false,
              showSelectedLabels: false,
              onTap: (index) {
                _changeSelectedNavbar(index);
              },
              items: navigationItems.map((item) {
                return BottomNavigationBarItem(
                  icon: Icon(item['icon'] as IconData),
                  label: item['label'] as String,
                );
              }).toList(),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
