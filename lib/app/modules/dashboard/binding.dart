

import 'package:get/get.dart';
import 'package:legalsteward/app/modules/dashboard/controller.dart';

import '../tasks/task_controller.dart';

class DashBoardBinding extends Bindings{
  @override
  void dependencies() {
    
    Get.put(DashBoardController(), permanent: true  );
    Get.put(TaskController(), permanent: true);
  }
}
