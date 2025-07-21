import 'package:flutter/material.dart';
import 'user_info.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/background_service.dart';
import '../main.dart';
import 'family_list.dart';
import 'settings.dart';
import 'Student_history_location.dart';
import '../models/navigation_item.dart';
import 'family_billing_log.dart';
import 'dart:async';
import 'qr_scanner_page.dart';
import 'teacher_attendance.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const DashboardPage({
    super.key,
    this.userData,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isExpanded = false;
  int _selectedIndex = 0;
  late List<NavigationItem> _navigationItems;
  Timer? _locationTimer;
  final LocationService _locationService = LocationService();
  bool _isTrackingEnabled = false;
  bool _isSimpleTrackingEnabled = false;

  @override
  void initState() {
    super.initState();
    _navigationItems = _getNavigationItems();

    // Start location tracking if user is a student
    if (widget.userData?['access'] == 'student') {
      _initializeLocationTracking();
      // Automatically start simple tracking when app opens
      _startSimpleTracking();
    }
  }

  Future<void> _initializeLocationTracking() async {
    print('Dashboard: Initializing location tracking');

    // Check if tracking is already enabled
    _isTrackingEnabled = await _locationService.isBackgroundTrackingEnabled();
    print('Dashboard: Is tracking enabled? $_isTrackingEnabled');

    if (!_isTrackingEnabled) {
      // Start background tracking
      if (widget.userData != null) {
        final String email = widget.userData!['email'] ?? '';
        final String userCode = widget.userData!['userCode'] ?? '';

        print('Dashboard: User data - email: $email, userCode: $userCode');

        if (email.isNotEmpty && userCode.isNotEmpty) {
          await _locationService.startBackgroundTracking(email, userCode);

          // Ensure background service is running
          print('Dashboard: Ensuring background service is running');
          await BackgroundService.startBackgroundService();

          setState(() {
            _isTrackingEnabled = true;
          });

          print('Dashboard: Location tracking initialized successfully');

          // Test the location sending immediately
          print('Dashboard: Testing location sending');
          await BackgroundService.testLocationSending();
        } else {
          print('Dashboard: Missing email or userCode');
        }
      } else {
        print('Dashboard: No user data available');
      }
    } else {
      print('Dashboard: Tracking already enabled');
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
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
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                // Call logout from auth service
                await AuthService().logout();
                // Navigate to login page and remove all previous routes
                if (!mounted) return;
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

  List<NavigationItem> _getNavigationItems() {
    final String? access = widget.userData?['access'];

    List<NavigationItem> items = [];

    switch (access) {
      case 'student':
        items = [
          NavigationItem(
            title: 'Dashboard',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
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
        ];
        break;

      case 'parent':
        items = [
          NavigationItem(
            title: 'Dashboard',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
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
          NavigationItem(
            title: 'Billing',
            icon: Icons.receipt_outlined,
            selectedIcon: Icons.receipt,
          ),
        ];
        break;

      case 'teacher':
        items = [
          NavigationItem(
            title: 'Dashboard',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
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
        ];
        break;

      default:
        items = [
          NavigationItem(
            title: 'Dashboard',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
        ];
    }

    // Add Settings and Logout at the bottom for all users
    items.addAll([
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

  void _handleNavigation(NavigationItem item) {
    if (item.onTap != null) {
      item.onTap!();
      return;
    }

    final index = _navigationItems.indexOf(item);
    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation based on the item title
    switch (item.title) {
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
                StudentHistoryLocationPage(userData: widget.userData ?? {}),
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
            builder: (context) => SettingsPage(userData: widget.userData ?? {}),
          ),
        );
        break;
      case 'Attendance':
        // For teachers, navigate to attendance page; for others, use QR scanner
        if (widget.userData?['access'] == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherAttendancePage(userData: widget.userData ?? {}),
            ),
          );
        } else {
          _navigateToQRScanner();
        }
        break;
    }
  }

  Future<void> _navigateToQRScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerPage(
          userType: widget.userData?['access'] ?? '',
          userData: widget.userData,
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result['message'] ?? 'Attendance recorded successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image/backgrounds/bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black26,
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Sidebar - hidden on mobile, collapsible on desktop
              if (!isMobile || _isExpanded)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width:
                      isMobile ? screenWidth * 0.8 : (_isExpanded ? 250 : 70),
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
                        // Logo and toggle button
                        Container(
                          height: 70,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : (_isExpanded ? 16 : 12),
                          ),
                          child: Row(
                            children: [
                              if (_isExpanded || isMobile)
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: AssetImage(
                                          'assets/image/logos/Triconnect.png'),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              if (_isExpanded || isMobile)
                                const SizedBox(width: 12),
                              if (_isExpanded || isMobile)
                                const Text(
                                  'Triconnect',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              const Spacer(),
                              if (!isMobile)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                  icon: Icon(
                                    _isExpanded
                                        ? Icons.chevron_left
                                        : Icons.chevron_right,
                                    size: 22,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              if (isMobile)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isExpanded = false;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    size: 22,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        // Navigation items
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: [
                              ..._navigationItems
                                  .where((item) => !item.isBottom)
                                  .map(
                                    (item) => _buildNavigationItem(item),
                                  ),
                              const Divider(height: 16),
                              ..._navigationItems
                                  .where((item) => item.isBottom)
                                  .map(
                                    (item) => _buildNavigationItem(item),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // App bar
                    Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Menu button for mobile
                          if (isMobile)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isExpanded = true;
                                });
                              },
                              icon: Icon(
                                Icons.menu,
                                color: Color(0xFF4CAF50),
                                size: 24,
                              ),
                            ),
                          Text(
                            _navigationItems[_selectedIndex].title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const Spacer(),
                          // QR Scanner button for student and teacher
                          if (widget.userData?['access'] == 'student' ||
                              widget.userData?['access'] == 'teacher')
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: IconButton(
                                onPressed: _navigateToQRScanner,
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  color: Color(0xFF4CAF50),
                                  size: 28,
                                ),
                              ),
                            ),
                          // User profile section
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50]?.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => UserInfoPage(
                                        userData: widget.userData,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      radius: 14,
                                      child: Text(
                                        (widget.userData?['name'] as String?)
                                                    ?.isNotEmpty ==
                                                true
                                            ? (widget.userData!['name']
                                                    as String)
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (!isMobile) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.userData?['name'] ?? 'User',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Page content
                    Expanded(
                      child: Container(
                        color: Colors.grey[50]?.withOpacity(0.95),
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Welcome to ${_navigationItems[_selectedIndex].title}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item) {
    final isSelected = _navigationItems.indexOf(item) == _selectedIndex;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNavigation(item),
        child: Container(
          height: 50,
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 16 : 12,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 22,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
              ),
              if (_isExpanded) ...[
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
              if (_isExpanded && isSelected && item.onTap == null)
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

  // Simple tracking function that works when app is open
  void _startSimpleTracking() {
    if (_isSimpleTrackingEnabled) {
      _locationTimer?.cancel();
      setState(() {
        _isSimpleTrackingEnabled = false;
      });
      return;
    }

    setState(() {
      _isSimpleTrackingEnabled = true;
    });

    // Start timer to send location every minute when app is open
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (widget.userData != null) {
        final String email = widget.userData!['email'] ?? '';
        final String userCode = widget.userData!['userCode'] ?? '';

        if (email.isNotEmpty && userCode.isNotEmpty) {
          await BackgroundService.testLocationSending();
        }
      }
    });

    // Send initial location
    if (widget.userData != null) {
      final String email = widget.userData!['email'] ?? '';
      final String userCode = widget.userData!['userCode'] ?? '';

      if (email.isNotEmpty && userCode.isNotEmpty) {
        BackgroundService.testLocationSending();
      }
    }
  }
}
