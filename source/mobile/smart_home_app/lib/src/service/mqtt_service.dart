import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:smart_home_app/src/model/data/schedule.dart';

class MqttService {
  static const String _host = 'rabbitmq.bhbl.vn';
  static const int _port = 1883;
  static const String _user = 'iots';
  static const String _password = 'Tintin@123';
  static const String _statusTopic = 'smartplug/status';
  static const String _scheduleTopic = 'smartplug/schedule';
  static const String _statusReportTopic = 'smartplug/status_report';

  final _relayStateController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _subscribed = false;

  Stream<Map<String, dynamic>> get relayStateStream =>
      _relayStateController.stream;

  MqttServerClient? _client;

  Future<bool> connect() async {
    if (_client != null && _client!.connectionStatus?.state == MqttConnectionState.connected) {
      return true;
    }

    final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(_host, clientId, _port);
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 60;
    _client!.connectTimeoutPeriod = 5000;
    _client!.onDisconnected = _onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(_user, _password)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        print('[MQTT] Connected to $_host');
        _setupSubscription();
        return true;
      }
    } on SocketException catch (e) {
      print('[MQTT] SocketException: $e');
    } catch (e) {
      print('[MQTT] Connect error: $e');
    }

    _client = null;
    return false;
  }

  void _setupSubscription() {
    if (_subscribed || _client == null) return;
    _client!.subscribe(_statusReportTopic, MqttQos.atLeastOnce);
    _client!.updates?.listen(_onMessage);
    _subscribed = true;
    print('[MQTT] Subscribed to $_statusReportTopic');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage?>>? messages) {
    if (messages == null) return;
    for (final msg in messages) {
      final pub = msg.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
          pub.payload.message);
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        if (data.containsKey('device_id') && data.containsKey('relay_status')) {
          _relayStateController.add(data);
        }
      } catch (_) {}
    }
  }

  void _onDisconnected() {
    print('[MQTT] Disconnected');
    _client = null;
  }

  Future<bool> publishRelayCommand(String deviceId, bool value) async {
    final connected = await connect();
    if (!connected) {
      print('[MQTT] Cannot connect, skip publish');
      return false;
    }

    final payload = jsonEncode({
      'id': deviceId,
      'type': 'device',
      'value': value,
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    try {
      _client!.publishMessage(
        _statusTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );
      print('[MQTT] Published → $_statusTopic: $payload');
      return true;
    } catch (e) {
      print('[MQTT] Publish error: $e');
      _client = null;
      return false;
    }
  }

  Future<bool> publishScheduleUpdate(List<Schedule> schedules) async {
    final connected = await connect();
    if (!connected) {
      print('[MQTT] Cannot connect, skip schedule publish');
      return false;
    }

    final payload = jsonEncode(schedules.map((s) => s.toJson()).toList());
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    try {
      _client!.publishMessage(
        _scheduleTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );
      print('[MQTT] Published schedule update (${schedules.length} items) → $_scheduleTopic');
      return true;
    } catch (e) {
      print('[MQTT] Schedule publish error: $e');
      _client = null;
      return false;
    }
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
    _subscribed = false;
  }

  void dispose() {
    _relayStateController.close();
    disconnect();
  }
}
