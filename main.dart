import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(ChargeMonitorApp());
}

class ChargeMonitorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChargeMonitor',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF071024),
        cardColor: Color(0x0AFFFFFF),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel('com.user.charge_monitor/battery');

  int batteryLevel = 0;
  double voltage = 0.0;
  double current = 0.0;
  double power = 0.0;
  String timeToFull = 'Unknown';
  bool isCharging = false;
  Timer? _timer;
  int batteryCapacityMah = 4000; // Default estimate. Edit in Android code or here for better estimate.

  @override
  void initState() {
    super.initState();
    _fetchBatteryInfo();
    _timer = Timer.periodic(Duration(seconds: 5), (_) => _fetchBatteryInfo());
  }

  Future<void> _fetchBatteryInfo() async {
    try {
      final result = await platform.invokeMethod('getBatteryInfo');
      if (result is Map) {
        setState(() {
          batteryLevel = (result['level'] ?? 0).toInt();
          voltage = ((result['voltage'] ?? 0) / 1000.0).toDouble(); // from mV to V
          current = ((result['current'] ?? 0)).toDouble(); // mA (may be negative on discharge depending on device)
          power = (voltage * (current.abs()) / 1000.0);
          isCharging = (result['isCharging'] ?? false);
          // estimate time to full in minutes using capacity and current
          if (current > 50 && isCharging) {
            final remainingPercent = 100 - batteryLevel;
            final hours = (batteryCapacityMah * (remainingPercent/100)) / current;
            final mins = (hours * 60).round();
            timeToFull = _formatMinutes(mins);
          } else {
            timeToFull = 'Estimating...';
          }
        });
      }
    } on PlatformException catch (e) {
      print("Platform exception: \$e");
    }
  }

  String _formatMinutes(int mins) {
    if (mins <= 0) return '0m';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0) return '\${h}h \${m}m';
    return '\${m}m';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Card(
      color: Color(0x11223344),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Padding(padding: padding ?? EdgeInsets.all(18), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('⚡ ChargeMonitor', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children:[
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0x11226699),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.battery_charging_full, color: Colors.cyanAccent),
                  ),
                  SizedBox(width: 12),
                  Text('Battery Level', style: TextStyle(color: Colors.white70)),
                ]),
                SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\${batteryLevel}%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                    SizedBox(width: 12),
                  ],
                ),
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: batteryLevel / 100,
                    minHeight: 10,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                  ),
                ),
                SizedBox(height: 8),
                Text(isCharging ? 'Fast charging' : 'Not charging', style: TextStyle(color: Colors.greenAccent)),
              ],
            ),
          ),
          _card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Current Draw', style: TextStyle(color: Colors.white70)),
                  SizedBox(height:8),
                  Text('\${current.toStringAsFixed(2)}mA', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height:6),
                  Text(isCharging ? 'Fast charging detected' : '', style: TextStyle(color: Colors.greenAccent)),
                ]),
                Icon(Icons.bolt, size: 48, color: Colors.cyanAccent),
              ],
            )
          ),
          _card(child: Column(children:[
            Text('Voltage', style: TextStyle(color: Colors.white70)),
            SizedBox(height:8),
            Text('\${voltage.toStringAsFixed(1)}V', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ])),
          _card(child: Column(children:[
            Text('Charging Power', style: TextStyle(color: Colors.white70)),
            SizedBox(height:8),
            Text('\${power.toStringAsFixed(1)}W', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ])),
          _card(child: Column(children:[
            Row(children:[Icon(Icons.access_time, size:20), SizedBox(width:8), Text('Time to Full', style: TextStyle(color: Colors.white70))]),
            SizedBox(height:12),
            Text(timeToFull, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ])),
          SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Charging History (coming soon)', style: TextStyle(color: Colors.white70)),
          ),
          SizedBox(height: 120),
        ]),
      ),
    );
  }
}
