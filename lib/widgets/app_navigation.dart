import 'package:flutter/material.dart';
import '../models/navigation_item.dart';
import '../pages/dashboard.dart';
import '../pages/family_list.dart';
import '../pages/settings.dart';
import '../pages/Student_history_location.dart';
import '../pages/family_billing_log.dart';
import '../main.dart';

class AppNavigation extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final int selectedIndex;
  final bool isExpanded;
  final Function(bool) onExpandToggle;

  const AppNavigation({
    super.key,
    required this.userData,
    required this.selectedIndex,
    this.isExpanded = false,
    required this.onExpandToggle,
  });

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  late List<NavigationItem> _navigationItems;

  @override
  void initState() {
    super.initState();
    _navigationItems = _getNavigationItems();
  }

  List<NavigationItem> _getNavigationItems() {
    final String? access = widget.userData?['access'];
    List<NavigationItem> items = [];

    // Common items for all users
    items.add(
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
      ),
    );

    // Access-specific items
    switch (access) {
      case 'student':
        items.addAll([
          NavigationItem(
            title: 'Courses',
            icon: Icons.school_outlined,
            selectedIcon: Icons.school,
          ),
          NavigationItem(
            title: 'Schedule',
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today,
          ),
          NavigationItem(
            title: 'Assignments',
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment,
          ),
          NavigationItem(
            title: 'Grades',
            icon: Icons.grade_outlined,
            selectedIcon: Icons.grade,
          ),
        ]);
        break;

      case 'parent':
        items.addAll([
          NavigationItem(
            title: 'Family',
            icon: Icons.family_restroom_outlined,
            selectedIcon: Icons.family_restroom,
          ),
          NavigationItem(
            title: 'Location',
            icon: Icons.location_on_outlined,
            selectedIcon: Icons.location_on,
          ),
        ]);
        break;

      case 'teacher':
        items.addAll([
          NavigationItem(
            title: 'Students',
            icon: Icons.people_outlined,
            selectedIcon: Icons.people,
          ),
          NavigationItem(
            title: 'Attendance',
            icon: Icons.fact_check_outlined,
            selectedIcon: Icons.fact_check,
          ),
          NavigationItem(
            title: 'Schedule',
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today,
          ),
          NavigationItem(
            title: 'Reports',
            icon: Icons.assessment_outlined,
            selectedIcon: Icons.assessment,
          ),
        ]);
        break;
    }

    // Common bottom items for all users
    items.addAll([
      NavigationItem(
        title: 'Billing',
        icon: Icons.receipt_outlined,
        selectedIcon: Icons.receipt,
      ),
      NavigationItem(
        title: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        isBottom: true,
      ),
      NavigationItem(
        title: 'Logout',
        icon: Icons.logout_outlined,
        selectedIcon: Icons.logout,
        isBottom: true,
        onTap: _handleLogout,
      ),
    ]);

    return items;
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _handleNavigation(NavigationItem item) {
    if (item.onTap != null) {
      item.onTap!();
      return;
    }

    switch (item.title) {
      case 'Dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(userData: widget.userData),
          ),
        );
        break;
      case 'Family':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FamilyListPage(userData: widget.userData ?? {}),
          ),
        );
        break;
      case 'Location':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StudentHistoryLocationPage(userData: widget.userData),
          ),
        );
        break;
      case 'Billing':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FamilyBillingLogPage(userData: widget.userData ?? {}),
          ),
        );
        break;
      case 'Settings':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(userData: widget.userData),
          ),
        );
        break;
      // Add other navigation cases as needed
    }
  }

  Widget _buildNavigationItem(NavigationItem item) {
    final isSelected = _navigationItems.indexOf(item) == widget.selectedIndex;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNavigation(item),
        child: Container(
          height: 50,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? 16 : 12,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 22,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color:
                        isSelected ? const Color(0xFF4CAF50) : Colors.grey[800],
                  ),
                ),
              ],
              if (widget.isExpanded && isSelected && item.onTap == null)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: widget.isExpanded ? 16 : 12),
      child: Row(
        children: [
          if (widget.isExpanded) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/image/logos/Triconnect.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Triconnect',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: () => widget.onExpandToggle(!widget.isExpanded),
            icon: Icon(
              widget.isExpanded ? Icons.chevron_left : Icons.chevron_right,
              size: 22,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.isExpanded ? 250 : 70,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSidebarHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ..._navigationItems
                      .where((item) => !item.isBottom)
                      .map(_buildNavigationItem),
                  const Divider(height: 16),
                  ..._navigationItems
                      .where((item) => item.isBottom)
                      .map(_buildNavigationItem),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
