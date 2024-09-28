import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutterfirebaseapp/SensorData.dart';
import 'package:flutterfirebaseapp/firebase_options.dart';

import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutterfirebaseapp/notification_helper.dart';
import 'package:intl/intl.dart';
import 'chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Workmanager().initialize(callbackDispatcher);
  await NotificationHelper.initialize();
  Workmanager().registerPeriodicTask("degerkontrol", "degerkontrol",
      frequency: const Duration(minutes: 15));
  runApp(const MainApp());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Map<dynamic, dynamic> values = {};
    DatabaseReference starCountRef = FirebaseDatabase.instance.ref('proje');
    await starCountRef.once().then((DatabaseEvent event) {
      values = event.snapshot.value as Map<dynamic, dynamic>;
    });

    var degerler = "";
    var bosluk = " | ";
    var bosluk1 = " : ";
    values.forEach((key, value) {
      if (key == "SICAKLIK") {
        var isaret = "C";
        degerler +=
            key.toString() + bosluk1 + value.toString() + isaret + bosluk;
      }
      if (key == "CO2") {
        var isaret = "ppm";
        degerler +=
            key.toString() + bosluk1 + value.toString() + isaret + bosluk;
      }
      if (key == "NEM") {
        var isaret = " %";
        degerler += key.toString() + bosluk1 + isaret + value.toString();
      }
    });
    NotificationHelper.showNotification(
        id: 123, title: "ODA VERİLERİ", body: degerler.toString());

    Database db = await openDatabase(
      'SENSORDATA',
      version: 1,
    );
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat('HH:mm:ss').format(now);
    String sql =
        "CREATE TABLE IF NOT EXISTS sensordata(id INTEGER PRIMARY KEY,sicaklik INTEGER,co2 INTEGER,nem INTEGER,tarih TEXt,saat TEXT)";
    db.execute(sql);

    await db.insert(
        "sensordata",
        SensorData.set(values["SICAKLIK"], values["CO2"], values["NEM"],
                formattedDate, formattedTime)
            .toMap());
    db.query("sensordata").then((value) => value.forEach((element) {
          print(element);
        }));
    db.close();

    return Future.value(true);
  });
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final List<Map<dynamic, dynamic>> _dataList = [];
  final TextEditingController _sureController = TextEditingController();
  @override
  void initState() {
    super.initState();
    readData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Akılli Ev'),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                Workmanager().registerOneOffTask(
                    "birseferlikveriekle", "birseferlikveriekle");
              },
              icon: const Icon(Icons.get_app),
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: _dataList.length,
          itemBuilder: (BuildContext context, int index) {
            if (_dataList[index]['key'].toString() != 'SURE') {
              return ListTile(
                title: Column(
                  children: [
                    Text(_dataList[index]['key'].toString()),
                    const SizedBox(height: 20),
                    Semantics(
                        label: _dataList[index]['value'].toString(),
                        enabled: true,
                        readOnly: true,
                        child: ProgressBar(index,
                            _dataList[index]['key'].toString(), context)),
                  ],
                ),
              );
            } else {
              String text = "Güncelleme Süresi : " +
                  _dataList[index]['value'].toString() +
                  "sn";
              return ListTile(
                title: Column(
                  children: [
                    Text(text),
                    const SizedBox(height: 20),
                    Semantics(
                        label: _dataList[index]['value'].toString(),
                        enabled: true,
                        readOnly: true,
                        child: ProgressBar(index,
                            _dataList[index]['key'].toString(), context)),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget ProgressBar(int index, String key, BuildContext context) {
    if (key != 'SURE') {
      return GestureDetector(
        onTap: () {
          // ProgressBar'a dokunulduğunda yeni bir sayfaya git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChartPage(_dataList[index]['key']),
            ),
          );
        },
        child: SleekCircularSlider(
          max: (_dataList[index]['value'] + 0.0) > 100 ? 1000 : 100,
          min: 0,
          initialValue: _dataList[index]['value'] + 0.0,
          innerWidget: (double value) => Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [v(_dataList[index]['key'], _dataList[index]['value'])],
            ),
          ),
        ),
      );
    } else {
      //_sureController.text = _dataList[index]['value'].toString();
      return ElevatedButton(
        onPressed: () => _showDialog(context, _dataList[index]['key']),
        child: Text('GÜNCELLEME SÜRESİ DEĞİŞTİR'),
      );
    }
  }

  Widget v(String deger, int value) {
    if (deger == "CO2") {
      return Text('${value.roundToDouble()} ppm');
    }
    if (deger == "SICAKLIK") {
      return Text('${value.roundToDouble()} C');
    } else {
      return Text('% ${value.roundToDouble()}');
    }
  }

  void readData() {
    DatabaseReference starCountRef = FirebaseDatabase.instance.ref('proje');
    starCountRef.onValue.listen((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        setState(() {
          _dataList.clear();
          values.forEach((key, value) {
            _dataList.add({'key': key, 'value': value});
          });
        });
      }
    });
  }

  void _showDialog(BuildContext context, String key) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('GÜNCELLEME SÜRESİ BELİRLE (sn)'),
          content: TextFormField(
            controller: _sureController,
            keyboardType: TextInputType.number,
            //initialValue: _sureController.text,
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
                updateFirebaseValue(key, int.parse(_sureController.text));
              },
            ),
          ],
        );
      },
    );
  }

  void updateFirebaseValue(String key, int newValue) {
    DatabaseReference sureRef = FirebaseDatabase.instance.ref('proje/SURE');
    sureRef.set(newValue);
  }
}
