import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QRScannerPage extends StatefulWidget {
  final String userType;
  final Map<String, dynamic>? userData;

  const QRScannerPage({
    super.key,
    required this.userType,
    this.userData,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isScanned = false;
  bool _isLoading = false;
  MobileScannerController controller = MobileScannerController();

  Future<void> _submitAttendance(String roomCode) async {
    if (_isLoading) return;

    // Validate required fields
    final userCode = widget.userData?['userCode'] ?? '';
    final role = widget.userData?['access'] ?? '';

    if (userCode.isEmpty || roomCode.isEmpty || role.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Missing required information:'),
              if (userCode.isEmpty) const Text('• User Code'),
              if (roomCode.isEmpty) const Text('• Room Code'),
              if (role.isEmpty) const Text('• Role'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Log the data being sent
      print('Sending data to server:');
      print('user_code: $userCode');
      print('room_code: $roomCode');
      print('role: $role');

      final response = await http.post(
        Uri.parse('https://stsapi.bccbsis.com/scan_room.php'),
        body: {
          'user_code': userCode,
          'room_code': roomCode,
          'role': role,
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Headers: ${response.headers}');
      print('API Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      // Check if response body is empty
      if (response.body.isEmpty) {
        throw Exception('Server returned empty response');
      }

      // Try to parse the response
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        print('JSON Parse Error: $e');
        print('Raw response body: ${response.body}');
        throw FormatException('Invalid JSON response from server. Response: ${response.body}');
      }
      
      if (data['status'] == 'error') {
        Navigator.pop(context); // Return to dashboard on error
        return;
      }

      if (!mounted) return;

      // Immediately return to dashboard with success data
      Navigator.pop(context, {
        'success': true,
        'message': data['message'] ?? 'Attendance recorded successfully',
        'status': data['attendance_status'] ?? 'N/A'
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Return to dashboard on any error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isScanned = false; // Reset scan state to allow scanning again
        });
      }
    }
  }

  void _onDetect(BarcodeCapture barcode) {
    if (_isScanned || _isLoading) return;

    final String? code = barcode.barcodes.first.rawValue;
    if (code != null) {
      // Log the scanned QR code content
      print('Scanned QR Code content: $code');
      
      // Validate room code format
      if (code.trim().isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Invalid QR Code'),
            content: const Text('The scanned QR code is empty. Please try again.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isScanned = false; // Reset scan state to allow scanning again
                  });
                },
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        _isScanned = true;
      });

      _submitAttendance(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Center Scan Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Align the QR code within the box',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// Custom painter for the overlay box
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final double boxSize = size.width * 0.65;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect boxRect = Rect.fromCenter(
      center: center,
      width: boxSize,
      height: boxSize,
    );

    // Dim background outside the scanning box
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(boxRect),
      ),
      paint,
    );

    // Border for the scanning box
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawRect(boxRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 