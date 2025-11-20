import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_header.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import 'dart:ui' as ui;

class WeatherScreen extends StatefulWidget {
  static String routeName = './WeatherScreen';
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  double lat = 36.0;
  double long = -123.0;
  dynamic weatherData;
  bool isApiCalling = true;
  String city = "";

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  void fetchLocation() async {
    try {
      Position? position = await getCurrentLocation();
      if (position != null) {
        lat = position.latitude;
        long = position.longitude;
        // lat = 36.0;
        // long = -123.0;
        _getAddressFromLatLng(lat, long);
        print(
            "Latitudeadfa: ${position.latitude}, Longitude: ${position.longitude}, position: $position");

        weatherData = await getWeatherData(latitude: lat, longitude: long);
        setState(() {
          isApiCalling = false;
        });
        log("weatherData$weatherData");
        // fetchWeather(latitude: lat, longitude: long);
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  //!get current location
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    //! Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      //! Location services are not enabled
      SnackBarToastMessage.showSnackBar(
          context, 'Location services are disabled.');
      return Future.error('Location services are disabled.');
    }

    //! Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        //! Permissions are denied
        SnackBarToastMessage.showSnackBar(
            context, 'Location permissions are denied');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      //! Permissions are permanently denied
      SnackBarToastMessage.showSnackBar(
          context, 'Location permissions are permanently denied');
      return Future.error('Location permissions are permanently denied');
    }

    //! Get the current position city area
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _getAddressFromLatLng(lat, long) async {
    await placemarkFromCoordinates(lat, long)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      print(
          'Line 105  ${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}');

      setState(() {
        city = "${place.subAdministrativeArea}";
      });
    }).catchError((e) {
      print(
        "Line 95",
      );
      debugPrint(e);
    });
  }

  //!======Fetch Weather API==============
  Future<Map<String, dynamic>?> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    // Build the URI with all required parameters
    final uri = Uri.parse('$_baseUrl?'
        'latitude=$latitude&'
        'longitude=$longitude&'
        'hourly=temperature_2m,windspeed_10m,winddirection_10m,relativehumidity_2m&'
        'wind_speed_unit=kmh&'
        'timezone=auto&'
        'apikey=${AppConstant.weatherKey}');

    print("uri: $uri");

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print("weatherRes: ${response.body}");
        final data = json.decode(response.body);
        return data;
      } else {
        print('Failed to fetch weather: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  //!======Fetch Marine Weather API==============
  Future<Map<String, dynamic>?> fetchMarineWeather({
    required double latitude,
    required double longitude,
  }) async {
    // Build the URI with all required parameters
    final uri = Uri.parse('https://marine-api.open-meteo.com/v1/marine?'
        'latitude=$latitude&'
        'longitude=$longitude&'
        'hourly=wave_height,wave_direction,wave_period,sea_surface_temperature,sea_level_height_msl&'
        'timezone=auto');

    print("uri: $uri");

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print("weatherRes: ${response.body}");
        final data = json.decode(response.body);
        return data;
      } else {
        print('Failed to fetch weather: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<Map<String, Map<String, dynamic>>?> getWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Fetch both weather and marine data concurrently
      final results = await Future.wait([
        fetchWeather(latitude: latitude, longitude: longitude),
        fetchMarineWeather(latitude: latitude, longitude: longitude),
      ]);

      final weatherData = results[0];
      final marineData = results[1];

      if (weatherData == null || marineData == null) {
        print('Failed to fetch one or both weather data sources');
        return null;
      }

      // Get current time and calculate target hours
      final now = DateTime.now();
      final currentHour = now.hour;

      // Calculate dates for today, tomorrow, and day after tomorrow
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final dayAfterTomorrow = today.add(const Duration(days: 2));

      // Extract hourly data arrays from responses
      final weatherHourly = weatherData['hourly'] as Map<String, dynamic>?;
      final marineHourly = marineData['hourly'] as Map<String, dynamic>?;

      if (weatherHourly == null || marineHourly == null) {
        print('Missing hourly data in API responses');
        return null;
      }

      // Get the time array to find matching hours
      final timeArray = weatherHourly['time'] as List<dynamic>?;
      if (timeArray == null) {
        print('Missing time array in weather data');
        return null;
      }

      // Find indices for current hour of each day
      int? todayIndex;
      int? tomorrowIndex;
      int? dayAfterTomorrowIndex;

      for (int i = 0; i < timeArray.length; i++) {
        final timeString = timeArray[i] as String;
        final dateTime = DateTime.parse(timeString);

        // Check if this is the current hour of today
        if (dateTime.year == today.year &&
            dateTime.month == today.month &&
            dateTime.day == today.day &&
            dateTime.hour == currentHour) {
          todayIndex = i;
        }

        // Check if this is the current hour of tomorrow
        if (dateTime.year == tomorrow.year &&
            dateTime.month == tomorrow.month &&
            dateTime.day == tomorrow.day &&
            dateTime.hour == currentHour) {
          tomorrowIndex = i;
        }

        // Check if this is the current hour of day after tomorrow
        if (dateTime.year == dayAfterTomorrow.year &&
            dateTime.month == dayAfterTomorrow.month &&
            dateTime.day == dayAfterTomorrow.day &&
            dateTime.hour == currentHour) {
          dayAfterTomorrowIndex = i;
        }
      }

      // Helper function to extract data for a specific index
      Map<String, dynamic> extractDataForIndex(int index) {
        final date = DateTime.parse(timeArray[index] as String);
        final formattedDate =
            '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

        return {
          'date': formattedDate,
          'temperature':
              (weatherHourly['temperature_2m'] as List<dynamic>?)?[index] ??
                  0.0,
          'wind_direction_degree':
              (weatherHourly['winddirection_10m'] as List<dynamic>?)?[index] ??
                  0.0,
          'humidity': (weatherHourly['relativehumidity_2m']
                  as List<dynamic>?)?[index] ??
              0.0,
          'wind_speed':
              (weatherHourly['windspeed_10m'] as List<dynamic>?)?[index] ?? 0.0,
          'wave_height':
              (marineHourly['wave_height'] as List<dynamic>?)?[index] ?? 0.0,
          'tide': (marineHourly['sea_level_height_msl']
                  as List<dynamic>?)?[index] ??
              0.0,
        };
      }

      // Build the result map
      Map<String, Map<String, dynamic>> result = {};

      if (todayIndex != null) {
        result['today'] = extractDataForIndex(todayIndex);
      }

      if (tomorrowIndex != null) {
        result['tomorrow'] = extractDataForIndex(tomorrowIndex);
      }

      if (dayAfterTomorrowIndex != null) {
        result['dayAfterTomorrow'] = extractDataForIndex(dayAfterTomorrowIndex);
      }

      return result;
    } catch (e) {
      print('Error in getWeatherData: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isApiCalling,
        opacity: 0.5,
        child: _buildUIScreen(context));
  }

  Widget _buildUIScreen(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: AppColor.secondaryColor,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppColor.secondaryColor,
          body: SafeArea(
            child: Directionality(
              textDirection:
                  language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              child: Container(
                height: screenHeight * 100 / 100,
                width: screenWidth * 100 / 100,
                color: AppColor.secondaryColor,
                child: Column(children: [
                  AppHeader(
                      text: AppLanguage.weatherReportText[language],
                      onPress: () {
                        Navigator.pop(context);
                      }),
                  SizedBox(
                    height: screenHeight * 2 / 100,
                  ),
                  if (!isApiCalling)
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(
                              width: screenWidth * 90 / 100,
                              child: Row(
                                children: [
                                  Container(
                                    width: screenWidth * 30 / 100,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 1),
                                        left: BorderSide(width: 1),
                                        right: BorderSide(width: 1),
                                        bottom: BorderSide(width: 1),
                                      ),
                                      color: AppColor.secondaryColor,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          alignment: language == 0
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          width: screenWidth * 30 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              AppLanguage.dateText[language],
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          alignment: language == 0
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          width: screenWidth * 30 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              AppLanguage
                                                  .locationText[language],
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          alignment: language == 0
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          width: screenWidth * 30 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              AppLanguage
                                                  .windSpeedText[language],
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          alignment: language == 0
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          width: screenWidth * 30 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              AppLanguage
                                                  .windDirectionText[language],
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          alignment: language == 0
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          width: screenWidth * 30 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              AppLanguage
                                                  .waveHeightText[language],
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          alignment: language == 0
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          width: screenWidth * 30 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              "${AppLanguage.temperatureText[language]} (\u1d52C)",
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          alignment: language == 0
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          width: screenWidth * 30 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              "${AppLanguage.humidityText[language]} (%)",
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          alignment: language == 0
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          width: screenWidth * 30 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            color: AppColor.secondaryColor,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              AppLanguage
                                                  .tideHeightText[language],
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  //!=====Day 1====
                                  Container(
                                    width: screenWidth * 20 / 100,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 1),
                                        right: BorderSide(width: 1),
                                        bottom: BorderSide(width: 1),
                                      ),
                                      color: AppColor.secondaryColor,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5.0),
                                            child: Text(
                                              weatherData['today']['date'] ??
                                                  "",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            city,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['today']['wind_speed'] ?? ""}",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['today']['wind_direction_degree'] ?? ""}\u1d52",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['today']['wave_height'] ?? ""}",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['today']['temperature'] ?? ""}\u1d52C",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['today']['humidity'] ?? ""}",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['today']['tide'] ?? ""}m",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  //!=====Day 2====
                                  Container(
                                    width: screenWidth * 20 / 100,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 1),
                                        right: BorderSide(width: 1),
                                        bottom: BorderSide(width: 1),
                                      ),
                                      color: AppColor.secondaryColor,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5.0),
                                            child: Text(
                                              weatherData['tomorrow']['date'] ??
                                                  "",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            city,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['tomorrow']['wind_speed'] ?? ""}",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['tomorrow']['wind_direction_degree'] ?? ""}\u1d52",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['tomorrow']['wave_height'] ?? ""}",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['tomorrow']['temperature'] ?? ""}\u1d52C",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['tomorrow']['humidity'] ?? ""}",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['tomorrow']['tide'] ?? ""}m",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  //!=====Day 3====
                                  Container(
                                    width: screenWidth * 20 / 100,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 1),
                                        right: BorderSide(width: 1),
                                        bottom: BorderSide(width: 1),
                                      ),
                                      color: AppColor.secondaryColor,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5.0),
                                            child: Text(
                                              weatherData['dayAfterTomorrow']
                                                      ['date'] ??
                                                  "",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            city,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['dayAfterTomorrow']['wind_speed'] ?? ""}",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['dayAfterTomorrow']['wind_direction_degree'] ?? ""}\u1d52",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['dayAfterTomorrow']['wave_height'] ?? ""}",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['dayAfterTomorrow']['temperature'] ?? ""}\u1d52C",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(width: 1),
                                            ),
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['dayAfterTomorrow']['humidity'] ?? ""}",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        Container(
                                          width: screenWidth * 20 / 100,
                                          height: screenHeight * 9 / 100,
                                          decoration: const BoxDecoration(
                                            color: AppColor.secondaryColor,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${weatherData['dayAfterTomorrow']['tide'] ?? ""}m",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ));
  }
}

