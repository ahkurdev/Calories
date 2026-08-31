import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    const destinations = <({String route, IconData icon, String label})>[
      (route: '/home', icon: Icons.home_outlined, label: 'Home'),
      (route: '/diary', icon: Icons.menu_book_outlined, label: 'Diary'),
      (route: '/progress', icon: Icons.insights_outlined, label: 'Progress'),
      (route: '/profile', icon: Icons.person_outline_rounded, label: 'Profile'),
    ];
    final index = destinations.indexWhere((item) => item.route == currentRoute);
    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (value) => context.go(destinations[value].route),
      destinations: destinations
          .map(
            (item) =>
                NavigationDestination(icon: Icon(item.icon), label: item.label),
          )
          .toList(growable: false),
    );
  }
}
