import 'package:get/get.dart';

import 'controller.dart';

class ClientBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ClientsController>(ClientsController(), permanent: true);
  }
}
