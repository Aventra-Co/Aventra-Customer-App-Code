import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_shimmers.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';
import '../authentication/notification_screen.dart';
import '../other_screen/privateBookingFlow/private_trip_details.dart';
import '../other_screen/publicBookingFlow/public_trip_details.dart';
import '../other_screen/beaches.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import '../other_screen/weather_screen.dart';

class Explore extends StatefulWidget {
  static String routeName = './Explore';
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  final CarouselController carouselController = CarouselController();
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  int status = 0;
  bool hasInitialized = false;
  bool isApiCalling = false;
  bool isLoading = true;
  List<dynamic> promotionsList = <dynamic>[];
  List popularDestinationList = <dynamic>[];
  List hasTripDestinationsList = <dynamic>[];
  List filteredDestinationsList = <dynamic>[];
  List filteredActivityList = <dynamic>[];
  List bottomSheetPopularDestinationList = <dynamic>[];
  List searchPopularDestinationList = <dynamic>[];
  List categoryList = <dynamic>[];
  int selectActivity = 0;
  int destinationId = 0;
  bool isSearch = false;
  List activitiesList = <dynamic>[];
  List filterList = [
    {
      "id": 1,
      "title": "Parasailing",
      "image": "./assets/icons/parasailing.png"
    },
    {
      "id": 2,
      "title": "Snorkelling",
      "image": "./assets/icons/snorkelling.png"
    },
    {"id": 3, "title": "Yachts", "image": "./assets/icons/ship.png"},
    {"id": 4, "title": "Boats", "image": "./assets/icons/image_ship.png"},
    {
      "id": 5,
      "title": "Diving",
      "image": "./assets/icons/diving.png",
    },
    {"id": 6, "title": "Surfing", "image": "./assets/icons/surfing.png"}
  ];
  String profileImage = '';
  int userId = 0;
  dynamic userDetails;
  double lat = 22.7196;
  double long = 75.8577;
  var weatherData;
  dynamic cityData = {};
  int notificationCount = 0;
  dynamic temperatureData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        hasInitialized = true;
      });
    });
    getUserDetails();
  }

  //!--------------GET USER DETAILS---------------//!
  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");
    setState(() {
      isApiCalling = true;
    });

    //! print("userDetails $userDetails");
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      print("up $data");
      userId = data['user_id'];
      profileImage = data["image"] ?? "NA";
    }
    setState(() {
      isApiCalling = false;
    });
    homeApi(userId);
    fetchLocation();
    // fetchWeather();
    setState(() {});
  }

  //!=============GET Home DETAILS=====================//!
  Future<void> homeApi(userId) async {
    Uri url =
        Uri.parse("${AppConfigProvider.apiUrl}home_page_api?user_id=$userId");
    print("url $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', //! Use 'Bearer' if required
    };

    print("headers $headers");

    try {
      final response = await http.get(url, headers: headers);
      print("response $response");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          var item = res['activity_arr'];
          activitiesList = (item != "NA") ? item : [];
          print("activity$activitiesList");
          item = res['banner_arr'];
          promotionsList = (item != "NA") ? item : [];
          print("promotionsList$promotionsList");

          item = res['destination_arr'];
          popularDestinationList = (item != "NA") ? item : [];
          bottomSheetPopularDestinationList = (item != "NA") ? item : [];
          searchPopularDestinationList = (item != "NA") ? item : [];
          print("popularDestinationList$popularDestinationList");

          var hasTripDestinationData = res['destination_arr_active'];
          hasTripDestinationsList =
              (hasTripDestinationData != "NA") ? hasTripDestinationData : [];

          item = res['boat_arr'];
          categoryList = (item != "NA") ? item : [];
          print("categoryList$categoryList");
          notificationCount = res['notificationCount'];

          setState(() {
            isLoading = false;
          });
        } else {
          if (res['active_status'] == 0) {
            localstorageclearbutton();
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          }
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print("Error: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Exception: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  //-----------------Sign Out-----------------------
  localstorageclearbutton() async {
    final prefs = await SharedPreferences.getInstance();
    print("prefs =================>$prefs");
    prefs.remove('userDetails');
    prefs.remove('password');

    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
    );
  }

  //!------------OPEN RATE URL-------------------//!
  Future openUrl({
    required String url,
    bool inApp = false,
  }) async {
    print(url);
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      //! If not, prepend https://! to the URL
      url = 'https://$url';
    }

    if (await canLaunch(url)) {
      await launch(url,
          forceSafariVC: inApp, forceWebView: inApp, enableJavaScript: true);
    }
  }

  //!===========GET Destinations Acc to Activity DETAILS==========//!
  Future<void> getDestinationAccordingActivity(
      userId, context, screenWidth) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_destination?user_id=$userId&activity_id=$selectActivity");
    print("url $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', //! Use 'Bearer' if required
    };

    setState(() {
      isApiCalling = true;
    });

    print("headers $headers");

    try {
      final response = await http.get(url, headers: headers);
      print("response $response");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          var item = res['destination_arr'];
          filteredDestinationsList = (item != "NA") ? item : [];
          viewFilteredDestinationBottomSheet(
              context, screenWidth, selectActivity, () {
            setState(() {
              selectActivity = 0;
            });
          });
          print("activity$activitiesList");

          setState(() {
            isApiCalling = false;
          });
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
          setState(() {
            isApiCalling = false;
          });
        }
      } else {
        print("Error: ${response.statusCode}");
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      print("Exception: $e");
      setState(() {
        isApiCalling = false;
      });
    }
  }

  //!===========GET Activities Acc to Destination DETAILS==========//!
  Future<void> getActivityAccordingDestination(
      context, screenWidth, selectedDestination) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_activity_by_destinations?user_id=$userId&destination_id=$selectedDestination");
    print("url $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', //! Use 'Bearer' if required
    };

    setState(() {
      isApiCalling = true;
    });

    print("headers $headers");

    try {
      final response = await http.get(url, headers: headers);
      print("response $response");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          var item = res['activity_arr'];
          filteredActivityList = (item != "NA") ? item : [];

          viewFilteredActivitiesBottomSheet(
              context, screenWidth, selectedDestination, () {});
          print("activity$activitiesList");

          setState(() {
            isApiCalling = false;
          });
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
          setState(() {
            isApiCalling = false;
          });
        }
      } else {
        print("Error: ${response.statusCode}");
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      print("Exception: $e");
      setState(() {
        isApiCalling = false;
      });
    }
  }

  var refreshKey = GlobalKey<RefreshIndicatorState>();

  //!------------REFRESH FUNCION---------------//!
  Future<Null> _refreshPage() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(const Duration(seconds: 1));
    //! getTopStories(0);
    selectActivity = 0;
    getUserDetails();
    return null;
  }

  //!-----------SEARCH FUNCTION Trips-----------//!/
  searchResultCountry(String query) {
    print(query);

    var results1 = searchPopularDestinationList
        .where((value) => value['destination_english'][language]
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    print("results1 $results1");

    bottomSheetPopularDestinationList = [];

    bottomSheetPopularDestinationList = results1;

    setState(() {});
  }

  void fetchLocation() async {
    try {
      Position? position = await getCurrentLocation();
      if (position != null) {
        lat = position.latitude;
        long = position.longitude;
        print(
            "Latitude: ${position.latitude}, Longitude: ${position.longitude}");
        fetchWeather(latitude: lat, longitude: long);
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  //!!get current location
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

    //! Get the current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  //!!fetch weather data
  // Future<void> fetchWeather() async {
  //   //! setState(() {
  //   //!   isApiCalling = true;
  //   //! });
  //   final url =
  //       'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$long&units=imperial&appid=${AppConstant.weatherApiKey}';
  //   final response = await http.get(Uri.parse(url));
  //   if (response.statusCode == 200) {
  //     setState(() {
  //       weatherData = json.decode(response.body);

  //       cityData = weatherData?['list'][0];
  //       //! cityName = 'Oxford, Mississippi';
  //       //! cityName = weatherData?['city']['name'];
  //       //! pop = (cityData["pop"]);
  //       String fahrenheitStr = cityData['main']['temp'].toString();
  //       temperature = convertFahrenheitToCelsius(fahrenheitStr);
  //       weatherDesc = cityData['weather'][0]['description'].toString();
  //       isApiCalling = false;
  //       setState(() {});
  //       print('weatherData$weatherData');
  //       //! print('City Name $cityName');
  //       print('City data $cityData');
  //     });
  //   }
  // }

  // String convertFahrenheitToCelsius(String fahrenheitStr) {
  //   try {
  //     double fahrenheit = double.parse(fahrenheitStr);
  //     double celsius = (fahrenheit - 32) * 5 / 9;
  //     return celsius.toStringAsFixed(0); //! Returns Celsius as a string
  //   } catch (e) {
  //     return "Invalid input"; //! You can customize this error message
  //   }
  // }

  //!======Fetch Weather API==============
  Future<Map<String, dynamic>?> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    // Build the URI with all required parameters
    final uri = Uri.parse('$_baseUrl?'
        'latitude=$latitude&'
        'longitude=$longitude&'
        'hourly=temperature_2m,windspeed_10m,winddirection_10m,relativehumidity_2m,weathercode,precipitation,cloudcover&'
        'wind_speed_unit=kmh&'
        'timezone=auto&'
        'apikey=${AppConstant.weatherKey}');

    print("uri: $uri");

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print("weatherRes: ${response.body}");
        final data = json.decode(response.body);
        temperatureData = getCurrentWeatherData(data);
        AppConstant.temperature =
            temperatureData["temperature"].toStringAsFixed(0);
        AppConstant.unit = temperatureData["temperatureUnit"].toString();
        AppConstant.weatherDesc =
            temperatureData["weatherDescription"].toString();
        AppConstant.weatherIcon = temperatureData["weatherIcon"].toString();
        setState(() {});
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

  //! Function to get weather description from WMO weather codes
  String getWeatherDescription(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return AppLanguage.clearSkyText[language];
      case 1:
        return AppLanguage.mainlyClearText[language];
      case 2:
        return AppLanguage.partlyCloudyText[language];
      case 3:
        return AppLanguage.overcastText[language];
      case 45:
        return AppLanguage.fogText[language];
      case 48:
        return AppLanguage.depositingRimeFogText[language];
      case 51:
        return AppLanguage.lightDrizzleText[language];
      case 53:
        return AppLanguage.moderateDrizzleText[language];
      case 55:
        return AppLanguage.denseDrizzleText[language];
      case 56:
        return AppLanguage.lightFreezingDrizzleText[language];
      case 57:
        return AppLanguage.denseFreezingDrizzleText[language];
      case 61:
        return AppLanguage.slightRainText[language];
      case 63:
        return AppLanguage.moderateRainText[language];
      case 65:
        return AppLanguage.heavyRainText[language];
      case 66:
        return AppLanguage.lightFreezingRainText[language];
      case 67:
        return AppLanguage.heavyFreezingRainText[language];
      case 71:
        return AppLanguage.slightSnowFallText[language];
      case 73:
        return AppLanguage.moderateSnowFallText[language];
      case 75:
        return AppLanguage.heavySnowFallText[language];
      case 77:
        return AppLanguage.snowGrainsText[language];
      case 80:
        return AppLanguage.slightRainShowersText[language];
      case 81:
        return AppLanguage.moderateRainShowersText[language];
      case 82:
        return AppLanguage.violentRainShowersText[language];
      case 85:
        return AppLanguage.slightSnowShowersText[language];
      case 86:
        return AppLanguage.heavySnowShowersText[language];
      case 95:
        return AppLanguage.thunderstormText[language];
      case 96:
        return AppLanguage.thunderstormSlightHailText[language];
      case 99:
        return AppLanguage.thunderstormHeavyHailText[language];
      default:
        return AppLanguage.unknownWeatherText[language];
    }
  }

  //! Function to get weather icon based on weather code
  String getWeatherIcon(int weatherCode) {
    switch (weatherCode) {
      case 0:
      case 1:
        return '☀️'; // Clear/Sunny
      case 2:
      case 3:
        return '⛅'; // Cloudy
      case 45:
      case 48:
        return '🌫️'; // Fog
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return '🌧️'; // Rain
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return '❄️'; // Snow
      case 95:
      case 96:
      case 99:
        return '⛈️'; // Thunderstorm
      default:
        return '🌤️'; // Default
    }
  }

  Map<String, dynamic>? getCurrentWeatherData(
      Map<String, dynamic> weatherData) {
    try {
      // Get current date and hour
      final now = DateTime.now();
      final currentHour = now.hour;
      final today = DateTime(now.year, now.month, now.day);

      // Extract hourly data from the API response
      final hourlyData = weatherData['hourly'] as Map<String, dynamic>?;
      if (hourlyData == null) {
        print('No hourly data found in weather response');
        return null;
      }

      // Get arrays from API response
      final timeArray = hourlyData['time'] as List<dynamic>?;
      final temperatureArray = hourlyData['temperature_2m'] as List<dynamic>?;
      final weatherCodeArray = hourlyData['weathercode'] as List<dynamic>?;
      final windSpeedArray = hourlyData['windspeed_10m'] as List<dynamic>?;
      final windDirectionArray =
          hourlyData['winddirection_10m'] as List<dynamic>?;
      final humidityArray = hourlyData['relativehumidity_2m'] as List<dynamic>?;
      final precipitationArray = hourlyData['precipitation'] as List<dynamic>?;
      final cloudCoverArray = hourlyData['cloudcover'] as List<dynamic>?;

      if (timeArray == null || temperatureArray == null) {
        print('Missing essential data in response');
        return null;
      }

      // Find the index for current hour of today
      int? currentIndex;

      for (int i = 0; i < timeArray.length; i++) {
        final timeString = timeArray[i] as String;
        final dateTime = DateTime.parse(timeString);

        // Check if this matches current date and hour
        if (dateTime.year == today.year &&
            dateTime.month == today.month &&
            dateTime.day == today.day &&
            dateTime.hour == currentHour) {
          currentIndex = i;
          break;
        }
      }

      if (currentIndex == null) {
        print('Current hour data not found in response');
        return null;
      }

      // Helper function to safely convert numeric values from API
      double? safeToDouble(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        return null;
      }

      // Extract current weather data with safe type conversions
      final currentTemperature = safeToDouble(temperatureArray[currentIndex]);
      final weatherCode = weatherCodeArray?[currentIndex] as int? ?? 0;
      final windSpeed = safeToDouble(windSpeedArray?[currentIndex]);
      final windDirection = safeToDouble(windDirectionArray?[currentIndex]);
      final humidity = safeToDouble(humidityArray?[currentIndex]);
      final precipitation = safeToDouble(precipitationArray?[currentIndex]);
      final cloudCover = safeToDouble(cloudCoverArray?[currentIndex]);

      if (currentTemperature == null) {
        print('Temperature data not available for current hour');
        return null;
      }

      // Format current date
      final formattedDate =
          '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';

      return {
        'date': formattedDate,
        'hour': currentHour,
        'temperature': currentTemperature,
        'temperatureUnit': '°C',
        'weatherCode': weatherCode,
        'weatherDescription': getWeatherDescription(weatherCode),
        'weatherIcon': getWeatherIcon(weatherCode),
        'windSpeed': windSpeed,
        'windSpeedUnit': 'km/h',
        'windDirection': windDirection,
        'humidity': humidity,
        'humidityUnit': '%',
        'precipitation': precipitation ?? 0.0,
        'precipitationUnit': 'mm',
        'cloudCover': cloudCover,
        'cloudCoverUnit': '%',
        'timestamp': timeArray[currentIndex],
      };
    } catch (e) {
      print('Error getting current weather data: $e');
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
    // double screenHeight = MediaQuery.of(context).size.height;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: Scaffold(
        body: SafeArea(
          child: Directionality(
            textDirection:
                language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: RefreshIndicator(
              onRefresh: _refreshPage,
              color: AppColor.themeColor,
              child: Container(
                color: AppColor.secondaryColor,
                width: MediaQuery.of(context).size.width * 100 / 100,
                height: MediaQuery.of(context).size.height * 100 / 100,
                child: Column(
                  children: [
                    const NoInternetBanner(),
                    isLoading
                        ? exploreShimmerEffect(context)
                        : Expanded(
                            flex: 1,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  //!screen header
                                  Container(
                                    width: screenWidth > 600
                                        ? MediaQuery.of(context).size.width *
                                            95 /
                                            100
                                        : MediaQuery.of(context).size.width *
                                            90 /
                                            100,
                                    margin: const EdgeInsets.only(top: 15),
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                5 /
                                                100),
                                    decoration: const BoxDecoration(
                                        image: DecorationImage(
                                            image: AssetImage(
                                                AppImage.homeBackImage),
                                            fit: BoxFit.cover),
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(32),
                                            bottomRight: Radius.circular(32))),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              85 /
                                              100,
                                          margin:
                                              const EdgeInsets.only(top: 10),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    12 /
                                                    100,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    12 /
                                                    100,
                                                child: (profileImage != 'NA' &&
                                                        !isGuest)
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(100),
                                                        child: Image.network(
                                                          "${AppConfigProvider.imageURL}$profileImage",
                                                          fit: BoxFit.cover,
                                                          loadingBuilder:
                                                              (BuildContext
                                                                      context,
                                                                  Widget child,
                                                                  ImageChunkEvent?
                                                                      loadingProgress) {
                                                            if (loadingProgress ==
                                                                null) {
                                                              //! Image has loaded
                                                              return child;
                                                            } else {
                                                              //! Image is still loading, show shimmer
                                                              return Shimmer
                                                                  .fromColors(
                                                                baseColor: Colors
                                                                    .grey
                                                                    .shade300,
                                                                highlightColor:
                                                                    Colors.grey
                                                                        .shade100,
                                                                child:
                                                                    Container(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade300,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      )
                                                    : Image.asset(
                                                        AppImage
                                                            .profilePlaceholderImage,
                                                        fit: BoxFit.cover,
                                                      ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    notificationCount = 0;
                                                  });
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const NotificationScreen()));
                                                },
                                                child: Stack(
                                                  children: [
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              10 /
                                                              100,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              10 /
                                                              100,
                                                      child: Image.asset(AppImage
                                                          .deactiveNotificationIcon),
                                                    ),
                                                    if (notificationCount != 0)
                                                      Positioned(
                                                        right: 0,
                                                        child: Container(
                                                          alignment:
                                                              Alignment.center,
                                                          width: screenWidth *
                                                              5 /
                                                              100,
                                                          height: screenWidth *
                                                              5 /
                                                              100,
                                                          decoration: BoxDecoration(
                                                              color: AppColor
                                                                  .redcolor,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          100)),
                                                          child: Text(
                                                            notificationCount >
                                                                    9
                                                                ? "9+"
                                                                : "$notificationCount",
                                                            style: const TextStyle(
                                                                fontFamily: AppFont
                                                                    .fontFamily,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: AppColor
                                                                    .secondaryColor),
                                                          ),
                                                        ),
                                                      )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                2 /
                                                100),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const WeatherScreen(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            color: Colors.transparent,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                85 /
                                                100,
                                            child: Row(
                                              children: [
                                                Text(
                                                  AppConstant.weatherIcon,
                                                  style: const TextStyle(
                                                      color: AppColor
                                                          .secondaryColor,
                                                      fontSize: 34,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily:
                                                          AppFont.fontFamily),
                                                ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            2 /
                                                            100),
                                                Text(
                                                  AppConstant.temperature,
                                                  style: const TextStyle(
                                                      color: AppColor
                                                          .secondaryColor,
                                                      fontSize: 34,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily:
                                                          AppFont.fontFamily),
                                                ),
                                                Text(
                                                  AppConstant.unit,
                                                  style: const TextStyle(
                                                      color: AppColor
                                                          .secondaryColor,
                                                      fontSize: 34,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily:
                                                          AppFont.fontFamily),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const WeatherScreen(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 9, vertical: 5),
                                            decoration: BoxDecoration(
                                                color: AppColor.secondaryColor
                                                    .withOpacity(0.3),
                                                borderRadius:
                                                    BorderRadius.circular(5)),
                                            child: Text(
                                              AppConstant.weatherDesc,
                                              style: const TextStyle(
                                                  color:
                                                      AppColor.secondaryColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily:
                                                      AppFont.fontFamily),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                1 /
                                                100),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100),

                                  //!activity list
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        100 /
                                        100,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Wrap(
                                        children: List.generate(
                                            activitiesList.length, (index) {
                                          return Padding(
                                            padding: language == 0
                                                ? EdgeInsets.only(
                                                    left: index == 0
                                                        ? screenWidth > 600
                                                            ? 20
                                                            : 18
                                                        : 10,
                                                    right: index ==
                                                            activitiesList
                                                                    .length -
                                                                1
                                                        ? 10
                                                        : 0)
                                                : EdgeInsets.only(
                                                    right: index == 0
                                                        ? screenWidth > 600
                                                            ? 20
                                                            : 18
                                                        : 10,
                                                    left: index ==
                                                            activitiesList
                                                                    .length -
                                                                1
                                                        ? 10
                                                        : 0),
                                            child: GestureDetector(
                                              onTap: () {
                                                if (selectActivity ==
                                                    activitiesList[index]
                                                        ['trip_type_id']) {
                                                  setState(() {
                                                    selectActivity = 0;
                                                  });
                                                  homeApi(userId);
                                                } else {
                                                  setState(() {
                                                    selectActivity =
                                                        activitiesList[index]
                                                            ['trip_type_id'];
                                                  });
                                                  getDestinationAccordingActivity(
                                                      userId,
                                                      context,
                                                      screenWidth);
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color: selectActivity ==
                                                            activitiesList[
                                                                    index]
                                                                ['trip_type_id']
                                                        ? AppColor.themeColor
                                                        : AppColor
                                                            .boxshadowColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6,
                                                        horizontal: 15),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              5 /
                                                              100,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              5 /
                                                              100,
                                                      child: Image.network(
                                                        "${AppConfigProvider.imageURL}${activitiesList[index]['vector_image']}",
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            1 /
                                                            100),
                                                    Text(
                                                      activitiesList[index]
                                                              ['name_english']
                                                          [language],
                                                      style: TextStyle(
                                                          color: selectActivity ==
                                                                  activitiesList[
                                                                          index]
                                                                      [
                                                                      'trip_type_id']
                                                              ? AppColor
                                                                  .secondaryColor
                                                              : AppColor
                                                                  .primaryColor,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontFamily: AppFont
                                                              .fontFamily),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100),

                                  if (promotionsList.isNotEmpty) ...[
                                    SizedBox(
                                      width: screenWidth > 600
                                          ? MediaQuery.of(context).size.width *
                                              95 /
                                              100
                                          : MediaQuery.of(context).size.width *
                                              90 /
                                              100,
                                      child: Text(
                                        AppLanguage.promotionsText[language],
                                        style: const TextStyle(
                                            color: AppColor.primaryColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                2 /
                                                100),

                                    //!promotions carousal
                                    Center(
                                      child: Column(
                                        children: [
                                          CarouselSlider(
                                            items: promotionsList
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              int index = entry.key;

                                              bool isCenter = hasInitialized &&
                                                  index == status;

                                              return AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 100),
                                                margin: EdgeInsets.only(
                                                  top: isCenter ? 0 : 10,
                                                  bottom: isCenter
                                                      ? screenWidth > 600
                                                          ? 100
                                                          : 60
                                                      : 0,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  child: Stack(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          if (promotionsList[
                                                                      index]
                                                                  ['type'] ==
                                                              0) {
                                                            if (promotionsList[
                                                                        index]
                                                                    ['link'] !=
                                                                null) {
                                                              openUrl(
                                                                  url: promotionsList[
                                                                          index]
                                                                      ['link']);
                                                            }
                                                          } else if (promotionsList[
                                                                      index]
                                                                  ['type'] ==
                                                              1) {
                                                            if (promotionsList[
                                                                        index][
                                                                    'advertisement_type'] ==
                                                                0) {
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) =>
                                                                          PrivateTripDetailsScreen(
                                                                            tripId:
                                                                                promotionsList[index]['trip_id'].toString(),
                                                                          )));
                                                            } else {
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) =>
                                                                          PublicTripDetailsScreen(
                                                                            tripId:
                                                                                promotionsList[index]['trip_id'].toString(),
                                                                          )));
                                                            }
                                                          }
                                                        },
                                                        child: SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.75,
                                                          height: screenWidth >
                                                                  600
                                                              ? MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.35
                                                              : MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.28,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            child:
                                                                Image.network(
                                                              '${AppConfigProvider.imageURL}${promotionsList[index]['image']}',
                                                              fit: BoxFit.cover,
                                                              loadingBuilder:
                                                                  (BuildContext
                                                                          context,
                                                                      Widget
                                                                          child,
                                                                      ImageChunkEvent?
                                                                          loadingProgress) {
                                                                if (loadingProgress ==
                                                                    null) {
                                                                  return child;
                                                                } else {
                                                                  return Shimmer
                                                                      .fromColors(
                                                                    baseColor: Colors
                                                                        .grey
                                                                        .shade300,
                                                                    highlightColor:
                                                                        Colors
                                                                            .grey
                                                                            .shade100,
                                                                    child:
                                                                        Container(
                                                                      color: Colors
                                                                          .grey
                                                                          .shade300,
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        bottom: 18,
                                                        left: 20,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            if (promotionsList[
                                                                        index]
                                                                    ['type'] ==
                                                                0) {
                                                              if (promotionsList[
                                                                          index]
                                                                      [
                                                                      'link'] !=
                                                                  null) {
                                                                openUrl(
                                                                    url: promotionsList[
                                                                            index]
                                                                        [
                                                                        'link']);
                                                              }
                                                            } else if (promotionsList[
                                                                        index]
                                                                    ['type'] ==
                                                                1) {
                                                              if (promotionsList[
                                                                          index]
                                                                      [
                                                                      'advertisement_type'] ==
                                                                  0) {
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder: (context) =>
                                                                            PrivateTripDetailsScreen(
                                                                              tripId: promotionsList[index]['trip_id'].toString(),
                                                                            )));
                                                              } else {
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder: (context) =>
                                                                            PublicTripDetailsScreen(
                                                                              tripId: promotionsList[index]['trip_id'].toString(),
                                                                            )));
                                                              }
                                                            }
                                                          },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical: 4,
                                                                    horizontal:
                                                                        15),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: AppColor
                                                                  .secondaryColor,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          17),
                                                            ),
                                                            child: Text(
                                                              AppLanguage
                                                                      .exploreText[
                                                                  language],
                                                              style:
                                                                  const TextStyle(
                                                                color: AppColor
                                                                    .themeColor,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontFamily: AppFont
                                                                    .fontFamily,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            carouselController:
                                                carouselController,
                                            options: CarouselOptions(
                                              height: screenWidth > 600
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.35
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.28,
                                              viewportFraction: 0.7,
                                              enlargeCenterPage: true,
                                              autoPlay: true,
                                              autoPlayInterval:
                                                  const Duration(seconds: 3),
                                              onPageChanged: (index, reason) {
                                                setState(() {
                                                  status = index;
                                                });
                                              },
                                            ),
                                          ),
                                          //! Dots Indicator
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: List.generate(
                                                promotionsList.length, (index) {
                                              return GestureDetector(
                                                onTap: () => carouselController
                                                    .animateToPage(index),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 5),
                                                  child: Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            2 /
                                                            100,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            2 /
                                                            100,
                                                    decoration: BoxDecoration(
                                                      color: status == index
                                                          ? Colors.blue
                                                          : Colors.grey,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              3 /
                                              100),

                                  //!popular destination text
                                  SizedBox(
                                    width: screenWidth > 600
                                        ? MediaQuery.of(context).size.width *
                                            95 /
                                            100
                                        : MediaQuery.of(context).size.width *
                                            90 /
                                            100,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          AppLanguage
                                              .popularDestinationText[language],
                                          style: const TextStyle(
                                              color: AppColor.primaryColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily),
                                        ),
                                        if (popularDestinationList.isNotEmpty)
                                          GestureDetector(
                                            onTap: () {
                                              viewMoreDestinationBottomSheet(
                                                  context, screenWidth);
                                            },
                                            child: Text(
                                              AppLanguage
                                                  .viewMoreText[language],
                                              style: const TextStyle(
                                                  color: AppColor.themeColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily:
                                                      AppFont.fontFamily),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100),

                                  //!popular destination list
                                  if (hasTripDestinationsList.isNotEmpty)
                                    Column(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              100 /
                                              100,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Wrap(
                                              children: List.generate(
                                                  hasTripDestinationsList
                                                      .length, (index) {
                                                return Container(
                                                  padding: language == 1
                                                      ? EdgeInsets.only(
                                                          right: index == 0
                                                              ? screenWidth >
                                                                      600
                                                                  ? 20
                                                                  : 18
                                                              : 10,
                                                          left: index ==
                                                                  hasTripDestinationsList
                                                                          .length -
                                                                      1
                                                              ? 10
                                                              : 0)
                                                      : EdgeInsets.only(
                                                          left: index == 0
                                                              ? screenWidth >
                                                                      600
                                                                  ? 20
                                                                  : 18
                                                              : 10,
                                                          right: index ==
                                                                  hasTripDestinationsList
                                                                          .length -
                                                                      1
                                                              ? 10
                                                              : 0),
                                                  child: Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          if (selectActivity ==
                                                              0) {
                                                            getActivityAccordingDestination(
                                                                context,
                                                                screenWidth,
                                                                hasTripDestinationsList[
                                                                        index][
                                                                    'destination_id']);
                                                          } else {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        Beaches(
                                                                  status: 0,
                                                                  activityId:
                                                                      selectActivity
                                                                          .toString(),
                                                                  destinationId:
                                                                      hasTripDestinationsList[index]
                                                                              [
                                                                              'destination_id']
                                                                          .toString(),
                                                                  toOpen: "",
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              40 /
                                                              100,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              25 /
                                                              100,
                                                          padding: language == 1
                                                              ? const EdgeInsets
                                                                  .only(
                                                                  right: 15)
                                                              : const EdgeInsets
                                                                  .only(
                                                                  left: 15),
                                                          decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                  image: hasTripDestinationsList[index]
                                                                              [
                                                                              'destination_image'] !=
                                                                          null
                                                                      ? NetworkImage(
                                                                          "${AppConfigProvider.imageURL}${hasTripDestinationsList[index]['destination_image']}")
                                                                      : const AssetImage(
                                                                              AppImage.imageFrameImage)
                                                                          as ImageProvider,
                                                                  fit: BoxFit
                                                                      .cover),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          18)),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                hasTripDestinationsList[index]
                                                                            [
                                                                            'destination_english']
                                                                        [
                                                                        language] ??
                                                                    "",
                                                                style: const TextStyle(
                                                                    color: AppColor
                                                                        .secondaryColor,
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontFamily:
                                                                        AppFont
                                                                            .fontFamily),
                                                              ),
                                                              if (hasTripDestinationsList[
                                                                              index]
                                                                          [
                                                                          'rating']
                                                                      .toString() !=
                                                                  "0.00")
                                                                Container(
                                                                  width: screenWidth >
                                                                          600
                                                                      ? MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          12 /
                                                                          100
                                                                      : MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          16 /
                                                                          100,
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          2),
                                                                  decoration: BoxDecoration(
                                                                      color: AppColor
                                                                          .secondaryColor
                                                                          .withOpacity(
                                                                              0.3),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              25)),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      SizedBox(
                                                                        width: screenWidth >
                                                                                600
                                                                            ? MediaQuery.of(context).size.width *
                                                                                3 /
                                                                                100
                                                                            : MediaQuery.of(context).size.width *
                                                                                4 /
                                                                                100,
                                                                        height: MediaQuery.of(context).size.width *
                                                                            4 /
                                                                            100,
                                                                        child: Image.asset(
                                                                            AppImage.ratingIcon),
                                                                      ),
                                                                      SizedBox(
                                                                          width: MediaQuery.of(context).size.width *
                                                                              1 /
                                                                              100),
                                                                      SizedBox(
                                                                        width: screenWidth >
                                                                                600
                                                                            ? MediaQuery.of(context).size.width *
                                                                                6 /
                                                                                100
                                                                            : MediaQuery.of(context).size.width *
                                                                                8 /
                                                                                100,
                                                                        child:
                                                                            Text(
                                                                          hasTripDestinationsList[index]['rating']
                                                                              .toString(),
                                                                          style: const TextStyle(
                                                                              color: AppColor.secondaryColor,
                                                                              fontSize: 12,
                                                                              fontWeight: FontWeight.w600,
                                                                              fontFamily: AppFont.fontFamily),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              SizedBox(
                                                                  height: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .height *
                                                                      2 /
                                                                      100),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                2 /
                                                100),
                                      ],
                                    ),

                                  if (hasTripDestinationsList.isEmpty)
                                    Column(
                                      children: [
                                        Container(
                                          alignment: Alignment.center,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              90 /
                                              100,
                                          child: Text(
                                            AppLanguage
                                                    .noDestinationAvailableText[
                                                language],
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                2 /
                                                100),
                                      ],
                                    ),

                                  //!category text
                                  //! Container(
                                  //!   width: screenWidth > 600
                                  //!       ? MediaQuery.of(context).size.width * 95 / 100
                                  //!       : MediaQuery.of(context).size.width * 90 / 100,
                                  //!   child: Row(
                                  //!     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //!     children: [
                                  //!       Text(
                                  //!         AppLanguage.categoriesText[language],
                                  //!         style: const TextStyle(
                                  //!             color: AppColor.primaryColor,
                                  //!             fontSize: 16,
                                  //!             fontWeight: FontWeight.w600,
                                  //!             fontFamily: AppFont.fontFamily),
                                  //!       ),
                                  //!       GestureDetector(
                                  //!         onTap: () {
                                  //!           viewMoreCategoriesBottomSheet(
                                  //!               context, screenWidth);
                                  //!         },
                                  //!         child: Text(
                                  //!           AppLanguage.viewMoreText[language],
                                  //!           style: const TextStyle(
                                  //!               color: AppColor.themeColor,
                                  //!               fontSize: 12,
                                  //!               fontWeight: FontWeight.w600,
                                  //!               fontFamily: AppFont.fontFamily),
                                  //!         ),
                                  //!       ),
                                  //!     ],
                                  //!   ),
                                  //! ),
                                  //! SizedBox(
                                  //!     height:
                                  //!         MediaQuery.of(context).size.height * 2 / 100),

                                  //!category list
                                  //! Container(
                                  //!   width:
                                  //!       MediaQuery.of(context).size.width * 100 / 100,
                                  //!   child: SingleChildScrollView(
                                  //!     scrollDirection: Axis.horizontal,
                                  //!     child: Wrap(
                                  //!       spacing: 10,
                                  //!       alignment: WrapAlignment.spaceBetween,
                                  //!       children:
                                  //!           List.generate(categoryList.length, (index) {
                                  //!         return Padding(
                                  //!           padding: language == 1
                                  //!               ? EdgeInsets.only(
                                  //!                   right: index == 0
                                  //!                       ? screenWidth > 600
                                  //!                           ? 20
                                  //!                           : 18
                                  //!                       : 10,
                                  //!                   left: index ==
                                  //!                           popularDestinationList
                                  //!                                   .length -
                                  //!                               1
                                  //!                       ? 10
                                  //!                       : 0)
                                  //!               : EdgeInsets.only(
                                  //!                   left: index == 0
                                  //!                       ? screenWidth > 600
                                  //!                           ? 20
                                  //!                           : 18
                                  //!                       : 10,
                                  //!                   right: index ==
                                  //!                           popularDestinationList
                                  //!                                   .length -
                                  //!                               1
                                  //!                       ? 10
                                  //!                       : 0),
                                  //!           child: Column(
                                  //!             children: [
                                  //!               Container(
                                  //!                 width: MediaQuery.of(context)
                                  //!                         .size
                                  //!                         .width *
                                  //!                     20 /
                                  //!                     100,
                                  //!                 height: MediaQuery.of(context)
                                  //!                         .size
                                  //!                         .width *
                                  //!                     20 /
                                  //!                     100,
                                  //!                 decoration: BoxDecoration(
                                  //!                     image: DecorationImage(
                                  //!                         image: categoryList[index]
                                  //!                                     ['boat_image'] !=
                                  //!                                 null
                                  //!                             ? NetworkImage(
                                  //!                                 "${AppConfigProvider.imageURL}${categoryList[index]['boat_image']}")
                                  //!                             : const AssetImage(
                                  //!                                     AppImage
                                  //!                                         .dummyIcon)
                                  //!                                 as ImageProvider,
                                  //!                         fit: BoxFit.cover),
                                  //!                     borderRadius:
                                  //!                         BorderRadius.circular(16)),
                                  //!               ),
                                  //!               SizedBox(
                                  //!                   height: MediaQuery.of(context)
                                  //!                           .size
                                  //!                           .height *
                                  //!                       1 /
                                  //!                       100),
                                  //!               Text(
                                  //!                 categoryList[index]
                                  //!                             ['boat_name_english']
                                  //!                         [language] ??
                                  //!                     "",
                                  //!                 style: const TextStyle(
                                  //!                     color: AppColor.themeColor,
                                  //!                     fontSize: 14,
                                  //!                     fontWeight: FontWeight.w600,
                                  //!                     fontFamily: AppFont.fontFamily),
                                  //!               ),
                                  //!             ],
                                  //!           ),
                                  //!         );
                                  //!       }),
                                  //!     ),
                                  //!   ),
                                  //! ),
                                  //! SizedBox(
                                  //!     height:
                                  //!         MediaQuery.of(context).size.height * 2 / 100),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  setSearch(BuildContext context, screenWidth) {
    setState(() {
      isSearch = !isSearch;
    });
    Navigator.pop(context);
    viewMoreDestinationBottomSheet(context, screenWidth);
  }

  void viewMoreDestinationBottomSheet(BuildContext contextUp, screenWidth) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      constraints: BoxConstraints.expand(
          width: screenWidth,
          height: isSearch
              ? MediaQuery.of(contextUp).size.height * 96 / 100
              : MediaQuery.of(contextUp).size.height * 60 / 100),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      context: contextUp,
      backgroundColor: AppColor.secondaryColor,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: ((context, setState) {
            return GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Directionality(
                    textDirection: language == 1
                        ? ui.TextDirection.rtl
                        : ui.TextDirection.ltr,
                    child: Container(
                        height: MediaQuery.of(context).size.height * 55 / 100,
                        width: MediaQuery.of(context).size.width * 100 / 100,
                        decoration: const BoxDecoration(
                          color: AppColor.secondaryColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(children: [
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 4 / 100,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    AppLanguage.selectDestinationText[language],
                                    style: TextStyle(
                                        color: AppColor.primaryColor,
                                        fontFamily: AppFont.fontFamily,
                                        fontWeight: FontWeight.w700,
                                        fontSize: screenWidth > 600 ? 20 : 16)),
                                GestureDetector(
                                  onTap: () {
                                    setSearch(context, screenWidth);
                                  },
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        12 /
                                        100,
                                    height: MediaQuery.of(context).size.width *
                                        12 /
                                        100,
                                    child:
                                        Image.asset(AppImage.searchRoundIcon),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSearch)
                            Center(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    80 /
                                    100,
                                height: MediaQuery.of(context).size.height *
                                    6 /
                                    100,
                                child: TextFormField(
                                  readOnly: false,
                                  style: AppConstant.textFilledHeading,
                                  textAlignVertical: TextAlignVertical.center,
                                  keyboardType: TextInputType.name,
                                  autofocus: isSearch,
                                  //!controller: controller,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value.isNotEmpty) {
                                        searchResultCountry(value);
                                      } else {
                                        bottomSheetPopularDestinationList =
                                            searchPopularDestinationList;
                                      }
                                    });
                                  },
                                  decoration: InputDecoration(
                                    prefixIcon: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          child: Image.asset(
                                            AppImage.searchIcon1,
                                            height: screenWidth > 600
                                                ? MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    3 /
                                                    100
                                                : MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    5 /
                                                    100,
                                            width: screenWidth > 600
                                                ? MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    3 /
                                                    100
                                                : MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    5 /
                                                    100,
                                          ),
                                        ),
                                      ],
                                    ),
                                    border: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: AppColor.textColor),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(25)),
                                    ),
                                    enabledBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: AppColor.textColor),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(25)),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: AppColor.textColor),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(25)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 15),
                                    filled: false,
                                    counterText: '',
                                    hintText:
                                        AppLanguage.searchInputText[language],
                                    hintStyle: const TextStyle(
                                        color: AppColor.textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: AppFont.fontFamily),
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 3 / 100,
                          ),
                          Expanded(
                              child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  alignment: Alignment.center,
                                  child: Wrap(
                                    spacing: 15,
                                    runSpacing: 12,
                                    children: List.generate(
                                        bottomSheetPopularDestinationList
                                            .length, (index) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                          if (selectActivity == 0) {
                                            getActivityAccordingDestination(
                                                contextUp,
                                                screenWidth,
                                                bottomSheetPopularDestinationList[
                                                    index]['destination_id']);
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Beaches(
                                                  status: 0,
                                                  activityId:
                                                      selectActivity.toString(),
                                                  destinationId:
                                                      bottomSheetPopularDestinationList[
                                                                  index]
                                                              ['destination_id']
                                                          .toString(),
                                                  toOpen: "",
                                                ),
                                              ),
                                            );
                                          }

                                          //! Navigator.push(
                                          //!     context,
                                          //!     MaterialPageRoute(
                                          //!         builder: (context) => const Beaches(
                                          //!               status: 0,
                                          //!             )));
                                        },
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              27 /
                                              100,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              18 /
                                              100,
                                          padding:
                                              const EdgeInsets.only(left: 15),
                                          decoration: BoxDecoration(
                                              image: DecorationImage(
                                                  image: bottomSheetPopularDestinationList[
                                                                  index][
                                                              'destination_image'] !=
                                                          null
                                                      ? NetworkImage(
                                                          "${AppConfigProvider.imageURL}${bottomSheetPopularDestinationList[index]['destination_image']}")
                                                      : const AssetImage(
                                                              AppImage
                                                                  .dummyIcon)
                                                          as ImageProvider,
                                                  fit: BoxFit.cover),
                                              borderRadius:
                                                  BorderRadius.circular(18)),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment: language == 0
                                                ? CrossAxisAlignment.start
                                                : CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                bottomSheetPopularDestinationList[
                                                                index][
                                                            'destination_english']
                                                        [language] ??
                                                    "",
                                                style: const TextStyle(
                                                    color:
                                                        AppColor.secondaryColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily:
                                                        AppFont.fontFamily),
                                              ),
                                              if (bottomSheetPopularDestinationList[
                                                          index]['rating']
                                                      .toString() !=
                                                  "0.00")
                                                Container(
                                                  width: screenWidth > 600
                                                      ? MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          12 /
                                                          100
                                                      : MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          16 /
                                                          100,
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 2),
                                                  decoration: BoxDecoration(
                                                      color: AppColor
                                                          .secondaryColor
                                                          .withOpacity(0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              25)),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width: screenWidth > 600
                                                            ? MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                3 /
                                                                100
                                                            : MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                4 /
                                                                100,
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            4 /
                                                            100,
                                                        child: Image.asset(
                                                            AppImage
                                                                .ratingIcon),
                                                      ),
                                                      SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              1 /
                                                              100),
                                                      SizedBox(
                                                        width: screenWidth > 600
                                                            ? MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                6 /
                                                                100
                                                            : MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                8 /
                                                                100,
                                                        child: Text(
                                                          bottomSheetPopularDestinationList[
                                                                      index]
                                                                  ['rating']
                                                              .toString(),
                                                          style: const TextStyle(
                                                              color: AppColor
                                                                  .secondaryColor,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontFamily: AppFont
                                                                  .fontFamily),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      2 /
                                                      100),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100),
                              ],
                            ),
                          ))
                        ])),
                  ),
                ));
          }),
        );
      },
    );
  }

  void viewFilteredDestinationBottomSheet(
      BuildContext context, screenWidth, activityId, VoidCallback onDismiss) {
    showModalBottomSheet<void>(
        isScrollControlled: true,
        constraints: BoxConstraints.expand(
            width: screenWidth,
            height: MediaQuery.of(context).size.height * 60 / 100),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Directionality(
                textDirection:
                    language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                child: Container(
                    height: MediaQuery.of(context).size.height * 55 / 100,
                    width: MediaQuery.of(context).size.width * 100 / 100,
                    decoration: const BoxDecoration(
                      color: AppColor.secondaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 4 / 100,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLanguage.selectDestinationText[language],
                                style: TextStyle(
                                    color: AppColor.primaryColor,
                                    fontFamily: AppFont.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: screenWidth > 600 ? 20 : 16)),
                            // Container(
                            //   width: MediaQuery.of(context).size.width * 12 / 100,
                            //   height:
                            //       MediaQuery.of(context).size.width * 12 / 100,
                            //   child: Image.asset(AppImage.searchRoundIcon),
                            // ),
                          ],
                        ),
                      ),
                      // Center(
                      //   child: SizedBox(
                      //     width: MediaQuery.of(context).size.width * 60 / 100,
                      //     height: MediaQuery.of(context).size.height * 6 / 100,
                      //     child: TextFormField(
                      //       readOnly: false,
                      //       style: AppConstant.textFilledHeading,
                      //       textAlignVertical: TextAlignVertical.center,
                      //       keyboardType: TextInputType.name,
                      //       //!controller: controller,
                      //       onChanged: (value) {
                      //         setState(() {
                      //           if (value.isNotEmpty) {
                      //             searchResultCountry(value);
                      //           } else {
                      //             bottomSheetPopularDestinationList =
                      //                 searchPopularDestinationList;
                      //           }
                      //         });
                      //       },
                      //       decoration: InputDecoration(
                      //         prefixIcon: Column(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           children: [
                      //             SizedBox(
                      //               child: Image.asset(
                      //                 AppImage.searchIcon1,
                      //                 height: screenWidth > 600
                      //                     ? MediaQuery.of(context).size.width *
                      //                         3 /
                      //                         100
                      //                     : MediaQuery.of(context).size.width *
                      //                         5 /
                      //                         100,
                      //                 width: screenWidth > 600
                      //                     ? MediaQuery.of(context).size.width *
                      //                         3 /
                      //                         100
                      //                     : MediaQuery.of(context).size.width *
                      //                         5 /
                      //                         100,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //         border: const OutlineInputBorder(
                      //           borderSide:
                      //               BorderSide(color: AppColor.secondaryColor),
                      //           borderRadius:
                      //               BorderRadius.all(Radius.circular(25)),
                      //         ),
                      //         enabledBorder: const OutlineInputBorder(
                      //           borderSide:
                      //               BorderSide(color: AppColor.secondaryColor),
                      //           borderRadius:
                      //               BorderRadius.all(Radius.circular(25)),
                      //         ),
                      //         focusedBorder: const OutlineInputBorder(
                      //           borderSide:
                      //               BorderSide(color: AppColor.secondaryColor),
                      //           borderRadius:
                      //               BorderRadius.all(Radius.circular(25)),
                      //         ),
                      //         contentPadding: const EdgeInsets.symmetric(
                      //             vertical: 5, horizontal: 15),
                      //         filled: false,
                      //         counterText: '',
                      //         hintText: AppLanguage.searchInputText[language],
                      //         hintStyle: const TextStyle(
                      //             color: AppColor.secondaryColor,
                      //             fontSize: 14,
                      //             fontWeight: FontWeight.w400,
                      //             fontFamily: AppFont.fontFamily),
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * 3 / 100,
                      ),
                      Expanded(
                          child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (filteredDestinationsList.isNotEmpty)
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                // alignment: Alignment.center,
                                child: Wrap(
                                  spacing: 15,
                                  runSpacing: 12,
                                  children: List.generate(
                                      filteredDestinationsList.length, (index) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Beaches(
                                              status: 0,
                                              activityId: activityId.toString(),
                                              destinationId:
                                                  filteredDestinationsList[
                                                              index]
                                                          ['destination_id']
                                                      .toString(),
                                              toOpen: "",
                                            ),
                                          ),
                                        );

                                        setState(() {
                                          selectActivity = 0;
                                        });
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                27 /
                                                100,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                18 /
                                                100,
                                        padding:
                                            const EdgeInsets.only(left: 15),
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: filteredDestinationsList[
                                                                index][
                                                            'destination_image'] !=
                                                        null
                                                    ? NetworkImage(
                                                        "${AppConfigProvider.imageURL}${filteredDestinationsList[index]['destination_image']}")
                                                    : const AssetImage(
                                                            AppImage.dummyIcon)
                                                        as ImageProvider,
                                                fit: BoxFit.cover),
                                            borderRadius:
                                                BorderRadius.circular(18)),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment: language == 0
                                              ? CrossAxisAlignment.start
                                              : CrossAxisAlignment.end,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                filteredDestinationsList[index]
                                                        ['destination_english']
                                                    [language],
                                                style: const TextStyle(
                                                    color:
                                                        AppColor.secondaryColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily:
                                                        AppFont.fontFamily),
                                              ),
                                            ),
                                            if (filteredDestinationsList[index]
                                                        ['rating']
                                                    .toString() !=
                                                "0.00")
                                              Container(
                                                width: screenWidth > 600
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        12 /
                                                        100
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        16 /
                                                        100,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2),
                                                decoration: BoxDecoration(
                                                    color: AppColor
                                                        .secondaryColor
                                                        .withOpacity(0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25)),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: screenWidth > 600
                                                          ? MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              3 /
                                                              100
                                                          : MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              4 /
                                                              100,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              4 /
                                                              100,
                                                      child: Image.asset(
                                                          AppImage.ratingIcon),
                                                    ),
                                                    SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            1 /
                                                            100),
                                                    SizedBox(
                                                      width: screenWidth > 600
                                                          ? MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              6 /
                                                              100
                                                          : MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              8 /
                                                              100,
                                                      child: Text(
                                                        filteredDestinationsList[
                                                                index]['rating']
                                                            .toString(),
                                                        style: const TextStyle(
                                                            color: AppColor
                                                                .secondaryColor,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontFamily: AppFont
                                                                .fontFamily),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    2 /
                                                    100),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            if (filteredDestinationsList.isEmpty)
                              Column(
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              15 /
                                              100),
                                  //!text msg
                                  SizedBox(
                                    width: screenWidth * 75 / 100,
                                    child: Text(
                                      AppLanguage
                                          .destinationNoDataMsg[language],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),
                          ],
                        ),
                      ))
                    ])),
              ),
            );
          });
        }).then((_) {
      // Runs after bottom sheet is dismissed
      onDismiss();
    });
  }

  void viewFilteredActivitiesBottomSheet(BuildContext context, screenWidth,
      destinationId, VoidCallback onDismiss) {
    showModalBottomSheet<void>(
        isScrollControlled: true,
        constraints: BoxConstraints.expand(
            width: screenWidth,
            height: MediaQuery.of(context).size.height * 60 / 100),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Directionality(
                textDirection:
                    language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                child: Container(
                    height: MediaQuery.of(context).size.height * 55 / 100,
                    width: MediaQuery.of(context).size.width * 100 / 100,
                    decoration: const BoxDecoration(
                      color: AppColor.secondaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 4 / 100,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLanguage.selectActivityText[language],
                                style: TextStyle(
                                    color: AppColor.primaryColor,
                                    fontFamily: AppFont.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: screenWidth > 600 ? 20 : 16)),
                            // Container(
                            //   width: MediaQuery.of(context).size.width * 12 / 100,
                            //   height:
                            //       MediaQuery.of(context).size.width * 12 / 100,
                            //   child: Image.asset(AppImage.searchRoundIcon),
                            // ),
                          ],
                        ),
                      ),
                      // Center(
                      //   child: SizedBox(
                      //     width: MediaQuery.of(context).size.width * 60 / 100,
                      //     height: MediaQuery.of(context).size.height * 6 / 100,
                      //     child: TextFormField(
                      //       readOnly: false,
                      //       style: AppConstant.textFilledHeading,
                      //       textAlignVertical: TextAlignVertical.center,
                      //       keyboardType: TextInputType.name,
                      //       //!controller: controller,
                      //       onChanged: (value) {
                      //         setState(() {
                      //           if (value.isNotEmpty) {
                      //             searchResultCountry(value);
                      //           } else {
                      //             bottomSheetPopularDestinationList =
                      //                 searchPopularDestinationList;
                      //           }
                      //         });
                      //       },
                      //       decoration: InputDecoration(
                      //         prefixIcon: Column(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           children: [
                      //             SizedBox(
                      //               child: Image.asset(
                      //                 AppImage.searchIcon1,
                      //                 height: screenWidth > 600
                      //                     ? MediaQuery.of(context).size.width *
                      //                         3 /
                      //                         100
                      //                     : MediaQuery.of(context).size.width *
                      //                         5 /
                      //                         100,
                      //                 width: screenWidth > 600
                      //                     ? MediaQuery.of(context).size.width *
                      //                         3 /
                      //                         100
                      //                     : MediaQuery.of(context).size.width *
                      //                         5 /
                      //                         100,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //         border: const OutlineInputBorder(
                      //           borderSide:
                      //               BorderSide(color: AppColor.secondaryColor),
                      //           borderRadius:
                      //               BorderRadius.all(Radius.circular(25)),
                      //         ),
                      //         enabledBorder: const OutlineInputBorder(
                      //           borderSide:
                      //               BorderSide(color: AppColor.secondaryColor),
                      //           borderRadius:
                      //               BorderRadius.all(Radius.circular(25)),
                      //         ),
                      //         focusedBorder: const OutlineInputBorder(
                      //           borderSide:
                      //               BorderSide(color: AppColor.secondaryColor),
                      //           borderRadius:
                      //               BorderRadius.all(Radius.circular(25)),
                      //         ),
                      //         contentPadding: const EdgeInsets.symmetric(
                      //             vertical: 5, horizontal: 15),
                      //         filled: false,
                      //         counterText: '',
                      //         hintText: AppLanguage.searchInputText[language],
                      //         hintStyle: const TextStyle(
                      //             color: AppColor.secondaryColor,
                      //             fontSize: 14,
                      //             fontWeight: FontWeight.w400,
                      //             fontFamily: AppFont.fontFamily),
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * 3 / 100,
                      ),
                      Expanded(
                          child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (filteredActivityList.isNotEmpty)
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                // alignment: Alignment.center,
                                child: Wrap(
                                  spacing: 15,
                                  runSpacing: 12,
                                  children: List.generate(
                                      filteredActivityList.length, (index) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Beaches(
                                              status: 0,
                                              activityId:
                                                  filteredActivityList[index]
                                                          ['activity_id']
                                                      .toString(),
                                              destinationId:
                                                  destinationId.toString(),
                                              toOpen: "",
                                            ),
                                          ),
                                        );

                                        setState(() {
                                          selectActivity = 0;
                                        });
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                27 /
                                                100,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                18 /
                                                100,
                                        padding:
                                            const EdgeInsets.only(left: 15),
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: filteredActivityList[
                                                            index]['image'] !=
                                                        null
                                                    ? NetworkImage(
                                                        "${AppConfigProvider.imageURL}${filteredActivityList[index]['image']}")
                                                    : const AssetImage(
                                                            AppImage.dummyIcon)
                                                        as ImageProvider,
                                                fit: BoxFit.cover),
                                            borderRadius:
                                                BorderRadius.circular(18)),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment: language == 0
                                              ? CrossAxisAlignment.start
                                              : CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              width: screenWidth * 27 / 100,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  filteredActivityList[index]
                                                          ['activity_name']
                                                      [language],
                                                  style: const TextStyle(
                                                      color: AppColor
                                                          .secondaryColor,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFamily:
                                                          AppFont.fontFamily),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    2 /
                                                    100),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            if (filteredActivityList.isEmpty)
                              Column(
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              15 /
                                              100),
                                  //!text msg
                                  SizedBox(
                                    width: screenWidth * 75 / 100,
                                    child: Text(
                                      AppLanguage.activityNoDataMsg[language],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),
                          ],
                        ),
                      ))
                    ])),
              ),
            );
          });
        }).then((_) {
      // Runs after bottom sheet is dismissed
      onDismiss();
    });
  }

  //! void viewMoreCategoriesBottomSheet(BuildContext context, screenWidth) {
  //!   showModalBottomSheet<void>(
  //!     isScrollControlled: true,
  //!     constraints: BoxConstraints.expand(
  //!         width: screenWidth,
  //!         height: MediaQuery.of(context).size.height * 60 / 100),
  //!     shape: const RoundedRectangleBorder(
  //!       borderRadius: BorderRadius.only(
  //!         topLeft: Radius.circular(30),
  //!         topRight: Radius.circular(30),
  //!       ),
  //!     ),
  //!     context: context,
  //!     builder: (BuildContext context) {
  //!       return StatefulBuilder(
  //!         builder: (context, setState) {
  //!           return Container(
  //!             height: MediaQuery.of(context).size.height * 55 / 100,
  //!             width: MediaQuery.of(context).size.width * 100 / 100,
  //!             decoration: const BoxDecoration(
  //!               color: AppColor.secondaryColor,
  //!               borderRadius: BorderRadius.only(
  //!                 topLeft: Radius.circular(30),
  //!                 topRight: Radius.circular(30),
  //!               ),
  //!             ),
  //!             child: Column(
  //!               children: [
  //!                 SizedBox(
  //!                   height: MediaQuery.of(context).size.height * 4 / 100,
  //!                 ),
  //!                 Container(
  //!                   width: MediaQuery.of(context).size.width * 90 / 100,
  //!                   child: Row(
  //!                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //!                     children: [
  //!                       Text(AppLanguage.categoriesText[language],
  //!                           style: TextStyle(
  //!                               color: AppColor.primaryColor,
  //!                               fontFamily: AppFont.fontFamily,
  //!                               fontWeight: FontWeight.w700,
  //!                               fontSize: screenWidth > 600 ? 20 : 16)),
  //!                       Container(
  //!                         width: MediaQuery.of(context).size.width * 12 / 100,
  //!                         height: MediaQuery.of(context).size.width * 12 / 100,
  //!                         child: Image.asset(AppImage.searchRoundIcon),
  //!                       ),
  //!                     ],
  //!                   ),
  //!                 ),
  //!                 SizedBox(
  //!                   height: MediaQuery.of(context).size.height * 3 / 100,
  //!                 ),
  //!                 Expanded(
  //!                   child: SingleChildScrollView(
  //!                     child: Column(
  //!                       children: [
  //!                         Container(
  //!                           width: MediaQuery.of(context).size.width * 90 / 100,
  //!                           child: Wrap(
  //!                             runSpacing: 10,
  //!                             alignment: WrapAlignment.spaceBetween,
  //!                             children:
  //!                                 List.generate(categoryList.length, (index) {
  //!                               return Column(
  //!                                 children: [
  //!                                   Container(
  //!                                     width: MediaQuery.of(context).size.width *
  //!                                         24 /
  //!                                         100,
  //!                                     height:
  //!                                         MediaQuery.of(context).size.width *
  //!                                             24 /
  //!                                             100,
  //!                                     padding: const EdgeInsets.only(left: 15),
  //!                                     decoration: BoxDecoration(
  //!                                         image: DecorationImage(
  //!                                             image: categoryList[index]
  //!                                                         ['image'] !=
  //!                                                     null
  //!                                                 ? NetworkImage(
  //!                                                     "${AppConfigProvider.imageURL}${categoryList[index]['image']}")
  //!                                                 : const AssetImage(AppImage
  //!                                                         .imageFrameImage)
  //!                                                     as ImageProvider,
  //!                                             fit: BoxFit.cover),
  //!                                         borderRadius:
  //!                                             BorderRadius.circular(15)),
  //!                                   ),
  //!                                   SizedBox(
  //!                                       height:
  //!                                           MediaQuery.of(context).size.height *
  //!                                               1 /
  //!                                               100),
  //!                                   Text(
  //!                                     categoryList[index]['boat_name_english']
  //!                                         [language],
  //!                                     style: const TextStyle(
  //!                                         color: AppColor.primaryColor,
  //!                                         fontSize: 14,
  //!                                         fontWeight: FontWeight.w600,
  //!                                         fontFamily: AppFont.fontFamily),
  //!                                   ),
  //!                                 ],
  //!                               );
  //!                             }),
  //!                           ),
  //!                         ),
  //!                         SizedBox(
  //!                             height:
  //!                                 MediaQuery.of(context).size.height * 2 / 100),
  //!                       ],
  //!                     ),
  //!                   ),
  //!                 ),
  //!               ],
  //!             ),
  //!           );
  //!         },
  //!       );
  //!     },
  //!   );
  //! }

  //! void filterBottomSheet(BuildContext context, screenWidth) {
  //   showModalBottomSheet<void>(
  //     isScrollControlled: true,
  //     constraints: BoxConstraints.expand(
  //         width: screenWidth,
  //         height: MediaQuery.of(context).size.height * 60 / 100),
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(30),
  //         topRight: Radius.circular(30),
  //       ),
  //     ),
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return Directionality(
  //             textDirection:
  //                 language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
  //             child: Container(
  //               height: MediaQuery.of(context).size.height * 55 / 100,
  //               width: MediaQuery.of(context).size.width * 100 / 100,
  //               decoration: const BoxDecoration(
  //                 color: AppColor.secondaryColor,
  //                 borderRadius: BorderRadius.only(
  //                   topLeft: Radius.circular(30),
  //                   topRight: Radius.circular(30),
  //                 ),
  //               ),
  //               child: Column(
  //                 children: [
  //                   SizedBox(
  //                     height: MediaQuery.of(context).size.height * 4 / 100,
  //                   ),
  //                   SizedBox(
  //                     width: MediaQuery.of(context).size.width * 90 / 100,
  //                     child: Text(AppLanguage.selectActivityText[language],
  //                         style: TextStyle(
  //                             color: AppColor.primaryColor,
  //                             fontFamily: AppFont.fontFamily,
  //                             fontWeight: FontWeight.w700,
  //                             fontSize: screenWidth > 600 ? 20 : 16)),
  //                   ),
  //                   SizedBox(
  //                     height: MediaQuery.of(context).size.height * 3 / 100,
  //                   ),
  //                   Expanded(
  //                     child: SingleChildScrollView(
  //                       child: Column(
  //                         children: [
  //                           SizedBox(
  //                             width:
  //                                 MediaQuery.of(context).size.width * 90 / 100,
  //                             child: Wrap(
  //                               spacing: 15,
  //                               runSpacing: 10,
  //                               //! alignment: WrapAlignment.spaceBetween,
  //                               children: List.generate(activitiesList.length,
  //                                   (index) {
  //                                 return Column(
  //                                   children: [
  //                                     GestureDetector(
  //                                       onTap: () {
  //                                         // selectActivity = activitiesList[index]
  //                                         //     ['trip_type_id'];
  //                                         Navigator.pop(context);
  //                                         Navigator.push(
  //                                             context,
  //                                             MaterialPageRoute(
  //                                                 builder: (context) => Beaches(
  //                                                       status: 0,
  //                                                       activityId: activitiesList[
  //                                                                   index]
  //                                                               ['trip_type_id']
  //                                                           .toString(),
  //                                                       destinationId:
  //                                                           destinationId
  //                                                               .toString(),
  //                                                     )));
  //                                       },
  //                                       child: Container(
  //                                         width: MediaQuery.of(context)
  //                                                 .size
  //                                                 .width *
  //                                             26 /
  //                                             100,
  //                                         height: MediaQuery.of(context)
  //                                                 .size
  //                                                 .width *
  //                                             26 /
  //                                             100,
  //                                         padding:
  //                                             const EdgeInsets.only(left: 15),
  //                                         decoration: BoxDecoration(
  //                                             image: DecorationImage(
  //                                                 image: activitiesList[index]
  //                                                             ['image'] !=
  //                                                         null
  //                                                     ? NetworkImage(
  //                                                         "${AppConfigProvider.imageURL}${activitiesList[index]['image']}")
  //                                                     : const AssetImage(
  //                                                             AppImage
  //                                                                 .dummyIcon)
  //                                                         as ImageProvider,
  //                                                 fit: BoxFit.cover),
  //                                             borderRadius:
  //                                                 BorderRadius.circular(15)),
  //                                       ),
  //                                     ),
  //                                     SizedBox(
  //                                         height: MediaQuery.of(context)
  //                                                 .size
  //                                                 .height *
  //                                             1 /
  //                                             100),
  //                                     Container(
  //                                       width:
  //                                           MediaQuery.of(context).size.width *
  //                                               26 /
  //                                               100,
  //                                       alignment: Alignment.center,
  //                                       child: Text(
  //                                         activitiesList[index]['name_english']
  //                                             [language],
  //                                         textAlign: TextAlign.center,
  //                                         style: const TextStyle(
  //                                             color: AppColor.primaryColor,
  //                                             fontSize: 14,
  //                                             fontWeight: FontWeight.w600,
  //                                             fontFamily: AppFont.fontFamily),
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 );
  //                               }),
  //                             ),
  //                           ),
  //                           SizedBox(
  //                               height: MediaQuery.of(context).size.height *
  //                                   2 /
  //                                   100),
  //                         ],
  //                       ),
  //                     ),
  //                   )
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
}
