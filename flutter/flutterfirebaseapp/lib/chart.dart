import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class ChartPage extends StatelessWidget {
  final String dataKey;
  dynamic datas;
  // Constructor ile dataKey parametresini alabilirsiniz
  ChartPage(this.dataKey) {
    datas = getDatas(dataKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dataKey),
      ),
      body: Center(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future:
              datas, // Burada datas değişkeni doğru bir şekilde tanımlanmalı
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Hata: ${snapshot.error}');
            } else {
              List<Map<String, dynamic>> dataList = snapshot.data!;
              var textGun = "Günlük Ortalama $dataKey : ";
              var textAy = "Aylık Ortalama $dataKey : ";
              var isaret = "C";
              if (dataKey == "SICAKLIK") {
                isaret = "C";
                return Center(
                  child: Column(children: [
                    Text(textGun +
                        gunlukOrtalama(dataList, "sicaklik").toString() +
                        isaret),
                    Text(textAy +
                        aylikOrtalama(dataList, "sicaklik").toString() +
                        isaret)
                  ]),
                );
              }
              if (dataKey == "CO2") {
                isaret = "ppm";
                return Center(
                  child: Column(children: [
                    Text(textGun +
                        gunlukOrtalama(dataList, "co2").toString() +
                        isaret),
                    Text(textAy +
                        aylikOrtalama(dataList, "co2").toString() +
                        isaret)
                  ]),
                );
              }
              if (dataKey == "NEM") {
                isaret = " %";
                return Center(
                    child: Column(
                  children: [
                    Text(textGun +
                        isaret +
                        gunlukOrtalama(dataList, "nem").toString()),
                    Text(textAy +
                        isaret +
                        aylikOrtalama(dataList, "nem").toString()),
                  ],
                ));
              } else {
                return Container();
              }
            }
          },
        ),
      ),
    );
  }

  double gunlukOrtalama(List<Map<String, dynamic>> datalist, String key) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    var gunverileri =
        datalist.where((element) => element["tarih"] == formattedDate);
    var veriler = 0;
    var count = 0;
    gunverileri.forEach((element) {
      veriler += element[key] as int;
      count++;
    });
    double ortalama = veriler / count;
    return double.parse(ortalama.toStringAsFixed(2));
  }

  double aylikOrtalama(List<Map<String, dynamic>> datalist, String key) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM').format(now);
    var gunverileri =
        datalist.where((element) => element['tarih'].startsWith(formattedDate));
    var veriler = 0;
    var count = 0;
    gunverileri.forEach((element) {
      veriler += element[key] as int;
      count++;
    });
    double ortalama = veriler / count;
    return double.parse(ortalama.toStringAsFixed(2));
  }

  Future<List<Map<String, dynamic>>> getDatas(String datakey) async {
    List<String> columns = ["tarih", "saat"];
    if (datakey == "SICAKLIK") {
      columns.add("sicaklik");
    } else if (datakey == "CO2") {
      columns.add("co2");
    } else {
      columns.add("nem");
    }
    Database db = await openDatabase(
      'SENSORDATA',
      version: 1,
    );
    List<Map<String, dynamic>> result =
        await db.query("sensordata", columns: columns);
    db.close();
    return result;
  }
}
