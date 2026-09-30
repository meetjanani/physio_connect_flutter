import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:physio_connect/route/route_module.dart';
import 'package:physio_connect/custom_widget/physio_progress_bar.dart';
import 'package:physio_connect/ui/profile/profile_about_us_controller.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/enum.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import '../../utils/constants.dart';

class ProfileAboutUsScreen extends StatefulWidget {
  const ProfileAboutUsScreen({super.key});

  @override
  State<ProfileAboutUsScreen> createState() => _ProfileAboutUsScreenState();
}

class _ProfileAboutUsScreenState extends State<ProfileAboutUsScreen> {
  ProfileAboutUsController controller = ProfileAboutUsController.to;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TODO: Once per app launch
    controller.fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return PhysioProgressOverlay(
      isLoading: controller.isLoading,
      message: 'Looking after your profile…',
      child: Scaffold(
      appBar: commonAppBar("Profile"),
      body: SingleChildScrollView(
        child: Obx(
          () => Column(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // User profile card with avatar
                    if (controller.userModelSupabase.value != null)
                      Card(
                        elevation: 4,
                        shadowColor: AppColors.medicalBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.medicalBlue,
                                    AppColors.wellnessGreen,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    isDoctorTypeUser(
                                          controller.userModelSupabase.value,
                                        )
                                        ? "Doctor Profile"
                                        : "Patient Profile",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Profile avatar with status indicator
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.medicalBlueLight,
                                            width: 3,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                controller.isDoctor.value
                                                    ? controller.doctor.value?.profilePhotoUrl ?? controller.patientProfileImage
                                                    : controller.patientProfileImage,
                                            fit: BoxFit.cover,
                                            width: 80,
                                            height: 80,
                                            placeholder: (_, __) => const Center(
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                ),
                                          ),
                                        ),
                                      ),
                                      // Online status indicator
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            color: AppColors.wellnessGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // User name
                                  Text(
                                    controller.userModelSupabase.value?.name ??
                                        '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),

                                  // User role badge
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isDoctorTypeUser(
                                            controller.userModelSupabase.value,
                                          )
                                          ? AppColors.medicalBlueLight
                                          : AppColors.wellnessGreenLight,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      (controller
                                                  .userModelSupabase
                                                  .value
                                                  ?.userType ??
                                              '') +
                                          '~' +
                                          '${controller.userModelSupabase.value?.id.toString() ?? ''}',
                                      style: TextStyle(
                                        color:
                                            isDoctorTypeUser(
                                              controller
                                                  .userModelSupabase
                                                  .value,
                                            )
                                            ? AppColors.medicalBlueDark
                                            : AppColors.wellnessGreenDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // User phone with icon
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        controller
                                                .userModelSupabase
                                                .value
                                                ?.mobileNumber ??
                                            '',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Doctor Profile with Count of (Today, Pending, Settled) if user is doctor
                                  if (isDoctorTypeUser(
                                    controller.userModelSupabase.value,
                                  ))
                                    FutureBuilder<Map<String, dynamic>>(
                                      future: () async {
                                        final doctor =
                                            controller.doctor.value ??
                                            await controller.supabaseController
                                                .getDoctorByUserId(
                                                  controller
                                                          .userModelSupabase
                                                          .value
                                                          ?.id ??
                                                      0,
                                                );
                                        if (doctor?.userId == null ||
                                            doctor!.userId! <= 0) {
                                          return {
                                            'todayCount': 0,
                                            'pendingCount': 0,
                                            'weekEarnings': 0.0,
                                            'upcomingCount': 0,
                                            'completedCount': 0,
                                            'cancelledNoShowCount': 0,
                                            'totalCount': 0,
                                          };
                                        }
                                        return controller.supabaseController
                                            .getDoctorEarningsSummary(
                                              doctor.userId!,
                                            );
                                      }(),
                                      builder: (context, snapshot) {
                                        final data = snapshot.data ?? {};
                                        return LayoutBuilder(
                                          builder: (context, constraints) {
                                            final stats = [
                                              (
                                                '${data['upcomingCount'] ?? '—'}',
                                                'Upcoming',
                                              ),
                                              (
                                                '${data['completedCount'] ?? '—'}',
                                                'Completed',
                                              ),
                                              (
                                                '${data['cancelledNoShowCount'] ?? '—'}',
                                                'Cancelled / NoShow',
                                              ),
                                              (
                                                '${data['totalCount'] ?? '—'}',
                                                'Total',
                                              ),
                                            ];
                                            return Wrap(
                                              alignment: WrapAlignment.center,
                                              spacing: 8,
                                              runSpacing: 12,
                                              children: stats
                                                  .map(
                                                    (stat) => SizedBox(
                                                      width:
                                                          (constraints
                                                                  .maxWidth -
                                                              8) /
                                                          2,
                                                      child: _buildStatColumn(
                                                        context,
                                                        stat.$1,
                                                        stat.$2,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _showEditNameDialog(context),
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Edit name'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Doctor info card
                    // if (controller.doctor.value != null)
                    //   Card(
                    //     elevation: 4,
                    //     shadowColor: AppColors.medicalBlue,
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(20),
                    //     ),
                    //     child: Column(
                    //       children: [
                    //         Container(
                    //           padding: const EdgeInsets.all(16),
                    //           decoration: const BoxDecoration(
                    //             gradient: LinearGradient(
                    //               colors: [
                    //                 AppColors.medicalBlue,
                    //                 AppColors.wellnessGreen,
                    //               ],
                    //               begin: Alignment.topLeft,
                    //               end: Alignment.bottomRight,
                    //             ),
                    //             borderRadius: BorderRadius.only(
                    //               topLeft: Radius.circular(20),
                    //               topRight: Radius.circular(20),
                    //             ),
                    //           ),
                    //           child: Row(
                    //             children: [
                    //               const Icon(
                    //                 Icons.medical_services,
                    //                 color: Colors.white,
                    //               ),
                    //               const SizedBox(width: 8),
                    //               Text(
                    //                 "Assigned Doctor",
                    //                 style: Theme.of(context)
                    //                     .textTheme
                    //                     .titleMedium
                    //                     ?.copyWith(
                    //                       color: Colors.white,
                    //                       fontWeight: FontWeight.bold,
                    //                     ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //         Padding(
                    //           padding: const EdgeInsets.all(20),
                    //           child: Column(
                    //             children: [
                    //               // Doctor header with avatar and info
                    //               Row(
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 children: [
                    //                   // Doctor avatar
                    //                   Container(
                    //                     decoration: BoxDecoration(
                    //                       shape: BoxShape.circle,
                    //                       boxShadow: [
                    //                         BoxShadow(
                    //                           color: AppColors.medicalBlue
                    //                               .withOpacity(0.2),
                    //                           blurRadius: 10,
                    //                           offset: const Offset(0, 4),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     child: CircleAvatar(
                    //                       radius: 35,
                    //                       backgroundImage: NetworkImage(
                    //                         controller.image,
                    //                       ),
                    //                     ),
                    //                   ),
                    //                   const SizedBox(width: 16),
                    //
                    //                   // Doctor info
                    //                   Expanded(
                    //                     child: Column(
                    //                       crossAxisAlignment:
                    //                           CrossAxisAlignment.start,
                    //                       children: [
                    //                         Text(
                    //                           controller.doctor.value?.name ??
                    //                               '',
                    //                           style: Theme.of(context)
                    //                               .textTheme
                    //                               .titleLarge
                    //                               ?.copyWith(
                    //                                 fontWeight: FontWeight.bold,
                    //                                 color: AppColors
                    //                                     .medicalBlueDark,
                    //                               ),
                    //                         ),
                    //                         const SizedBox(height: 4),
                    //                         Text(
                    //                           controller.doctor.value?.degree ??
                    //                               '',
                    //                           style: Theme.of(context)
                    //                               .textTheme
                    //                               .bodyMedium
                    //                               ?.copyWith(
                    //                                 color:
                    //                                     AppColors.medicalBlue,
                    //                                 fontWeight: FontWeight.w500,
                    //                               ),
                    //                         ),
                    //                         const SizedBox(height: 4),
                    //                         Row(
                    //                           children: [
                    //                             Icon(
                    //                               Icons.star,
                    //                               size: 18,
                    //                               color: AppColors.ratingGold,
                    //                             ),
                    //                             Icon(
                    //                               Icons.star,
                    //                               size: 18,
                    //                               color: AppColors.ratingGold,
                    //                             ),
                    //                             Icon(
                    //                               Icons.star,
                    //                               size: 18,
                    //                               color: AppColors.ratingGold,
                    //                             ),
                    //                             Icon(
                    //                               Icons.star,
                    //                               size: 18,
                    //                               color: AppColors.ratingGold,
                    //                             ),
                    //                             Icon(
                    //                               Icons.star_half,
                    //                               size: 18,
                    //                               color: AppColors.ratingGold,
                    //                             ),
                    //                             const SizedBox(width: 6),
                    //                             Text(
                    //                               "4.8",
                    //                               style: Theme.of(context)
                    //                                   .textTheme
                    //                                   .bodySmall
                    //                                   ?.copyWith(
                    //                                     fontWeight:
                    //                                         FontWeight.bold,
                    //                                   ),
                    //                             ),
                    //                           ],
                    //                         ),
                    //                       ],
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //
                    //               // Experience tag
                    //               Container(
                    //                 margin: const EdgeInsets.symmetric(
                    //                   vertical: 16,
                    //                 ),
                    //                 padding: const EdgeInsets.symmetric(
                    //                   horizontal: 16,
                    //                   vertical: 8,
                    //                 ),
                    //                 decoration: BoxDecoration(
                    //                   color: AppColors.medicalBlueLight,
                    //                   borderRadius: BorderRadius.circular(30),
                    //                 ),
                    //                 child: Row(
                    //                   mainAxisSize: MainAxisSize.min,
                    //                   children: [
                    //                     const Icon(
                    //                       Icons.work_outline,
                    //                       size: 18,
                    //                       color: AppColors.medicalBlueDark,
                    //                     ),
                    //                     const SizedBox(width: 8),
                    //                     Text(
                    //                       "${controller.doctor.value?.experience ?? ''} Experience",
                    //                       style: const TextStyle(
                    //                         color: AppColors.medicalBlueDark,
                    //                         fontWeight: FontWeight.w600,
                    //                       ),
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //
                    //               // Bio with quotes
                    //               Container(
                    //                 padding: const EdgeInsets.all(16),
                    //                 decoration: BoxDecoration(
                    //                   color: AppColors.backgroundLight,
                    //                   borderRadius: BorderRadius.circular(16),
                    //                   border: Border.all(
                    //                     color: AppColors.border,
                    //                     width: 1,
                    //                   ),
                    //                 ),
                    //                 child: Column(
                    //                   children: [
                    //                     Row(
                    //                       children: [
                    //                         const Icon(
                    //                           Icons.format_quote,
                    //                           color: AppColors.medicalBlue,
                    //                           size: 24,
                    //                         ),
                    //                         const SizedBox(width: 8),
                    //                         Text(
                    //                           "Biography",
                    //                           style: Theme.of(context)
                    //                               .textTheme
                    //                               .titleSmall
                    //                               ?.copyWith(
                    //                                 fontWeight: FontWeight.bold,
                    //                               ),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     const SizedBox(height: 8),
                    //                     Text(
                    //                       controller.doctor.value?.biodata ??
                    //                           '',
                    //                       style: Theme.of(
                    //                         context,
                    //                       ).textTheme.bodyMedium,
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //
                    //               const SizedBox(height: 16),
                    //
                    //               // Contact doctor button
                    //               ElevatedButton.icon(
                    //                 style: ElevatedButton.styleFrom(
                    //                   backgroundColor: AppColors.medicalBlue,
                    //                   foregroundColor: Colors.white,
                    //                   padding: const EdgeInsets.symmetric(
                    //                     vertical: 12,
                    //                     horizontal: 24,
                    //                   ),
                    //                   shape: RoundedRectangleBorder(
                    //                     borderRadius: BorderRadius.circular(30),
                    //                   ),
                    //                   elevation: 3,
                    //                 ),
                    //                 icon: const Icon(Icons.message),
                    //                 label: const Text("Contact Doctor"),
                    //                 onPressed: () {
                    //                   // Contact doctor action
                    //                 },
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    if (isDoctorTypeUser(controller.userModelSupabase.value))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.medicalBlueDark,
                            side: const BorderSide(
                              color: AppColors.medicalBlue,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.schedule, size: 22),
                          label: const Text(
                            'Manage Time Slot',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => Get.toNamed(AppPage.manageTimeSlot),
                        ),
                      ),

                    // Logout button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.error.withOpacity(0.3),
                      ),
                      icon: const Icon(Icons.logout, size: 24),
                      label: const Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        // Logout action
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Logout pressed")),
                        );
                        controller.logout();
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.medicalBlueDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Future<void> _showEditNameDialog(BuildContext context) async {
    final nameController = TextEditingController(
      text: controller.userModelSupabase.value?.name ?? '',
    );
    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Your full name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Get.back(result: nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await controller.updateDisplayName(result);
    }
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
