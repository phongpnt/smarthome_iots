import 'package:smart_home_app/src/model/smart_home_device.dart';

final smartModel = [
  {
    'id': 1,
    'title': 'Smart Lamp',
    'category': 'Dining Room',
    'image': SmartHomeType.light
  },
  {
    'id': 2,
    'title': 'Air Conditioner',
    'category': 'Bedroom',
    'image': SmartHomeType.ac
  },
  {
    'id': 3,
    'title': 'Smart Lamp',
    'category': 'Bedroom 2',
    'image': SmartHomeType.light
  },
  {
    'id': 4,
    'title': 'Television',
    'category': 'Leving Room',
    'image': SmartHomeType.tv
  },
  {
    'id': 5,
    'title': 'Air Conditioner',
    'category': 'Bedroom',
    'image': SmartHomeType.ac
  },
  {
    'id': 6,
    'title': 'Smart Lamp',
    'category': 'Bedroom 3',
    'image': SmartHomeType.light
  },
];

enum SmartHomeType { light, ac, tv }

final models = [
  SmartHomeDevice(
    id: 1,
    title: 'Smart Lamp',
    category: 'Dining Room',
    homeType: SmartHomeType.light,
  ),
  SmartHomeDevice(
    id: 2,
    title: 'Air Conditioner',
    category: 'Bedroom',
    homeType: SmartHomeType.ac,
  ),
  SmartHomeDevice(
    id: 1,
    title: 'Smart Lamp',
    category: 'Bedroom 2',
    homeType: SmartHomeType.light,
  ),
  SmartHomeDevice(
    id: 1,
    title: 'Television',
    category: 'Leving Room',
    homeType: SmartHomeType.tv,
  ),
  SmartHomeDevice(
    id: 1,
    title: 'Air Conditioner',
    category: 'Bedroom',
    homeType: SmartHomeType.ac,
  ),
  SmartHomeDevice(
    id: 1,
    title: 'Smart Lamp',
    category: 'Bedroom 3',
    homeType: SmartHomeType.light,
  ),
];
