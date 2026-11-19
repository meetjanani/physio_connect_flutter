import 'package:get/get.dart';
import 'package:physio_connect/model/area_model.dart';
import 'package:physio_connect/model/city_state_model.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/model/session_type_model.dart';
import 'package:physio_connect/supabase/supabase_controller.dart';

class DoctorCoverage {
  DoctorCoverage({required this.area, this.city});

  final AreaModel area;
  final CityStateModel? city;

  String get label {
    final cityName = city?.cityStateName.trim() ?? '';
    if (cityName.isEmpty) return area.areaName;
    return '${area.areaName} · $cityName';
  }
}

class DoctorDirectoryController extends GetxController {
  static DoctorDirectoryController get to => Get.find();

  final SupabaseController _supabase = SupabaseController.to;

  final isLoadingCatalog = false.obs;
  final isLoadingProfile = false.obs;
  final catalogError = ''.obs;
  final profileError = ''.obs;
  final searchQuery = ''.obs;

  final doctors = <DoctorModel>[].obs;
  final coverageByDoctorId = <int, List<DoctorCoverage>>{}.obs;

  final profileDoctor = Rx<DoctorModel?>(null);
  final profileCoverage = <DoctorCoverage>[].obs;
  final profileSessionTypes = <SessionTypeModel>[].obs;
  final preferredAreaId = Rxn<int>();
  final preferredCityId = Rxn<int>();

  List<DoctorModel> get filteredDoctors {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return doctors.toList();
    return doctors.where((doctor) {
      final name = doctor.name?.toLowerCase() ?? '';
      final degree = doctor.degree?.toLowerCase() ?? '';
      final experience = doctor.experience?.toLowerCase() ?? '';
      return name.contains(query) ||
          degree.contains(query) ||
          experience.contains(query);
    }).toList();
  }

  List<DoctorModel> get homePreviewDoctors => filteredDoctors.take(3).toList();

  List<DoctorCoverage> coverageFor(DoctorModel doctor) {
    final id = doctor.id ?? 0;
    return coverageByDoctorId[id] ?? const <DoctorCoverage>[];
  }

  String firstCoverageLabel(DoctorModel doctor) {
    final coverage = coverageFor(doctor);
    if (coverage.isEmpty) return '';
    return coverage.first.label;
  }

  @override
  void onInit() {
    super.onInit();
    loadCatalog();
  }

  Future<void> loadCatalog() async {
    isLoadingCatalog.value = true;
    catalogError.value = '';
    try {
      final results = await Future.wait([
        _supabase.getActiveDoctors(),
        _supabase.getActiveServiceAreas(),
        _supabase.getCityState(),
      ]);
      final loadedDoctors = results[0] as List<DoctorModel>;
      final areas = results[1] as List<AreaModel>;
      final cities = results[2] as List<CityStateModel>;
      final citiesById = {for (final city in cities) city.id: city};
      final mapped = <int, List<DoctorCoverage>>{};
      for (final area in areas) {
        final doctorId = area.doctorId ?? 0;
        if (doctorId <= 0) continue;
        mapped
            .putIfAbsent(doctorId, () => <DoctorCoverage>[])
            .add(DoctorCoverage(area: area, city: citiesById[area.cityStateId]));
      }
      doctors.assignAll(loadedDoctors);
      coverageByDoctorId.assignAll(mapped);
    } catch (_) {
      catalogError.value = 'Unable to load physiotherapists right now.';
    } finally {
      isLoadingCatalog.value = false;
    }
  }

  Future<void> openProfile({
    required int doctorId,
    DoctorModel? preview,
    int? areaId,
    int? cityId,
  }) async {
    preferredAreaId.value = areaId;
    preferredCityId.value = cityId;
    profileDoctor.value = preview;
    profileCoverage.clear();
    profileSessionTypes.clear();
    profileError.value = '';
    if (doctorId <= 0 && preview == null) {
      profileError.value = 'This profile is not available.';
      return;
    }
    isLoadingProfile.value = true;
    try {
      final doctor = await _supabase.getDoctorPublicById(doctorId) ?? preview;
      if (doctor == null) {
        profileError.value = 'This physiotherapist is not available.';
        profileDoctor.value = null;
        return;
      }
      profileDoctor.value = doctor;
      await Future.wait([
        _loadCoverage(doctor.id ?? doctorId),
        _loadSessionTypes(doctor),
      ]);
    } catch (_) {
      profileError.value = 'Unable to load this profile.';
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> _loadCoverage(int doctorId) async {
    final cached = coverageByDoctorId[doctorId];
    if (cached != null) {
      profileCoverage.assignAll(cached);
      return;
    }
    final areas = await _supabase.getAreasServedByDoctor(doctorId);
    final cities = await _supabase.getCityState();
    final citiesById = {for (final city in cities) city.id: city};
    profileCoverage.assignAll(
      areas
          .map(
            (area) => DoctorCoverage(
              area: area,
              city: citiesById[area.cityStateId],
            ),
          )
          .toList(),
    );
  }

  Future<void> _loadSessionTypes(DoctorModel doctor) async {
    final configured = _csvIds(doctor.sessionTypeId);
    final types = await _supabase.getSessionTypeMaster(
      sessionTypeIds: configured.isEmpty ? null : configured,
    );
    profileSessionTypes.assignAll(types);
  }

  List<int> _csvIds(String? raw) {
    return raw
            ?.split(',')
            .map((value) => int.tryParse(value.trim()))
            .whereType<int>()
            .where((id) => id > 0)
            .toSet()
            .toList() ??
        <int>[];
  }
}
