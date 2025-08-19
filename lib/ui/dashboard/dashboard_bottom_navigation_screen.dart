import 'package:flutter/material.dart';
import 'package:physio_connect/ui/dashboard/dashboard_screen.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import '../booking_history/booking_history_screen.dart';

class DashboardBottomNavigationScreen extends StatefulWidget {
  DashboardBottomNavigationScreen({super.key, required this.currentIndex});
  int currentIndex;

  @override
  State<DashboardBottomNavigationScreen> createState() => _DashboardBottomNavigationScreenState();
}

class _DashboardBottomNavigationScreenState extends State<DashboardBottomNavigationScreen> {
  final List<Widget> _buildScreens = [
    DashboardScreen(),
    BookingHistoryScreen(),
    DashboardScreen(),
  ];

  void onTapped(int index) {
    setState(() {
      widget.currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildScreens[widget.currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home,color: AppColors.therapyPurple,),
              activeIcon: Icon(Icons.home,color: AppColors.wellnessGreen,),
              label: "Home"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.history,color: AppColors.therapyPurple,),
              activeIcon: Icon(Icons.history,color: AppColors.wellnessGreen,),
              label: "Bookings"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings,color: AppColors.therapyPurple,),
              activeIcon: Icon(Icons.settings,color: AppColors.wellnessGreen,),
              label: "About-Us"
          ),
          /*BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_camera_back,
              color: tabShadowColor,
              size: 40,
            ),
            activeIcon: Icon(
              Icons.photo_camera_back,
              color: colabColorPrimary,
              size: 40,
            ),
            label: "Gallery",
          ),*/
        ],
        currentIndex: widget.currentIndex, //New
        onTap: onTapped,
        selectedItemColor: AppColors.wellnessGreen,
        unselectedItemColor: AppColors.backgroundLight,
        showUnselectedLabels: true,
      ),
    );
  }
}