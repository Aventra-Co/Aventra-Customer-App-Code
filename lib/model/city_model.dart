class CityModel {
  final int cityId;
  final String cityName;

  CityModel({
    required this.cityId,
    required this.cityName,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      cityId: json['city_id'],
      cityName: json['city_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city_id': cityId,
      'city_name': cityName,
    };
  }
}
