import 'package:smart_home_app/src/model/data/device.dart';

class UpsertDeviceArgument {
  final Devices? devices;
  final String id;
  UpsertDeviceArgument({this.devices, this.id = ''});
}
