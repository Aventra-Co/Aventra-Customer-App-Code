class CountryModel {
  final int countryId;
  final String countryName;
  final String createTime;

  CountryModel({
    required this.countryId,
    required this.countryName,
    required this.createTime,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      countryId: json['country_id'],
      countryName: json['country_name'],
      createTime: json['createtime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country_id': countryId,
      'country_name': countryName,
      'createtime': createTime,
    };
  }
}
