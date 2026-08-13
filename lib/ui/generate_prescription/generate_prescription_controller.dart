import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:physio_connect/model/bookings_model.dart';
import 'package:physio_connect/services/prescription_service.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

class GeneratePrescriptionController extends GetxController {
  static GeneratePrescriptionController get to => Get.put(GeneratePrescriptionController());

  final formKey = GlobalKey<FormState>();

  final patientNameController = TextEditingController();
  final patientAddressController = TextEditingController();

  final sessionTypeController = TextEditingController(text: 'General Physiotherapy');
  final sessionDescriptionController = TextEditingController(text: 'Mussel Strengthening');
  final sessionQtyController = TextEditingController(text: '1');
  final sessionAmountController = TextEditingController(text: '600');
  final doctorNameController = TextEditingController(text: 'Dr. Parul Desai');
  final specialistController = TextEditingController(text: 'Physiotherapist');
  final doctorCredentialsController =
      TextEditingController(text: 'Physiotherapist GPC-2345');

  final isGenerating = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is BookingsModel) {
      final patient = args.aPatient();
      patientNameController.text = patient.name ?? '';
      patientAddressController.text = args.address ?? '';
      sessionTypeController.text = args.aSessionType().name;
      sessionDescriptionController.text = args.aSessionType().name;
      doctorNameController.text = args.aDoctor().name ?? 'Dr. Parul Desai';
      specialistController.text = args.aDoctor().degree ?? 'Physiotherapist';
    }
  }

  Future<void> generatePrescription() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final int qty = int.tryParse(sessionQtyController.text.trim()) ?? 0;
    final double amount = double.tryParse(sessionAmountController.text.trim()) ?? 0;

    if (qty <= 0 || amount <= 0) {
      Get.snackbar(
        'Invalid values',
        'Session quantity and amount must be greater than 0.',
        backgroundColor: AppColors.errorLight,
        colorText: AppColors.error,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isGenerating.value = true;

    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppColors.medicalBlue),
              SizedBox(height: 16),
              Text('Generating Prescription...'),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final file = await PrescriptionService.generatePrescription(
        PrescriptionData(
          patientName: patientNameController.text.trim(),
          patientAddress: patientAddressController.text.trim(),
          sessionType: sessionTypeController.text.trim(),
          sessionDescription: sessionDescriptionController.text.trim(),
          sessionQty: qty,
          sessionAmount: amount,
          doctorName: doctorNameController.text.trim(),
          specialist: specialistController.text.trim(),
          doctorCredentials: doctorCredentialsController.text.trim(),
          createdAt: DateTime.now(),
        ),
      );

      Get.back();
      await PrescriptionService.openPdf(file);
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Failed to generate prescription: ${e.toString()}',
        backgroundColor: AppColors.errorLight,
        colorText: AppColors.error,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isGenerating.value = false;
    }
  }

  @override
  void onClose() {
    patientNameController.dispose();
    patientAddressController.dispose();
    sessionTypeController.dispose();
    sessionDescriptionController.dispose();
    sessionQtyController.dispose();
    sessionAmountController.dispose();
    doctorNameController.dispose();
    specialistController.dispose();
    doctorCredentialsController.dispose();
    super.onClose();
  }
}

