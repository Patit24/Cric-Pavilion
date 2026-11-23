import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mock_database.dart';

class MobileOtpVerificationDialog extends StatefulWidget {
  final VoidCallback? onVerified;

  const MobileOtpVerificationDialog({super.key, this.onVerified});

  @override
  State<MobileOtpVerificationDialog> createState() => _MobileOtpVerificationDialogState();
}

class _MobileOtpVerificationDialogState extends State<MobileOtpVerificationDialog> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  void _sendOtp() {
    final raw = _mobileController.text.trim();
    final norm = MockDatabase.normalizeMobile(raw);
    if (norm.length != 10) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final db = Provider.of<MockDatabase>(context, listen: false);
    final otp = db.sendMobileOtp(norm);

    setState(() {
      _isLoading = false;
      _otpSent = true;
      _otpController.text = otp; // Pre-filled for seamless testing
    });
  }

  void _verifyOtp() {
    final raw = _mobileController.text.trim();
    final norm = MockDatabase.normalizeMobile(raw);
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final db = Provider.of<MockDatabase>(context, listen: false);
    final success = db.verifyUserMobileOtp(mobileNumber: norm, otp: otp);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop();
      widget.onVerified?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number verified successfully!'),
          backgroundColor: Color(0xFF009270),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid OTP or mobile number. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x3300F5A0), width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phonelink_lock, color: Color(0xFF00F5A0), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mobile Verification',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Mandatory step to protect player & match records',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (!_otpSent) ...[
                const Text(
                  'Enter your 10-digit mobile number to link your permanent cricket identity:',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text('+91', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 9830112233',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                          filled: true,
                          fillColor: Color(0xFF1E293B),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                            borderSide: BorderSide(color: Color(0xFF00F5A0), width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => _sendOtp(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5A0),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Send Verification OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ] else ...[
                Text(
                  'We sent a 6-digit OTP to +91 ${_mobileController.text.trim()}:',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: '123456',
                    hintStyle: TextStyle(color: Colors.white24, letterSpacing: 6),
                    filled: true,
                    fillColor: Color(0xFF1E293B),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: Color(0xFF00F5A0), width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _verifyOtp(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _otpSent = false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Change Number', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F5A0),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('Verify & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
