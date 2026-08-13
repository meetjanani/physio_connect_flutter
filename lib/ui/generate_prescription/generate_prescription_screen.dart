import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:physio_connect/custom_widget/custom_button.dart';
import 'package:physio_connect/custom_widget/custom_text_field.dart';
import 'package:physio_connect/utils/common_appbar.dart';

import 'generate_prescription_controller.dart';

class GeneratePrescriptionScreen extends StatefulWidget {
  const GeneratePrescriptionScreen({super.key});

  @override
  State<GeneratePrescriptionScreen> createState() => _GeneratePrescriptionScreenState();
}

class _GeneratePrescriptionScreenState extends State<GeneratePrescriptionScreen> {
  final GeneratePrescriptionController controller =
      Get.put(GeneratePrescriptionController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar('Generate Prescription', isBackButtonVisible: true),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('PRESCRIPTION TO'),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.patientNameController,
                  labelText: 'Patient Name',
                  hintText: 'Enter patient name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) => _required(value, 'Patient name is required'),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.patientAddressController,
                  labelText: 'Patient Address',
                  hintText: 'Enter patient address',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 3,
                  validator: (value) => _required(value, 'Patient address is required'),
                ),
                const SizedBox(height: 20),
                _sectionTitle('APPOINTMENT DETAILS'),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.sessionTypeController,
                  labelText: 'Session Type',
                  hintText: 'General Physiotherapy',
                  prefixIcon: Icons.spa_outlined,
                  validator: (value) => _required(value, 'Session type is required'),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.sessionDescriptionController,
                  labelText: 'Session Description',
                  hintText: 'Mussel Strengthening',
                  prefixIcon: Icons.spa_outlined,
                  validator: (value) => _required(value, 'Session description is required'),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.sessionQtyController,
                  labelText: 'Session Qty',
                  hintText: '1',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.format_list_numbered,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _validateQty,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.sessionAmountController,
                  labelText: 'Session Amount',
                  hintText: '600',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: _validateAmount,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.doctorNameController,
                  labelText: 'Doctor Name',
                  hintText: 'Dr. Parul Desai',
                  prefixIcon: Icons.medical_information_outlined,
                  validator: (value) => _required(value, 'Doctor name is required'),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.specialistController,
                  labelText: 'Specialist',
                  hintText: 'Physiotherapist',
                  prefixIcon: Icons.workspace_premium_outlined,
                  validator: (value) => _required(value, 'Specialist is required'),
                ),
                const SizedBox(height: 20),
                _sectionTitle('SIGNATURE DETAILS'),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.doctorCredentialsController,
                  labelText: 'Doctor Degree & Registered Number',
                  hintText: 'Physiotherapist GPC-2345',
                  prefixIcon: Icons.badge_outlined,
                  validator: (value) =>
                      _required(value, 'Doctor degree and register number is required'),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => CustomButton(
                    text: 'Generate Prescription',
                    onPressed: controller.isGenerating.value
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            controller.generatePrescription();
                          },
                    isLoading: controller.isGenerating.value,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  String? _required(String? value, String message) {
    if ((value ?? '').trim().isEmpty) {
      return message;
    }
    return null;
  }

  String? _validateQty(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Session qty is required';
    }
    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) {
      return 'Session qty must be greater than 0';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Session amount is required';
    }
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) {
      return 'Session amount must be greater than 0';
    }
    return null;
  }
}

