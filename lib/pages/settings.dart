import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'family_list.dart';
import 'Student_history_location.dart';
import '../widgets/app_navigation.dart';
import '../services/location_service.dart';

// Feature configuration class to manage all features
class FeatureConfig {
  final String title;
  final String description;
  final IconData icon;
  final String? route;
  final bool isNew;

  FeatureConfig({
    required this.title,
    required this.description,
    required this.icon,
    this.route,
    this.isNew = false,
  });
}

// System information configuration
class SystemInfo {
  final String version;
  final String lastUpdated;
  final List<String> newFeatures;
  final Map<String, String> supportInfo;

  SystemInfo({
    required this.version,
    required this.lastUpdated,
    required this.newFeatures,
    required this.supportInfo,
  });
}

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const SettingsPage({
    super.key,
    this.userData,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isExpanded = false;
  int _selectedIndex = 3; // Settings index
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _geofenceEnabled = false;
  String _selectedLanguage = 'English';
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadGeofenceStatus();
  }

  Future<void> _loadGeofenceStatus() async {
    try {
      bool isEnabled = await _locationService.isGeofenceEnabled();
      setState(() {
        _geofenceEnabled = isEnabled;
      });
    } catch (e) {
      print('Error loading geofence status: $e');
    }
  }

  // Define all features here - Add new features to this list
  final List<FeatureConfig> _features = [
    FeatureConfig(
      title: 'Dashboard',
      description:
          'The main page showing an overview of your account and quick access to all features.',
      icon: Icons.dashboard,
    ),
    FeatureConfig(
      title: 'Family Management',
      description:
          'View and manage your family members, including student profiles and information.',
      icon: Icons.family_restroom,
    ),
    FeatureConfig(
      title: 'Location Tracking',
      description:
          'Monitor your children\'s location and receive notifications when they enter or leave school premises.',
      icon: Icons.location_on,
    ),
    FeatureConfig(
      title: 'Student History',
      description:
          'View detailed history of your children\'s attendance and location records.',
      icon: Icons.history,
      isNew: true,
    ),
  ];

  // System information configuration
  final SystemInfo _systemInfo = SystemInfo(
    version: 'v1.0.0',
    lastUpdated: 'June 11, 2025',
    newFeatures: [
      'Student Location History',
      'Real-time Location Tracking',
      'Geofence Notifications',
    ],
    supportInfo: {
      'Email': 'support@triconnect.com',
      'Phone': '+1 (123) 456-7890',
      'Hours':
          'Monday to Friday: 8:00 AM - 5:00 PM\nSaturday: 9:00 AM - 1:00 PM\nSunday: Closed',
    },
  );

  @override
  Widget build(BuildContext context) {
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
        child: Row(
          children: [
            // Sidebar navigation
            AppNavigation(
              userData: widget.userData,
              selectedIndex: _selectedIndex,
              isExpanded: _isExpanded,
              onExpandToggle: (value) => setState(() => _isExpanded = value),
            ),
            // Main content
            Expanded(
              child: Column(
                children: [
                  // App bar
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const Spacer(),
                        // User profile section
                        if (widget.userData != null) ...[
                          CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: Text(
                              (widget.userData!['firstName'] as String?)
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  '?',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.userData!['firstName']} ${widget.userData!['lastName']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Text(
                                widget.userData!['email'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Main content area
                  Expanded(
                    child: Container(
                      color: Colors.grey[50]?.withOpacity(0.95),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Account Settings Section
                            _buildSectionHeader('Account Settings'),
                            _buildSettingsCard([
                              _buildSettingsTile(
                                icon: Icons.person,
                                title: 'Profile Information',
                                subtitle: 'Update your personal information',
                                onTap: () {
                                  // Navigate to profile settings
                                },
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.security,
                                title: 'Security',
                                subtitle:
                                    'Manage password and security settings',
                                onTap: () {
                                  // Navigate to security settings
                                },
                              ),
                            ]),

                            const SizedBox(height: 24),

                            // Preferences Section
                            _buildSectionHeader('Preferences'),
                            _buildSettingsCard([
                              _buildSettingsTile(
                                icon: Icons.notifications,
                                title: 'Notifications',
                                subtitle: 'Manage notification preferences',
                                trailing: Switch(
                                  value: _notificationsEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _notificationsEnabled = value;
                                    });
                                  },
                                ),
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.location_on,
                                title: 'Geofence Alerts',
                                subtitle: 'Get notified when students enter/leave school',
                                trailing: Switch(
                                  value: _geofenceEnabled,
                                  onChanged: (value) async {
                                    setState(() {
                                      _geofenceEnabled = value;
                                    });
                                    await _locationService.setGeofenceEnabled(value);
                                    if (value) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Geofence alerts enabled'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.dark_mode,
                                title: 'Dark Mode',
                                subtitle: 'Toggle dark mode appearance',
                                trailing: Switch(
                                  value: _darkModeEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _darkModeEnabled = value;
                                    });
                                  },
                                ),
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.language,
                                title: 'Language',
                                subtitle: 'Change app language',
                                trailing: DropdownButton<String>(
                                  value: _selectedLanguage,
                                  items: ['English', 'Spanish', 'French']
                                      .map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedLanguage = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ]),

                            const SizedBox(height: 24),

                            // Features Section
                            _buildSectionHeader('Features'),
                            _buildSettingsCard(
                              _features
                                  .map((feature) => _buildFeatureTile(feature))
                                  .toList(),
                            ),

                            const SizedBox(height: 24),

                            // Support Section
                            _buildSectionHeader('Support'),
                            _buildSettingsCard([
                              _buildSettingsTile(
                                icon: Icons.help_outline,
                                title: 'Help Center',
                                subtitle: 'Get help and support',
                                onTap: () {
                                  // Navigate to help center
                                },
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.info_outline,
                                title: 'About',
                                subtitle: 'Version ${_systemInfo.version}',
                                onTap: () {
                                  // Show about dialog
                                },
                              ),
                            ]),
                          ],
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4CAF50),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF4CAF50),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildFeatureTile(FeatureConfig feature) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              feature.icon,
              color: const Color(0xFF4CAF50),
            ),
          ),
          title: Row(
            children: [
              Text(
                feature.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (feature.isNew) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(feature.description),
          onTap: () {
            // Handle feature navigation
            switch (feature.title) {
              case 'Dashboard':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DashboardPage(userData: widget.userData),
                  ),
                );
                break;
              case 'Family Management':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FamilyListPage(userData: widget.userData ?? {}),
                  ),
                );
                break;
              case 'Location Tracking':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StudentHistoryLocationPage(userData: widget.userData),
                  ),
                );
                break;
            }
          },
        ),
        if (feature != _features.last) _buildDivider(),
      ],
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 72, endIndent: 16);
  }
}
