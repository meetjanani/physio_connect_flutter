import 'package:get/get.dart';

import '../../supabase/supabase_controller.dart';

class SessionTypeController extends GetxController {
  static SessionTypeController get to => Get.find();
  SessionTypeController();
  SupabaseController supabaseController =
      SupabaseController.to;




}