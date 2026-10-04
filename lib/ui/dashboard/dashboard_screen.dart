import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/ui/booking_history/booking_history_controller.dart';
import 'package:physio_connect/ui/dashboard/dashboard_controller.dart';
import 'package:physio_connect/utils/constants.dart';

import '../../model/bookings_model.dart';
import '../../route/route_module.dart';
import '../../utils/common_appbar.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/units_extensions.dart';
import '../doctors/doctor_directory_card.dart';
import '../doctors/doctor_directory_controller.dart';
import '../booking_history/online_session_actions.dart';

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
    controller.getUpComingBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar("PhysioConnect"),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 20.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                96,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Obx(() {
                    final hasAppointment =
                        controller.upComingBookings.isNotEmpty;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            constraints.maxWidth < 360 ? 16 : 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            gradient: LinearGradient(
                              colors: AppColors.backgroundGradientColors,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: hasAppointment
                              ? _buildAppointmentView()
                              : _buildNoAppointmentView(),
                        ),
                        if (!isDoctorTypeUser(controller.userModelSupabase))
                          _buildPhysiotherapistsSection(),
                      ],
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed(AppPage.selectServiceCity);
          // Navigate to booking screen
        },
        backgroundColor: AppColors.medicalBlue,
        foregroundColor: AppColors.textOnDark,
        elevation: 4,
        icon: Icon(Icons.add),
        label: Text(
          'Book Appointment',
          style: GoogleFonts.inter(
            textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.medicalBlueLight.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.event_busy,
            size: 40,
            color: AppColors.medicalBlueDark.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "No upcoming appointments",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Book your next session to continue your progress",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            textStyle: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentView() {
    final appointment = controller.upComingBookings.first;
    var isDoctor = isDoctorTypeUser(controller.userModelSupabase);
    var nameOfPerson = isDoctor
        ? appointment.aPatient().name
        : appointment.aDoctor().name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.medicalBlueLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_note, color: AppColors.medicalBlueDark),
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
                        color: AppColors.medicalBlueDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "with $nameOfPerson",
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        color: AppColors.textPrimary,
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.medicalBlue),
                    const SizedBox(height: 8),
                    Text(
                      formatDateToReadable(appointment.bookingDate),
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      formatDateToWeekday(appointment.bookingDate),
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 60, color: AppColors.border),
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.access_time, color: AppColors.medicalBlue),
                    const SizedBox(height: 8),
                    Text(
                      appointment.aTimeslot().time,
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      appointment.aSessionType().duration,
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: AppColors.textSecondary,
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
        if (appointment.isOnlineSession)
          OnlineSessionActions(
            booking: appointment,
            isDoctor: isDoctor,
            compact: true,
          ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final buttons = [
              OutlinedButton.icon(
                onPressed: () => _openAppointment(appointment),
                icon: const Icon(Icons.edit_calendar),
                label: const Text("Reschedule"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.medicalBlueDark,
                  side: BorderSide(color: AppColors.medicalBlueDark),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openAppointment(appointment),
                icon: const Icon(Icons.visibility),
                label: const Text("View Details"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medicalBlueDark,
                  foregroundColor: AppColors.textOnDark,
                ),
              ),
            ];
            if (constraints.maxWidth < 380) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [buttons[0], const SizedBox(height: 8), buttons[1]],
              );
            }
            return Row(
              children: [
                Expanded(child: buttons[0]),
                const SizedBox(width: 12),
                Expanded(child: buttons[1]),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhysiotherapistsSection() {
    if (!Get.isRegistered<DoctorDirectoryController>()) {
      return const SizedBox.shrink();
    }
    final directory = DoctorDirectoryController.to;
    if (directory.isLoadingCatalog.value && directory.doctors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final preview = directory.homePreviewDoctors;
    if (preview.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Our physiotherapists',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppPage.doctors),
                child: Text(
                  'See all',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.medicalBlueDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Learn about the clinicians who visit your area.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...preview.map(
            (doctor) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DoctorDirectoryCard(
                doctor: doctor,
                coverageLabel: directory.firstCoverageLabel(doctor),
                onTap: () => Get.toNamed(
                  AppPage.doctorProfile,
                  arguments: {
                    'doctorId': doctor.id ?? 0,
                    'preview': doctor,
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAppointment(BookingsModel appointment) {
    Get.put(BookingHistoryController()).selectedAppointment.value = appointment;
    Get.toNamed(AppPage.bookingDetail, arguments: appointment);
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
        'color': AppColors.medicalBlueDark,
        'icon': Icons.ac_unit,
        'image': 'https://images.unsplash.com/photo-1563456020159-b74d547b3973',
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
                  child: Icon(Icons.error, color: AppColors.textOnDark),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(tip['icon'], color: AppColors.textOnDark, size: 32),
                    SizedBox(height: 8),
                    Text(
                      tip['title'],
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      tip['description'],
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: 14,
                        ),
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
                          color: AppColors.textOnDark,
                          size: 16,
                        ),
                        label: Text(
                          "Learn More",
                          style: TextStyle(
                            color: AppColors.textOnDark,
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
