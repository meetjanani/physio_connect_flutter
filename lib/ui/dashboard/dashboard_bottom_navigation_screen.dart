import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:physio_connect/ui/dashboard/dashboard_controller.dart';
import 'package:physio_connect/ui/dashboard/dashboard_screen.dart';
import 'package:physio_connect/ui/dashboard/doctor_dashboard_screen.dart';
import 'package:physio_connect/utils/app_shared_preference.dart';
import 'package:physio_connect/utils/enum.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import '../../model/user_model_supabase.dart';
import '../booking_history/booking_history_screen.dart';
import '../profile/profile_about_us_screen.dart';

class DashboardBottomNavigationScreen extends StatefulWidget {
  DashboardBottomNavigationScreen({super.key, required this.currentIndex});
  int currentIndex;

  @override
  State<DashboardBottomNavigationScreen> createState() => _DashboardBottomNavigationScreenState();
}

class _DashboardBottomNavigationScreenState extends State<DashboardBottomNavigationScreen> {
  final DashboardController controller = DashboardController.to;

  late List<Widget> _buildScreens = [];

  @override
  void initState() {
    super.initState();
    UserModelSupabase.getFromSecureStorage().then((value) {
      setState(() {
        controller.userModelSupabase = value;
        _initializeScreens();
      });
    });
  }

  void _initializeScreens() {
    final isDoctor = controller.userModelSupabase?.userType.toLowerCase() == UserType.doctor;

    _buildScreens = [
      DashboardScreen(),
      isDoctor == true ? DoctorDashboardScreen() :BookingHistoryScreen(),
      ProfileAboutUsScreen(),
    ];
  }

  void onTapped(int index) {
    setState(() {
      widget.currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: (_buildScreens != null && _buildScreens.length > 0)
          ? _buildScreens[widget.currentIndex]
          : Center(child: CircularProgressIndicator()),
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
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home, color: AppColors.medicalBlue),
                activeIcon: Icon(Icons.home, color: AppColors.wellnessGreen),
                label: "Home"
              ),
              /*BottomNavigationBarItem(
                icon: Icon(Icons.home, color: AppColors.medicalBlue),
                activeIcon: Icon(Icons.home, color: AppColors.wellnessGreen),
                label: "Home"
              ),*/
              BottomNavigationBarItem(
                icon: Icon(Icons.history, color: AppColors.medicalBlue),
                activeIcon: Icon(Icons.history, color: AppColors.wellnessGreen),
                label: "Bookings"
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings, color: AppColors.medicalBlue),
                activeIcon: Icon(Icons.settings, color: AppColors.wellnessGreen),
                label: "About-Us"
              ),
            ],
            currentIndex: widget.currentIndex,
            onTap: onTapped,
            selectedItemColor: AppColors.wellnessGreen,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
            ),
            showUnselectedLabels: true,
            backgroundColor: AppColors.surface,
            elevation: 0, // No elevation here since we're using a custom shadow
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}