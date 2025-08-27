import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/ui/dashboard/dashboard_controller.dart';

import '../../route/route_module.dart';
import '../../utils/common_appbar.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/units_extensions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardController controller = DashboardController.to;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TODO: Once per app launch
    controller.fetchFirebaseToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar("Physio Connect"),
      body: SafeArea(
        child: Center(
          child: Obx(() => Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Get.height * 0.02),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: Get.height * 0.2,
                        ),
                        child: Container(
                          width: Get.width,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.textMuted,
                              width: 2,
                            ),
                            gradient: LinearGradient(
                              colors: AppColors.backgroundGradientColors,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: controller.upComingBookings.value.isNotEmpty
                                ? _buildAppointmentView()
                                : _buildNoAppointmentView(),
                          ),
                        ),
                      ),
                      // Add this after your appointment container
                      SizedBox(height: 24),
                      Text(
                        "Health & Recovery Tips",
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: 230,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          children: _buildHealthTipCards(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed(AppPage.selectSessionType);
          // Navigate to booking screen
        },
        backgroundColor: AppColors.therapyPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(Icons.add),
        label: Text(
          'Book Appointment',
          style: GoogleFonts.inter(
            textStyle: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // Add these methods to your class
  Widget _buildNoAppointmentView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event_busy, size: 60, color: Colors.black.withOpacity(0.7)),
        const SizedBox(height: 16),
        Text(
          "No upcoming appointments",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Book your next session to continue your progress",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          onPressed: () {
            // Navigate to booking screen
          },
          backgroundColor: AppColors.therapyPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: Icon(Icons.add),
          label: Text(
            'Book Appointment',
            style: GoogleFonts.inter(
              textStyle: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
       /* CustomButton(
          text: 'Book Appointment',
          onPressed: () {
            // Navigate to booking screen
          },
          isLoading: controller.isLoading.value,
          size: ButtonSize.small,
          gradient: const LinearGradient(
            colors: [AppColors.wellnessGreenDark, AppColors.wellnessGreen],
          ),
          borderRadius: BorderRadius.circular(30),
          width: Get.width * 0.5,
        ),*/
      ],
    );
  }

  Widget _buildAppointmentView() {
    var appointment = controller.upComingBookings.value.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_note, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Next Appointment",
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "with ${appointment.aDoctor().name}",
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      formatDateToReadable(appointment.bookingDate),
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      formatDateToWeekday(appointment.bookingDate),
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey.shade300),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      appointment.aTimeslot().time,
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      appointment.aSessionType().duration,
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                // Handle reschedule
              },
              icon: const Icon(Icons.edit_calendar),
              label: const Text("Reschedule"),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue.shade700),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Handle view details
              },
              icon: const Icon(Icons.visibility),
              label: const Text("View Details"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildHealthTipCards() {
    final List<Map<String, dynamic>> healthTips = [
      {
        'title': 'Proper Posture',
        'description':
            'Keep your back straight and shoulders relaxed when sitting. Your feet should be flat on the floor.',
        'color': AppColors.therapyPurple,
        'icon': Icons.accessibility_new,
        'image': 'https://images.unsplash.com/photo-1559599101-f09722fb4948',
        // Add these images to your assets
      },
      {
        'title': 'Daily Stretching',
        'description':
            'Spend 10 minutes each morning stretching major muscle groups to improve flexibility and reduce pain.',
        'color': AppColors.medicalBlue,
        'icon': Icons.fitness_center,
        'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b',
      },
      {
        'title': 'Ice vs. Heat',
        'description':
            'Use ice for acute injuries (first 48 hours) and heat for chronic pain and muscle stiffness.',
        'color': AppColors.inProgress,
        'icon': Icons.ac_unit,
        'image':
            ' https://images.unsplash.com/photo-1563456020159-b74d547b3973',
      },
      {
        'title': 'Ergonomic Workspace',
        'description':
            'Position your monitor at eye level and keep wrists neutral when typing to prevent strain.',
        'color': AppColors.orthopedic,
        'icon': Icons.computer,
        'image': 'https://images.unsplash.com/photo-1593062096033-9a26b09da705',
      },
      {
        'title': 'Hydration Matters',
        'description':
            'Drink 8-10 glasses of water daily to keep muscles and joints lubricated and reduce stiffness.',
        'color': AppColors.wellnessGreen,
        'icon': Icons.water_drop,
        'image': 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d',
      },
      {
        'title': 'Sleep Position',
        'description':
            'Sleep on your back or side with a pillow between your knees to maintain proper spinal alignment.',
        'color': AppColors.neurological,
        'icon': Icons.nightlight,
        'image': 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55',
      },
      {
        'title': 'Sleep Position',
        'description':
            'Sleep on your back or side with a pillow between your knees to maintain proper spinal alignment.',
        'color': AppColors.neurological,
        'icon': Icons.nightlight,
        'image': 'assets/images/sleep.jpg',
      },
    ];

    return healthTips.map((tip) {
      return Container(
        width: 280,
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: tip['color'].withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image placeholder - replace with actual images
              CachedNetworkImage(
                imageUrl: tip['image'],
                height: 240,
                width: 280,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tip['color'].withOpacity(0.8),
                        tip['color'].withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tip['color'].withOpacity(0.8),
                        tip['color'].withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: Icon(Icons.error, color: Colors.white),
                ),
              ),
              /*Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tip['color'].withOpacity(0.8),
                      tip['color'].withOpacity(0.6),
                    ],
                  ),
                ),
                height: 220,
                width: 280,
              ),*/
              // Content
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(tip['icon'], color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text(
                      tip['title'],
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      tip['description'],
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton.icon(
                        onPressed: () {
                          // Handle tap on learn more
                        },
                        icon: Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                          size: 16,
                        ),
                        label: Text(
                          "Learn More",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerRight,
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
    }).toList();
  }
}
