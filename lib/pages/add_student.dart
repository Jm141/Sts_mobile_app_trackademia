import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class StudentEntry {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController middleNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  String gradeLevel = 'Grade 1';
  TextEditingController birthController = TextEditingController();
  DateTime? selectedDate;

  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    birthController.dispose();
  }

  Map<String, String> toJson() {
    return {
      'firstname': firstNameController.text,
      'middlename': middleNameController.text,
      'lastname': lastNameController.text,
      'age': ageController.text,
      'grade_level': gradeLevel,
      'birth': birthController.text,
    };
  }

  void clear() {
    firstNameController.clear();
    middleNameController.clear();
    lastNameController.clear();
    ageController.clear();
    birthController.clear();
    gradeLevel = 'Grade 1';
    selectedDate = null;
  }
}

class AddStudentPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  AddStudentPage({required this.userData});

  @override
  _AddStudentPageState createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  List<StudentEntry> students = [];
  String? _selectedSubscription;
  final List<String> _gradeLevels = [
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
  ];

  @override
  void initState() {
    super.initState();
    _addNewStudentEntry();
  }

  @override
  void dispose() {
    for (var student in students) {
      student.dispose();
    }
    super.dispose();
  }

  void _addNewStudentEntry() {
    setState(() {
      students.add(StudentEntry());
    });
  }

  void _removeStudentEntry(int index) {
    setState(() {
      students[index].dispose();
      students.removeAt(index);
      if (students.isEmpty) {
        _addNewStudentEntry();
      }
    });
  }

  Future<void> _selectDate(BuildContext context, StudentEntry student) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: student.selectedDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != student.selectedDate) {
      setState(() {
        student.selectedDate = picked;
        student.birthController.text = DateFormat('yyyy-MM-dd').format(picked);
        // Calculate age
        final now = DateTime.now();
        final age = now.year - picked.year;
        student.ageController.text = age.toString();
      });
    }
  }

  Future<void> _showSubscriptionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Subscription Plan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(height: 24),
                _buildSubscriptionCard(
                  'Standard Plan',
                  [
                    'Basic features',
                    'Limited access',
                    'Email support',
                  ],
                  'standard',
                ),
                SizedBox(height: 16),
                _buildSubscriptionCard(
                  'Premium Plan',
                  [
                    'All features included',
                    'Unlimited access',
                    '24/7 Priority support',
                    'Advanced analytics',
                  ],
                  'premium',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionCard(String title, List<String> features, String plan) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedSubscription == plan 
              ? const Color(0xFF4CAF50) 
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSubscription = plan;
          });
          _submitForm();
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              SizedBox(height: 12),
              ...features.map((feature) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: const Color(0xFF4CAF50),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      feature,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_selectedSubscription == null) {
      _showMessageDialog('Please select a subscription plan', false);
      return;
    }

    bool hasError = false;
    String errorMessage = '';

    for (var student in students) {
      try {
        // Create the request body
        final requestBody = {
          'family_code': widget.userData['userCode'],
          'firstname': student.firstNameController.text.trim(),
          'middlename': student.middleNameController.text.trim(),
          'lastname': student.lastNameController.text.trim(),
          'age': student.ageController.text.trim(),
          'grade_level': student.gradeLevel,
          'birth': student.birthController.text.trim(),
          'subscription_plan': _selectedSubscription,
        };

        // Log the request body for debugging
        print('Sending request with body: $requestBody');

        final response = await http.post(
          Uri.parse('https://stsapi.bccbsis.com/add_students.php'),
          body: requestBody,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        );

        // Log the response for debugging
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode != 200) {
          throw Exception('Server returned status code ${response.statusCode}');
        }

        final responseData = json.decode(response.body);
        if (responseData['message'] == 'Duplicate') {
          hasError = true;
          errorMessage = 'One or more students already exist!';
          break;
        } else if (responseData['message'] == 'Error') {
          hasError = true;
          errorMessage = 'Failed to add student: ${responseData['details'] ?? 'Unknown error'}';
          break;
        } else if (responseData['message'] != 'Success') {
          hasError = true;
          errorMessage = 'Failed to add one or more students: ${responseData['message']}';
          break;
        }
      } catch (error) {
        hasError = true;
        errorMessage = 'Error: $error';
        print('Exception occurred: $error');
        break;
      }
    }

    if (!hasError) {
      _showMessageDialog('All students added successfully!', true);
      // Clear form after successful submission
      _formKey.currentState?.reset();
      setState(() {
        students.clear();
        _addNewStudentEntry();
      });
    } else {
      _showMessageDialog(errorMessage, false);
    }
  }

  void _showMessageDialog(String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 30,
              ),
              SizedBox(width: 10),
              Text(
                isSuccess ? "Success" : "Error",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(message, style: TextStyle(fontSize: 16)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isSuccess) {
                  Navigator.of(context).pop(); // Return to previous screen
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? Colors.green : Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentForm(StudentEntry student, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Student ${index + 1}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                if (students.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeStudentEntry(index),
                    tooltip: 'Remove Student',
                  ),
              ],
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: student.firstNameController,
              label: 'First Name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter first name';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: student.middleNameController,
              label: 'Middle Name',
              icon: Icons.person,
            ),
            _buildTextField(
              controller: student.lastNameController,
              label: 'Last Name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter last name';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: student.birthController,
              label: 'Birth Date',
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: () => _selectDate(context, student),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select birth date';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: student.ageController,
              label: 'Age',
              icon: Icons.cake,
              readOnly: true,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: DropdownButtonFormField<String>(
                value: student.gradeLevel,
                decoration: InputDecoration(
                  labelText: 'Grade Level',
                  prefixIcon: Icon(Icons.school, color: const Color(0xFF4CAF50)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFF4CAF50)),
                  ),
                ),
                items: _gradeLevels.map((String grade) {
                  return DropdownMenuItem<String>(
                    value: grade,
                    child: Text(grade),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    student.gradeLevel = newValue!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: const Color(0xFF4CAF50)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Students'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image/backgrounds/bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black26,
              BlendMode.darken,
            ),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...students.asMap().entries.map((entry) => 
                  _buildStudentForm(entry.value, entry.key)
                ).toList(),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addNewStudentEntry,
                  icon: Icon(Icons.add),
                  label: Text('Add Another Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4CAF50),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: const Color(0xFF4CAF50)),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _showSubscriptionDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Submit All Students',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 