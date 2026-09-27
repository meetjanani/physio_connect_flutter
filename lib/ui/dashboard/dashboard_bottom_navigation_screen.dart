import 'package:flutter/material.dart';
import 'package:physio_connect/ui/dashboard/dashboard_controller.dart';
import 'package:physio_connect/ui/dashboard/dashboard_screen.dart';
import 'package:physio_connect/ui/dashboard/doctor_dashboard_screen.dart';
import 'package:physio_connect/ui/dashboard/doctor_earnings_screen.dart';
import 'package:physio_connect/ui/generate_prescription/generate_prescription_screen.dart';
import 'package:physio_connect/ui/help/help_support_screen.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import '../../model/user_model_supabase.dart';
import '../../utils/constants.dart';
import '../booking_history/booking_history_screen.dart';
import '../profile/profile_about_us_screen.dart';

class DashboardBottomNavigationScreen extends StatefulWidget {
  DashboardBottomNavigationScreen({super.key, required this.currentIndex});
  int currentIndex;

  @override
  State<DashboardBottomNavigationScreen> createState() =>
      _DashboardBottomNavigationScreenState();
}

class _DashboardBottomNavigationScreenState
    extends State<DashboardBottomNavigationScreen> {
  final DashboardController controller = DashboardController.to;

  List<Widget> _buildScreens = [];
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    UserModelSupabase.getFromSecureStorage().then((value) {
      setState(() {
        controller.userModelSupabase = value;
        _isDoctor = isDoctorTypeUser(value);
        _initializeScreens();
        // Doctors land on their appointments tab (index 0).
        if (_isDoctor && widget.currentIndex == 0) {
          widget.currentIndex = 0;
        }
      });
    });
  }

  // GeneratePrescriptionScreen // Make it on_Demand from doctor side, and only show if doctor is allowed to generate prescription.
  // DoctorEarningsScreen // Make it on_Demand from doctor side, and only show if doctor is allowed to generate prescription.
  void _initializeScreens() {
    _buildScreens = [
      DashboardScreen(),
      BookingHistoryScreen(),
      ProfileAboutUsScreen(),
      HelpSupportScreen()
    ];
    // if (_isDoctor) {
    //   _buildScreens = [
    //     // const DoctorEarningsScreen(),
    //     GeneratePrescriptionScreen(),
    //   ];
    // }
  }

  void onTapped(int index) {
    setState(() {
      widget.currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history),
        activeIcon: Icon(Icons.history),
        label: 'Bookings',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.medical_information_outlined),
        activeIcon: Icon(Icons.medical_information),
        label: 'About Us',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _buildScreens.isNotEmpty
          ? _buildScreens[widget.currentIndex.clamp(0, _buildScreens.length - 1)]
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: items,
            currentIndex: widget.currentIndex.clamp(0, items.length - 1),
            onTap: onTapped,
            selectedItemColor: AppColors.wellnessGreen,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            showUnselectedLabels: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}