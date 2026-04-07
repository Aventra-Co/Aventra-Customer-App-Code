import 'package:boatapp/controller/app_image.dart';
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
  bool _isFetchingLocation = false;
  String? _errorMessage; // <-- ADD: to show error to user

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  void fetchLocation() async {
    if (_isFetchingLocation) return;
    _isFetchingLocation = true;

    try {
      Position? position = await getCurrentLocation();
      if (position != null) {
        lat = position.latitude;
        long = position.longitude;

        // Run address lookup and weather fetch concurrently
        await Future.wait([
          _getAddressFromLatLng(lat, long),
          _fetchAndSetWeather(lat, long),
        ]);
      } else {
        // Permission denied or service disabled — stop loader
        if (mounted) {
          setState(() {
            isApiCalling = false;
            _errorMessage =
                'Unable to get location. Please enable location services.';
          });
        }
      }
    } catch (e) {
      debugPrint("fetchLocation Error: $e");
      if (mounted) {
        setState(() {
          isApiCalling = false;
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    } finally {
      _isFetchingLocation = false;
    }
  }

  Future<void> _fetchAndSetWeather(double latitude, double longitude) async {
    final data = await getWeatherData(latitude: latitude, longitude: longitude);
    if (mounted) {
      setState(() {
        weatherData = data;
        isApiCalling = false;
        if (data == null) {
          _errorMessage = 'Weather data unavailable for this location.';
        }
      });
    }
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        SnackBarToastMessage.showSnackBar(context,
            'Location services are disabled. Please enable in Settings.');
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // On iOS, once denied forever you MUST open Settings
      if (mounted) {
        _showOpenSettingsDialog();
      }
      return null;
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        SnackBarToastMessage.showSnackBar(
            context, 'Location permission denied.');
      }
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15), // prevents hanging forever
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location access was denied. Please go to Settings > Aventra > Location and allow access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings(); // opens iOS Settings directly
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _getAddressFromLatLng(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        if (mounted) {
          setState(() {
            city = place.subAdministrativeArea ?? place.locality ?? "";
          });
        }
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$_baseUrl?'
        'latitude=$latitude&'
        'longitude=$longitude&'
        'hourly=temperature_2m,windspeed_10m,winddirection_10m,relativehumidity_2m&'
        'wind_speed_unit=kmh&'
        'timezone=auto&'
        'apikey=${AppConstant.weatherKey}');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint(
            'Weather API failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('fetchWeather error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchMarineWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('https://marine-api.open-meteo.com/v1/marine?'
        'latitude=$latitude&'
        'longitude=$longitude&'
        'hourly=wave_height,wave_direction,wave_period,sea_surface_temperature,sea_level_height_msl&'
        'timezone=auto');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // *** KEY FIX: Log but don't fail — marine API fails for inland locations ***
        debugPrint(
            'Marine API failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('fetchMarineWeather error: $e');
      return null;
    }
  }

  Future<Map<String, Map<String, dynamic>>?> getWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Fetch both concurrently; marine may be null for inland locations
      final results = await Future.wait([
        fetchWeather(latitude: latitude, longitude: longitude),
        fetchMarineWeather(latitude: latitude, longitude: longitude),
      ]);

      final weatherApiData = results[0];
      final marineData = results[1]; // MAY BE NULL — handle gracefully

      // *** KEY FIX: Only fail if weather data is missing; marine is optional ***
      if (weatherApiData == null) {
        debugPrint('Failed to fetch weather data');
        return null;
      }

      final now = DateTime.now();
      final currentHour = now.hour;
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final dayAfterTomorrow = today.add(const Duration(days: 2));

      final weatherHourly = weatherApiData['hourly'] as Map<String, dynamic>?;
      final marineHourly =
          marineData?['hourly'] as Map<String, dynamic>?; // nullable

      if (weatherHourly == null) {
        debugPrint('Missing hourly data in weather response');
        return null;
      }

      final timeArray = weatherHourly['time'] as List<dynamic>?;
      if (timeArray == null) {
        debugPrint('Missing time array in weather data');
        return null;
      }

      int? todayIndex;
      int? tomorrowIndex;
      int? dayAfterTomorrowIndex;

      for (int i = 0; i < timeArray.length; i++) {
        final dateTime = DateTime.parse(timeArray[i] as String);

        if (dateTime.year == today.year &&
            dateTime.month == today.month &&
            dateTime.day == today.day &&
            dateTime.hour == currentHour) {
          todayIndex = i;
        }
        if (dateTime.year == tomorrow.year &&
            dateTime.month == tomorrow.month &&
            dateTime.day == tomorrow.day &&
            dateTime.hour == currentHour) {
          tomorrowIndex = i;
        }
        if (dateTime.year == dayAfterTomorrow.year &&
            dateTime.month == dayAfterTomorrow.month &&
            dateTime.day == dayAfterTomorrow.day &&
            dateTime.hour == currentHour) {
          dayAfterTomorrowIndex = i;
        }
      }

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
          // *** KEY FIX: Use null-safe access for marine data ***
          'wave_height':
              (marineHourly?['wave_height'] as List<dynamic>?)?[index] ?? 'N/A',
          'tide': (marineHourly?['sea_level_height_msl']
                  as List<dynamic>?)?[index] ??
              'N/A',
        };
      }

      Map<String, Map<String, dynamic>> result = {};
      if (todayIndex != null) result['today'] = extractDataForIndex(todayIndex);
      if (tomorrowIndex != null)
        result['tomorrow'] = extractDataForIndex(tomorrowIndex);
      if (dayAfterTomorrowIndex != null) {
        result['dayAfterTomorrow'] = extractDataForIndex(dayAfterTomorrowIndex);
      }

      return result;
    } catch (e) {
      debugPrint('Error in getWeatherData: $e');
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
                height: screenHeight,
                width: screenWidth,
                color: AppColor.secondaryColor,
                child: Column(children: [
                  AppHeader(
                      text: "",
                      onPress: () {
                        Navigator.pop(context);
                      }),
                  // SizedBox(height: screenHeight * 2 / 100),

                  // *** ADD: Error state ***
                  if (!isApiCalling && _errorMessage != null)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off,
                                  size: 60, color: AppColor.primaryColor),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: AppFont.fontFamily,
                                  fontSize: 14,
                                  color: AppColor.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isApiCalling = true;
                                    _errorMessage = null;
                                  });
                                  fetchLocation();
                                },
                                child: const Text('Retry'),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (!isApiCalling &&
                      _errorMessage == null &&
                      weatherData != null)
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Sea Report Header
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 5 / 100,
                                  vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          15 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              15 /
                                              100,
                                      child:
                                          Image.asset(AppImage.seaReportImage)),
                                  // const SizedBox(width: 5),
                                  Text(
                                    AppLanguage.seaReportText[language],
                                    style: const TextStyle(
                                        fontFamily: AppFont.fontFamily,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.primaryColor),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: screenWidth * 90 / 100,
                              child: Row(
                                children: [
                                  // Labels column
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
                                        _labelCell(
                                          screenWidth,
                                          screenHeight,
                                          AppLanguage.dateText[language],
                                          "",
                                        ),
                                        _labelCell(
                                          screenWidth,
                                          screenHeight,
                                          AppLanguage.locationText[language],
                                          AppImage.locationImage,
                                        ),
                                        _labelCell(
                                          screenWidth,
                                          screenHeight,
                                          AppLanguage.windSpeedText[language],
                                          AppImage.waveImage,
                                        ),
                                        _labelCell(
                                          screenWidth,
                                          screenHeight,
                                          AppLanguage
                                              .windDirectionText[language],
                                          AppImage.windDirectionImage,
                                        ),
                                        _labelCell(
                                          screenWidth,
                                          screenHeight,
                                          AppLanguage.waveHeightText[language],
                                          AppImage.waveHeightImage,
                                        ),
                                        _labelCell(
                                          screenWidth,
                                          screenHeight,
                                          "${AppLanguage.temperatureText[language]} (\u1d52C)",
                                          AppImage.temperatureImage,
                                        ),
                                        _labelCell(
                                          screenWidth,
                                          screenHeight,
                                          "${AppLanguage.humidityText[language]} (%)",
                                          AppImage.humidityImage,
                                        ),
                                        _labelCell(
                                          screenWidth,
                                          screenHeight,
                                          AppLanguage.tideHeightText[language],
                                          AppImage.tideImage,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Today
                                  _dayColumn(screenWidth, screenHeight,
                                      weatherData['today']),
                                  // Tomorrow
                                  _dayColumn(screenWidth, screenHeight,
                                      weatherData['tomorrow']),
                                  // Day After Tomorrow
                                  _dayColumn(screenWidth, screenHeight,
                                      weatherData['dayAfterTomorrow']),
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

  Widget _labelCell(
      double screenWidth, double screenHeight, String text, String image,
      {bool isLast = false}) {
    return Container(
      alignment: language == 0 ? Alignment.centerLeft : Alignment.centerRight,
      width: screenWidth * 40 / 100,
      height: screenHeight * 9 / 100,
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(width: 1)),
        color: AppColor.secondaryColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          mainAxisAlignment:
              language == 0 ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: language == 0
              ? [
                  if (image.isNotEmpty) ...[
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 10 / 100,
                        height: MediaQuery.of(context).size.width * 10 / 100,
                        child: Image.asset(image)),
                    // const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: const TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColor.primaryColor),
                    ),
                  ),
                ]
              : [
                  Flexible(
                    child: Text(
                      text,
                      style: const TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColor.primaryColor),
                    ),
                  ),
                  // if (icon != null) ...[
                  //   const SizedBox(width: 6),
                  //   Icon(icon, size: 16, color: AppColor.primaryColor),
                  // ],
                ],
        ),
      ),
    );
  }

  Widget _dayColumn(
      double screenWidth, double screenHeight, Map<String, dynamic>? dayData) {
    if (dayData == null) {
      return Container(
        width: screenWidth * 20 / 100,
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(width: 1),
              right: BorderSide(width: 1),
              bottom: BorderSide(width: 1)),
          color: AppColor.secondaryColor,
        ),
        child: const Center(child: Text('N/A')),
      );
    }

    return Container(
      width: screenWidth * 20 / 100,
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(width: 1),
            right: BorderSide(width: 1),
            bottom: BorderSide(width: 1)),
        color: AppColor.secondaryColor,
      ),
      child: Column(
        children: [
          _dataCell(screenWidth, screenHeight, dayData['date'] ?? "",
              isPadded: true),
          _dataCell(screenWidth, screenHeight, city),
          _dataCell(
              screenWidth, screenHeight, "${dayData['wind_speed'] ?? ''}"),
          _dataCell(screenWidth, screenHeight,
              "${dayData['wind_direction_degree'] ?? ''}\u1d52"),
          _dataCell(
              screenWidth, screenHeight, "${dayData['wave_height'] ?? 'N/A'}"),
          _dataCell(screenWidth, screenHeight,
              "${dayData['temperature'] ?? ''}\u1d52C"),
          _dataCell(screenWidth, screenHeight, "${dayData['humidity'] ?? ''}"),
          _dataCell(screenWidth, screenHeight,
              dayData['tide'] == 'N/A' ? 'N/A' : "${dayData['tide']}m",
              isLast: true),
        ],
      ),
    );
  }

  Widget _dataCell(double screenWidth, double screenHeight, String text,
      {bool isLast = false, bool isPadded = false}) {
    return Container(
      width: screenWidth * 20 / 100,
      height: screenHeight * 9 / 100,
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(width: 1)),
        color: AppColor.secondaryColor,
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isPadded ? 5.0 : 0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: AppFont.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColor.primaryColor),
        ),
      ),
    );
  }
}
