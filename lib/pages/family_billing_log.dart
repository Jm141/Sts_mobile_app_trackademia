import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'dashboard.dart';
import '../main.dart';
import 'family_list.dart';
import 'settings.dart';
import 'Student_history_location.dart';
import '../models/navigation_item.dart';

class FamilyBillingLogPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const FamilyBillingLogPage({Key? key, required this.userData}) : super(key: key);

  @override
  _FamilyBillingLogPageState createState() => _FamilyBillingLogPageState();
}

class _FamilyBillingLogPageState extends State<FamilyBillingLogPage> {
  bool isLoading = true;
  bool _isExpanded = false;
  int _selectedIndex = 1;
  late List<NavigationItem> _navigationItems;
  Map<String, dynamic> billingData = {};
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _navigationItems = _getNavigationItems();
    _fetchBillingData();
  }

  List<NavigationItem> _getNavigationItems() {
    return [
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
    ];
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
              onPressed: () => Navigator.of(context).pop(),
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
            builder: (context) => FamilyListPage(userData: widget.userData),
          ),
        );
        break;
      case 'Location':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentHistoryLocationPage(userData: widget.userData),
          ),
        );
        break;
      case 'Billing':
        // Already on Billing page
        break;
      case 'Settings':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(userData: widget.userData),
          ),
        );
        break;
    }
  }

  Future<void> _fetchBillingData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final String familyCode = widget.userData['userCode'] ?? '';
      print('Attempting to fetch billing data for family code: $familyCode');
      
      if (familyCode.isEmpty) {
        throw Exception('Invalid family code');
      }

      final response = await http.get(
        Uri.parse('https://stsapi.bccbsis.com/calculate_family_payment.php?family_code=$familyCode'),
      );
      
      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('error')) {
          throw Exception(responseData['error']);
        }
        setState(() {
          billingData = responseData;
        });
      } else {
        throw Exception('Failed to fetch billing data');
      }
    } catch (e) {
      print('Error fetching billing data: $e');
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
            _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: _buildMainContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchBillingData,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Data',
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 250 : 70,
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
              child: _buildNavigationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 12),
      child: Row(
        children: [
          if (_isExpanded) ...[
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
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: Icon(
              _isExpanded ? Icons.chevron_left : Icons.chevron_right,
              size: 22,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ..._navigationItems.where((item) => !item.isBottom).map(_buildNavigationItem),
        const Divider(height: 16),
        ..._navigationItems.where((item) => item.isBottom).map(_buildNavigationItem),
      ],
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
                    color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[800],
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

  Widget _buildAppBar() {
    return Container(
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
            'Family Billing Log',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Color(0xFF4CAF50),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    return Container(
      color: Colors.grey[50]?.withOpacity(0.95),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBillingCard(),
            const SizedBox(height: 24),
            _buildPaymentBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingCard() {
    final currencyFormat = NumberFormat.currency(symbol: '₱');
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Family Code', billingData['family_code'] ?? 'N/A'),
            _buildInfoRow('Subscription Plan', billingData['subscription_plan'] ?? 'N/A'),
            _buildInfoRow('Base Amount', currencyFormat.format(billingData['amount'] ?? 0)),
            _buildInfoRow('Number of Students', '${billingData['student_count'] ?? 0}'),
            _buildInfoRow('Total Payment', 
              currencyFormat.format(billingData['total_payment'] ?? 0),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF4CAF50) : Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown() {
    final payments = billingData['payments_per_student'] as List<dynamic>? ?? [];
    final currencyFormat = NumberFormat.currency(symbol: '₱');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Breakdown',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4CAF50),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('Student ${index + 1}'),
                  trailing: Text(
                    currencyFormat.format(payments[index]),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 