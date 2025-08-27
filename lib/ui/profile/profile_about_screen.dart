import 'package:flutter/material.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

class ProfileAboutScreen extends StatelessWidget {
  const ProfileAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final user = {
      "avatar": "https://i.pravatar.cc/150?img=3",
      "name": "John Doe",
      "phone": "+91 9876543210",
      "type": "Doctor", // or "Patient"
    };
    final doctor = {
      "avatar": "https://i.pravatar.cc/150?img=5",
      "name": "Dr. Priya Sharma",
      "degree": "MPT (Ortho), BPT",
      "experience": "8 years",
      "bio": "Dr. Priya Sharma is a senior physiotherapist specializing in orthopedics and sports injuries. She believes in holistic healing and personalized care for every patient. Her expertise includes manual therapy, exercise prescription, and patient education.",
    };

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Profile & About Us"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Info
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(user["avatar"]!),
                      backgroundColor: AppColors.therapyPurpleLight,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user["name"]!, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(user["phone"]!, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(user["type"]!),
                            backgroundColor: user["type"] == "Doctor"
                                ? AppColors.medicalBlueLight
                                : AppColors.wellnessGreenLight,
                            labelStyle: TextStyle(
                              color: user["type"] == "Doctor"
                                  ? AppColors.medicalBlueDark
                                  : AppColors.wellnessGreenDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Assigned Doctor Info
            Text("Assigned Doctor", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(doctor["avatar"]!),
                      backgroundColor: AppColors.medicalBlueLight,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctor["name"]!, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(doctor["degree"]!, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.work_outline, size: 18, color: AppColors.therapyPurple),
                              const SizedBox(width: 4),
                              Text("${doctor["experience"]} experience",
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            doctor["bio"]!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              onPressed: () {
                // TODO: Implement logout logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Logout pressed")),
                );
              },
            ),
            const SizedBox(height: 32),

            // About Us Section
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: AppColors.therapyPurpleLight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("About Us", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      "Physio Connect",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.therapyPurpleDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 18, color: AppColors.therapyPurple),
                        const SizedBox(width: 6),
                        Text(
                          "physioconnect.app@gmail.com",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

