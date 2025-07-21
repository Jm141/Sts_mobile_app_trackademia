import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'dashboard.dart';
// import 'update_password.dart';
import '../main.dart';
import 'add_student.dart';
import 'settings.dart';
import 'Student_history_location.dart';
// import '../widgets/dashboard_nav.dart';
import '../models/navigation_item.dart';
import 'family_billing_log.dart';

class FamilyListPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  FamilyListPage({required this.userData});

  @override
  _FamilyListPageState createState() => _FamilyListPageState();
}

class _FamilyListPageState extends State<FamilyListPage> {
  Map<String, dynamic> parentData = {};
  List<Map<String, dynamic>> students = [];
  String errorMessage = '';
  bool isLoading = true;
  bool _isExpanded = false;
  int _selectedIndex = 1; // Set to 1 for Family List in nav
  late List<NavigationItem> _navigationItems;

  // Controllers for parent data
  late TextEditingController _fnameController;
  late TextEditingController _mnameController;
  late TextEditingController _lnameController;
  late TextEditingController _emailController;
  late TextEditingController _numberController;
  late TextEditingController _statusController;
  late TextEditingController _userCodeController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _navigationItems = _getNavigationItems();
    _fetchData();
  }

  void _initializeControllers() {
    _fnameController = TextEditingController();
    _mnameController = TextEditingController();
    _lnameController = TextEditingController();
    _emailController = TextEditingController();
    _numberController = TextEditingController();
    _statusController = TextEditingController();
    _userCodeController = TextEditingController(text: widget.userData['userCode'] ?? '');
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _fnameController.dispose();
    _mnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _statusController.dispose();
    _userCodeController.dispose();
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

    final index = _navigationItems.indexOf(item);
    setState(() {
      _selectedIndex = index;
    });

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
        // Already on Family page
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FamilyBillingLogPage(userData: widget.userData),
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
    }
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

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await Future.wait([
        _fetchParentData(),
        _fetchStudents(),
      ]);
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchParentData() async {
    final String userCode = widget.userData['userCode'] ?? '';
    if (userCode.isEmpty) {
      throw Exception('Invalid user code');
    }

    final response = await http.get(
      Uri.parse('https://stsapi.bccbsis.com/fetch_parent.php?userCode=$userCode'),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['message'] == 'Success') {
        final parent = responseData['parent'];
        setState(() {
          parentData = parent;
          _updateControllers(parent);
        });
      } else {
        throw Exception(responseData['message']);
      }
    } else {
      throw Exception('Failed to fetch parent data');
    }
  }

  void _updateControllers(Map<String, dynamic> parent) {
    _fnameController.text = parent['fname'] ?? '';
    _mnameController.text = parent['mname'] ?? '';
    _lnameController.text = parent['lname'] ?? '';
    _emailController.text = parent['email'] ?? '';
    _numberController.text = parent['number'] ?? '';
    _statusController.text = parent['status']?.toString().toUpperCase() ?? '';
  }

  Future<void> _fetchStudents() async {
    final String userCode = widget.userData['userCode'] ?? '';
    if (userCode.isEmpty) {
      throw Exception('Invalid user code');
    }

    final response = await http.get(
      Uri.parse('https://stsapi.bccbsis.com/fetch_students.php?userCode=$userCode'),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['message'] == 'Success') {
        setState(() {
          students = List<Map<String, dynamic>>.from(responseData['students']);
        });
      } else {
        throw Exception(responseData['message']);
      }
    } else {
      throw Exception('Failed to fetch students');
    }
  }

  Future<void> _saveParentData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.post(
        Uri.parse('https://stsapi.bccbsis.com/update_parent.php'),
        body: {
          'userCode': _userCodeController.text,
          'fname': _fnameController.text,
          'mname': _mnameController.text,
          'lname': _lnameController.text,
          'email': _emailController.text,
          'number': _numberController.text,
          'status': _statusController.text,
        },
      );

      final responseData = json.decode(response.body);
      if (responseData['message'] == 'Success') {
        _showMessage('Parent information updated successfully!', true);
        await _fetchParentData();
      } else {
        _showMessage('Failed to update parent information', false);
      }
    } catch (e) {
      _showMessage('Error: $e', false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        onPressed: _fetchData,
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
            'Family Members',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Color(0xFF4CAF50),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF4CAF50)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddStudentPage(userData: widget.userData),
              ),
            ),
            tooltip: 'Add Student',
          ),
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

    return Container(
      color: Colors.grey[50]?.withOpacity(0.95),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildParentSection(),
            const SizedBox(height: 32),
            _buildStudentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildParentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Parent Information',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 16),
        _buildParentInfoCard(),
      ],
    );
  }

  Widget _buildParentInfoCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF4CAF50),
                        radius: 30,
                        child: Text(
                          _fnameController.text.isNotEmpty 
                              ? _fnameController.text[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Parent Information',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                    onPressed: () {
                      // Toggle readonly state for editable fields
                      setState(() {
                        // Implementation for edit mode toggle
                      });
                    },
                    tooltip: 'Edit Information',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(_fnameController, 'First Name', Icons.person, true),
              _buildTextField(_mnameController, 'Middle Name', Icons.person, true),
              _buildTextField(_lnameController, 'Last Name', Icons.person, true),
              _buildTextField(_emailController, 'Email', Icons.email, false),
              _buildTextField(_numberController, 'Phone Number', Icons.phone, false),
              _buildTextField(_statusController, 'Status', Icons.info, true),
              _buildTextField(_userCodeController, 'Family Code', Icons.code, true),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveParentData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text('Save Changes', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isReadOnly,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          hintText: 'Enter $label',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          filled: true,
          fillColor: isReadOnly ? Colors.grey[200] : Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF388E3C), width: 2.5),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Student Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4CAF50),
              ),
            ),
            Text(
              'Total Students: ${students.length}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStudentList(),
      ],
    );
  }

  Widget _buildStudentList() {
    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: students.length,
      itemBuilder: (context, index) => _buildStudentCard(students[index]),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF4CAF50),
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          '${student['firstname']} ${student['middlename']} ${student['lastname']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              student['grade_level'] ?? 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Birth Date: ${_formatDate(student['birth'])}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Status: ${_capitalizeFirst(student['status'])}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Username: ${student['email'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('MMMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  String _capitalizeFirst(String? text) {
    if (text == null || text.isEmpty) return 'N/A';
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }
} 
