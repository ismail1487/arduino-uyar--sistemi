class SensorData {
  int? id;
  int sicaklik;
  int co2;
  int nem;
  String tarih;
  String saat;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sicaklik': sicaklik,
      'co2': co2,
      'nem': nem,
      'tarih': tarih,
      'saat': saat,
    };
  }

  // Constructor
  SensorData.get(
      this.id, this.sicaklik, this.co2, this.nem, this.tarih, this.saat);
  SensorData.set(this.sicaklik, this.co2, this.nem, this.tarih, this.saat);
}