//!================PREVIOUS CODE FOR WEATHER DATA WITHOUT TIDE================
  // Future<Map<String, Map<String, dynamic>>?> getWeatherData({
  //   required double latitude,
  //   required double longitude,
  // }) async {
  //   try {
  //     // Fetch both weather and marine data concurrently
  //     final results = await Future.wait([
  //       fetchWeather(latitude: latitude, longitude: longitude),
  //       fetchMarineWeather(latitude: latitude, longitude: longitude),
  //     ]);
  //     final weatherData = results[0];
  //     final marineData = results[1];
  //     if (weatherData == null || marineData == null) {
  //       print('Failed to fetch one or both weather data sources');
  //       return null;
  //     }
  //     // Get current time and calculate target hours
  //     final now = DateTime.now();
  //     final currentHour = now.hour;
  //     // Calculate dates for today, tomorrow, and day after tomorrow
  //     final today = DateTime(now.year, now.month, now.day);
  //     final tomorrow = today.add(const Duration(days: 1));
  //     final dayAfterTomorrow = today.add(const Duration(days: 2));
  //     // Extract hourly data arrays from responses
  //     final weatherHourly = weatherData['hourly'] as Map<String, dynamic>?;
  //     final marineHourly = marineData['hourly'] as Map<String, dynamic>?;
  //     if (weatherHourly == null || marineHourly == null) {
  //       print('Missing hourly data in API responses');
  //       return null;
  //     
  //     // Get the time array to find matching hours
  //     final timeArray = weatherHourly['time'] as List<dynamic>?;
  //     if (timeArray == null) {
  //       print('Missing time array in weather data');
  //       return null;
  //     }
  //     // Find indices for current hour of each day
  //     int? todayIndex;
  //     int? tomorrowIndex;
  //     int? dayAfterTomorrowIndex;
  //     for (int i = 0; i < timeArray.length; i++) {
  //       final timeString = timeArray[i] as String;
  //       final dateTime = DateTime.parse(timeString);
  //       // Check if this is the current hour of today
  //       if (dateTime.year == today.year &&
  //           dateTime.month == today.month &&
  //           dateTime.day == today.day &&
  //           dateTime.hour == currentHour) {
  //         todayIndex = i;
  //       }
  //       // Check if this is the current hour of tomorrow
  //       if (dateTime.year == tomorrow.year &&
  //           dateTime.month == tomorrow.month &&
  //           dateTime.day == tomorrow.day &&
  //           dateTime.hour == currentHour) {
  //         tomorrowIndex = i;
  //       }
  //       // Check if this is the current hour of day after tomorrow
  //       if (dateTime.year == dayAfterTomorrow.year &&
  //           dateTime.month == dayAfterTomorrow.month &&
  //           dateTime.day == dayAfterTomorrow.day &&
  //           dateTime.hour == currentHour) {
  //         dayAfterTomorrowIndex = i;
  //       }
  //     }
  //     // Helper function to extract data for a specific index
  //     Map<String, dynamic> extractDataForIndex(int index) {
  //       final date = DateTime.parse(timeArray[index] as String);
  //       final formattedDate =
  //           '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  //       return {
  //         'date': formattedDate,
  //         'temperature':
  //             (weatherHourly['temperature_2m'] as List<dynamic>?)?[index] ??
  //                 0.0,
  //         'wind_direction_degree':
  //             (weatherHourly['winddirection_10m'] as List<dynamic>?)?[index] ??
  //                 0.0,
  //         'humidity': (weatherHourly['relativehumidity_2m']
  //                 as List<dynamic>?)?[index] ??
  //             0.0,
  //         'wind_speed':
  //             (weatherHourly['windspeed_10m'] as List<dynamic>?)?[index] ?? 0.0,
  //         'wave_height':
  //             (marineHourly['wave_height'] as List<dynamic>?)?[index] ?? 0.0,
  //       };
  //     }
  //     // Build the result map
  //     Map<String, Map<String, dynamic>> result = {};
  //     if (todayIndex != null) {
  //       result['today'] = extractDataForIndex(todayIndex);
  //     }
  //     if (tomorrowIndex != null) {
  //       result['tomorrow'] = extractDataForIndex(tomorrowIndex);
  //     }
  //     if (dayAfterTomorrowIndex != null) {
  //       result['dayAfterTomorrow'] = extractDataForIndex(dayAfterTomorrowIndex);
  //     }
  //     return result;
  //   } catch (e) {
  //     print('Error in getWeatherData: $e');
  //     return null;
  //   }
  // }
