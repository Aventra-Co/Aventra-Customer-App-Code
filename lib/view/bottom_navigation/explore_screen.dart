import 'dart:convert';
import 'package:boatapp/view/property_screens/property_screen.dart';
import 'package:boatapp/view/property_screens/viewAll_property_screen.dart';
import 'package:boatapp/view/property_screens/property_detail_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
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

enum _CardSelection { none, sea, property }

class Explore extends StatefulWidget {
  static String routeName = './Explore';
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  // ── Carousel controllers — one per section ──────────────────────────────
  final CarouselController carouselController = CarouselController();
  final CarouselController _propertyCarouselController = CarouselController();
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  _CardSelection _selectedCard = _CardSelection.sea;

  String get _tabTypeParam {
    switch (_selectedCard) {
      case _CardSelection.property:
        return 'property';
      case _CardSelection.sea:
      case _CardSelection.none:
      default:
        return 'sea';
    }
  }

  // Carousel dot indices
  int status = 0;
  int _propertyCarouselStatus = 0;
  bool hasInitialized = false;
  bool isApiCalling = false;
  bool isLoading = true;
  // String _selectedPropertyType = '';
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
  List<dynamic> cityList = [];
  List<dynamic> citySearchList = [];

  // ── Property type tabs ────────────────────────────────────────────────
  int _selectedPropertyTab = 0;
  // Tab index 0 = "All" → always shows every property (no filtering)
  List<dynamic> propertyTypeTabs = [];
  // ─────────────────────────────────────────────────────────────────────

  List<dynamic> popularPropertiesList = [];

  /// Tab index 0 ("All") always returns the full list — no filtering.
  List<dynamic> get _tabFilteredProperties {
    if (_selectedPropertyTab == 0) return popularPropertiesList;
    final label = propertyTypeTabs[_selectedPropertyTab]['label'] as String;
    return popularPropertiesList.where((p) => p['type'] == label).toList();
  }

  String profileImage = '';
  int userId = 0;
  dynamic userDetails;
  double lat = 22.7196;
  double long = 75.8577;
  var weatherData;
  dynamic cityData = {};
  int notificationCount = 0;
  dynamic temperatureData = {};

  bool get _showSea =>
      _selectedCard == _CardSelection.none ||
      _selectedCard == _CardSelection.sea;

  bool get _showProperty =>
      _selectedCard == _CardSelection.none ||
      _selectedCard == _CardSelection.property;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => hasInitialized = true);
    });
    getUserDetails();
  }

  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");
    setState(() => isApiCalling = true);
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      userId = data['user_id'];
      profileImage = data["image"] ?? "NA";
    }
    setState(() => isApiCalling = false);
    homeApi(userId, tabType: _tabTypeParam);
    fetchLocation();
    getCities();
    setState(() {});
  }

  deeplinkingProp(BuildContext context, propertyAdId) async {
    var shareUrl =
        "${AppConfigProvider.apiUrl}deepLink?link=aventra://property_ad_id/${Uri.encodeComponent(propertyAdId.toString())}";
    Rect? shareOrigin;
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      shareOrigin = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    } else {
      final overlayRenderObject =
          Overlay.of(context).context.findRenderObject();
      if (overlayRenderObject is RenderBox) {
        shareOrigin = overlayRenderObject.localToGlobal(Offset.zero) &
            overlayRenderObject.size;
      }
    }
    if (shareOrigin != null) {
      await Share.share("Aventra App! $shareUrl",
          sharePositionOrigin: shareOrigin);
    } else {
      await Share.share("Aventra App! $shareUrl");
    }
  }

  Future<void> homeApi(userId, {required String tabType}) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}home_page_api?user_id=$userId&tab_type=$tabType");
    print("url $url");
    String token = AppConstant.token;
    Map<String, String> headers = {'Authorization': 'Bearer $token'};
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        if (res['success'] == true) {
          if (tabType == "sea") {
            var item = res['activity_arr'];
            activitiesList = (item != "NA") ? item : [];
            item = res['destination_arr'];
            popularDestinationList = (item != "NA") ? item : [];
            bottomSheetPopularDestinationList = (item != "NA") ? item : [];
            searchPopularDestinationList = (item != "NA") ? item : [];
            var hasTripDestinationData = res['destination_arr_active'];
            hasTripDestinationsList =
                (hasTripDestinationData != "NA") ? hasTripDestinationData : [];
            item = res['boat_arr'];
            categoryList = (item != "NA") ? item : [];
          } else {
            propertyTypeTabs = res['property_type_arr_active'] ?? [];
            popularPropertiesList = res['property_advertisement_arr'] ?? [];
          }
          notificationCount = res['notificationCount'];
          promotionsList = (res['banner_arr'] != "NA") ? res['banner_arr'] : [];
          _propertyBanners =
              (res['banner_arr'] != "NA") ? res['banner_arr'] : [];

          setState(() => isLoading = false);
        } else {
          if (res['active_status'] == 0) {
            localstorageclearbutton();
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          }
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  localstorageclearbutton() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userDetails');
    prefs.remove('password');
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Login()));
  }

  Future openUrl({required String url, bool inApp = false}) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (await canLaunch(url)) {
      await launch(url,
          forceSafariVC: inApp, forceWebView: inApp, enableJavaScript: true);
    }
  }

  Future<void> getDestinationAccordingActivity(
      userId, context, screenWidth) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_destination?user_id=$userId&activity_id=$selectActivity");
    String token = AppConstant.token;
    Map<String, String> headers = {'Authorization': 'Bearer $token'};
    setState(() => isApiCalling = true);
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        if (res['success'] == true) {
          var item = res['destination_arr'];
          filteredDestinationsList = (item != "NA") ? item : [];
          viewFilteredDestinationBottomSheet(
              context, screenWidth, selectActivity, () {
            setState(() => selectActivity = 0);
          });
          setState(() => isApiCalling = false);
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
          setState(() => isApiCalling = false);
        }
      } else {
        setState(() => isApiCalling = false);
      }
    } catch (e) {
      setState(() => isApiCalling = false);
    }
  }

  Future<void> getActivityAccordingDestination(
      context, screenWidth, selectedDestination) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_activity_by_destinations?user_id=$userId&destination_id=$selectedDestination");
    String token = AppConstant.token;
    Map<String, String> headers = {'Authorization': 'Bearer $token'};
    setState(() => isApiCalling = true);
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        if (res['success'] == true) {
          var item = res['activity_arr'];
          filteredActivityList = (item != "NA") ? item : [];
          viewFilteredActivitiesBottomSheet(
              context, screenWidth, selectedDestination, () {});
          setState(() => isApiCalling = false);
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
          setState(() => isApiCalling = false);
        }
      } else {
        setState(() => isApiCalling = false);
      }
    } catch (e) {
      setState(() => isApiCalling = false);
    }
  }

  var refreshKey = GlobalKey<RefreshIndicatorState>();

  Future<Null> _refreshPage() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      selectActivity = 0;
      _selectedCard = _CardSelection.sea;
    });
    getUserDetails();
    return null;
  }

  searchResultCountry(String query) {
    var results1 = searchPopularDestinationList
        .where((value) => value['destination_english'][language]
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
    bottomSheetPopularDestinationList = [];
    bottomSheetPopularDestinationList = results1;
    setState(() {});
  }

  searchResultCity(String query) {
    var results1 = citySearchList
        .where((value) => value['city_name'][language]
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
    cityList = [];
    cityList = results1;
    setState(() {});
  }

  void fetchLocation() async {
    try {
      Position? position = await getCurrentLocation();
      if (position != null) {
        lat = position.latitude;
        long = position.longitude;
        fetchWeather(latitude: lat, longitude: long);
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      SnackBarToastMessage.showSnackBar(
          context, 'Location services are disabled.');
      return Future.error('Location services are disabled.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        SnackBarToastMessage.showSnackBar(
            context, 'Location permissions are denied');
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      SnackBarToastMessage.showSnackBar(
          context, 'Location permissions are permanently denied');
      return Future.error('Location permissions are permanently denied');
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<Map<String, dynamic>?> fetchWeather(
      {required double latitude, required double longitude}) async {
    final uri = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude&hourly=temperature_2m,windspeed_10m,winddirection_10m,relativehumidity_2m,weathercode,precipitation,cloudcover&wind_speed_unit=kmh&timezone=auto&apikey=${AppConstant.weatherKey}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
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
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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

  String getWeatherIcon(int weatherCode) {
    switch (weatherCode) {
      case 0:
      case 1:
        return '☀️';
      case 2:
      case 3:
        return '⛅';
      case 45:
      case 48:
        return '🌫️';
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
        return '🌧️';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return '❄️';
      case 95:
      case 96:
      case 99:
        return '⛈️';
      default:
        return '🌤️';
    }
  }

  Map<String, dynamic>? getCurrentWeatherData(
      Map<String, dynamic> weatherData) {
    try {
      final now = DateTime.now();
      final currentHour = now.hour;
      final today = DateTime(now.year, now.month, now.day);
      final hourlyData = weatherData['hourly'] as Map<String, dynamic>?;
      if (hourlyData == null) return null;
      final timeArray = hourlyData['time'] as List<dynamic>?;
      final temperatureArray = hourlyData['temperature_2m'] as List<dynamic>?;
      final weatherCodeArray = hourlyData['weathercode'] as List<dynamic>?;
      final windSpeedArray = hourlyData['windspeed_10m'] as List<dynamic>?;
      final windDirectionArray =
          hourlyData['winddirection_10m'] as List<dynamic>?;
      final humidityArray = hourlyData['relativehumidity_2m'] as List<dynamic>?;
      final precipitationArray = hourlyData['precipitation'] as List<dynamic>?;
      final cloudCoverArray = hourlyData['cloudcover'] as List<dynamic>?;
      if (timeArray == null || temperatureArray == null) return null;
      int? currentIndex;
      for (int i = 0; i < timeArray.length; i++) {
        final dateTime = DateTime.parse(timeArray[i] as String);
        if (dateTime.year == today.year &&
            dateTime.month == today.month &&
            dateTime.day == today.day &&
            dateTime.hour == currentHour) {
          currentIndex = i;
          break;
        }
      }
      if (currentIndex == null) return null;
      double? safeToDouble(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        return null;
      }

      final currentTemperature = safeToDouble(temperatureArray[currentIndex]);
      final weatherCode = weatherCodeArray?[currentIndex] as int? ?? 0;
      if (currentTemperature == null) return null;
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
        'windSpeed': safeToDouble(windSpeedArray?[currentIndex]),
        'windSpeedUnit': 'km/h',
        'windDirection': safeToDouble(windDirectionArray?[currentIndex]),
        'humidity': safeToDouble(humidityArray?[currentIndex]),
        'humidityUnit': '%',
        'precipitation': safeToDouble(precipitationArray?[currentIndex]) ?? 0.0,
        'precipitationUnit': 'mm',
        'cloudCover': safeToDouble(cloudCoverArray?[currentIndex]),
        'cloudCoverUnit': '%',
        'timestamp': timeArray[currentIndex],
      };
    } catch (e) {
      return null;
    }
  }

  //!-----------------GET CITIES API CALL-----------------//!
  Future<void> getCities() async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}fetch_city_by_country?country_id=0");
    print("url $url");

    Map<String, String> headers = ({
      'Content-Type': 'application/json',
    });
    try {
      final http.Response response = await http.get(
        url,
        headers: headers,
      );
      print("Runn");
      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print(res);
        if (res['success'] == true) {
          print(response.statusCode);
          var item = res['city_arr'];
          print("item $item");
          if (item != "NA") {
            setState(() {
              cityList = item;
              citySearchList = item;
            });
          } else {
            setState(() {
              cityList = [];
              citySearchList = [];
            });
          }

          setState(() {
            isApiCalling = false;
          });
        } else {
          if (res['active_status'] == 0) {
            Future.delayed(const Duration(milliseconds: 100), () async {});
          }
          setState(() {
            isApiCalling = false;
          });
        }
      } else {
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isApiCalling,
        opacity: 0.5,
        child: _buildUIScreen(context));
  }

  // ────────────────────────────────────────────────────────────────────────
  // MAIN SCREEN
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildUIScreen(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) =>
          SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
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
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: [
                    const NoInternetBanner(),
                    isLoading
                        ? exploreShimmerEffect(context)
                        : Expanded(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  // Header
                                  _buildHeader(context, screenWidth),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              4 /
                                              100),

                                  // Sea & Property selection cards
                                  _buildCategoryCards(context, screenWidth),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              4 /
                                              100),

                                  // ══════════════ SEA SECTION ══════════════
                                  if (_showSea && activitiesList.isNotEmpty)
                                    _buildActivityTabs(context, screenWidth),
                                  if (_showSea && activitiesList.isNotEmpty)
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                2 /
                                                100),
                                  if (_showSea && promotionsList.isNotEmpty)
                                    _buildPromotionsSection(
                                        context, screenWidth),
                                  if (_showSea && promotionsList.isNotEmpty)
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                3 /
                                                100),
                                  if (_showSea)
                                    _buildPopularDestinationsHeader(
                                        context, screenWidth),
                                  if (_showSea)
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                2 /
                                                100),
                                  if (_showSea &&
                                      hasTripDestinationsList.isNotEmpty)
                                    _buildDestinationsList(
                                        context, screenWidth),
                                  if (_showSea &&
                                      hasTripDestinationsList.isEmpty)
                                    _buildNoDestinationMsg(context),

                                  // ══════════════ PROPERTY SECTION ══════════
                                  // 1) Property type tabs (pill row)
                                  isLoading
                                      ? exploreShimmerEffect(context)
                                      : Column(
                                          children: [
                                            if (_showProperty)
                                              _buildPropertyTypeTabs(
                                                  context, screenWidth),
                                            if (_showProperty)
                                              SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      2 /
                                                      100),

                                            // 2) Property banner carousel (uses local asset images)
                                            if (_showProperty)
                                              _buildPropertyCarousel(
                                                  context, screenWidth),
                                            if (_showProperty)
                                              SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      3 /
                                                      100),

                                            // 3) Popular properties horizontal list (filtered by tab)
                                            if (_showProperty)
                                              _buildPopularPropertiesSection(
                                                  context),

                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    2 /
                                                    100),
                                          ],
                                        )
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

  // ────────────────────────────────────────────────────────────────────────
  // HEADER
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, double screenWidth) {
    return Container(
      width: screenWidth > 600
          ? MediaQuery.of(context).size.width * 95 / 100
          : MediaQuery.of(context).size.width * 90 / 100,
      margin: const EdgeInsets.only(top: 15),
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 5 / 100),
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage(AppImage.homeBackImage), fit: BoxFit.cover),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 85 / 100,
            margin: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 12 / 100,
                  height: MediaQuery.of(context).size.width * 12 / 100,
                  child: (profileImage != 'NA' && !isGuest)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.network(
                              "${AppConfigProvider.imageURL}$profileImage",
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(color: Colors.grey.shade300));
                          }),
                        )
                      : Image.asset(AppImage.profilePlaceholderImage,
                          fit: BoxFit.cover),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => notificationCount = 0);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationScreen()));
                  },
                  child: Stack(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 10 / 100,
                        height: MediaQuery.of(context).size.width * 10 / 100,
                        child: Image.asset(AppImage.deactiveNotificationIcon),
                      ),
                      if (notificationCount != 0)
                        Positioned(
                          right: 0,
                          child: Container(
                            alignment: Alignment.center,
                            width: screenWidth * 5 / 100,
                            height: screenWidth * 5 / 100,
                            decoration: BoxDecoration(
                                color: AppColor.redcolor,
                                borderRadius: BorderRadius.circular(100)),
                            child: Text(
                                notificationCount > 9
                                    ? "9+"
                                    : "$notificationCount",
                                style: const TextStyle(
                                    fontFamily: AppFont.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColor.secondaryColor)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 2 / 100),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const WeatherScreen())),
            child: Container(
              color: Colors.transparent,
              width: MediaQuery.of(context).size.width * 85 / 100,
              child: Row(
                children: [
                  Text(AppConstant.weatherIcon,
                      style: const TextStyle(
                          color: AppColor.secondaryColor,
                          fontSize: 34,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.fontFamily)),
                  SizedBox(width: MediaQuery.of(context).size.width * 2 / 100),
                  Text(AppConstant.temperature,
                      style: const TextStyle(
                          color: AppColor.secondaryColor,
                          fontSize: 34,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.fontFamily)),
                  Text(AppConstant.unit,
                      style: const TextStyle(
                          color: AppColor.secondaryColor,
                          fontSize: 34,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.fontFamily)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const WeatherScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColor.secondaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(5)),
              child: Text(AppConstant.weatherDesc,
                  style: const TextStyle(
                      color: AppColor.secondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFont.fontFamily)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 1 / 100),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // CATEGORY CARDS
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryCards(BuildContext context, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _categoryCard(
          context: context,
          image: AppImage.seaImage,
          title: AppLanguage.seaText[language],
          subtitle: AppLanguage.seaCardText[language],
          isSelected: _selectedCard == _CardSelection.sea,
          onTap: () => setState(() {
            _selectedCard = _CardSelection.sea;
            homeApi(userId, tabType: _tabTypeParam);
            // _selectedCard = _selectedCard == _CardSelection.sea
            //     ? _CardSelection.none
            //     : _CardSelection.sea;
          }),
        ),
        _categoryCard(
          context: context,
          image: AppImage.propertyImage,
          title: AppLanguage.propertyText[language],
          subtitle: AppLanguage.propertyCardText[language],
          isSelected: _selectedCard == _CardSelection.property,
          onTap: () => setState(() {
            _selectedCard = _CardSelection.property;
            homeApi(userId, tabType: _tabTypeParam);
            // _selectedCard = _selectedCard == _CardSelection.property
            //     ? _CardSelection.none
            //     : _CardSelection.property;
          }),
        ),
      ],
    );
  }

  Widget _categoryCard({
    required BuildContext context,
    required String image,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColor.themeColor, width: 3)
              : Border.all(color: Colors.transparent, width: 3),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppColor.themeColor.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 1)
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Image.asset(image,
                  width: MediaQuery.of(context).size.width * 45 / 100,
                  height: MediaQuery.of(context).size.height * 15 / 100,
                  fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppFont.fontFamily)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFont.fontFamily)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // PROPERTY: TYPE TABS  ← NEW
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildPropertyTypeTabs(BuildContext context, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scrollable pill tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(propertyTypeTabs.length, (index) {
              final tab = propertyTypeTabs[index];
              final isSelected = _selectedPropertyTab ==
                  propertyTypeTabs[index]['property_type_id'];
              return Padding(
                padding: EdgeInsetsDirectional.only(
                  start: index == 0 ? screenWidth * 0.05 : 8,
                  end: index == propertyTypeTabs.length - 1
                      ? screenWidth * 0.05
                      : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPropertyTab =
                        propertyTypeTabs[index]['property_type_id']);
                    showAllCities(context, screenWidth,
                        propertyTypeTabs[index]['property_type_id'], () {
                      setState(() => _selectedPropertyTab = 0);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColor.themeColor
                          : AppColor.boxshadowColor,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tab['property_type_name'][language] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColor.secondaryColor
                                  : AppColor.primaryColor,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontFamily: AppFont.fontFamily,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // PROPERTY: BANNER CAROUSEL — uses local property images (asset-based)
  // ────────────────────────────────────────────────────────────────────────

  /// Static banner slides using the same property images already in the app.
  /// Swap these out with a real API list when the backend is ready.
  List<dynamic> _propertyBanners = [];

  Widget _buildPropertyCarousel(BuildContext context, double screenWidth) {
    return Column(
      children: [
        SizedBox(
          width: screenWidth > 600
              ? MediaQuery.of(context).size.width * 95 / 100
              : MediaQuery.of(context).size.width * 90 / 100,
          child: Text(AppLanguage.promotionsText[language],
              style: const TextStyle(
                  color: AppColor.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFont.fontFamily)),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 2 / 100),
        Center(
          child: Column(
            children: [
              CarouselSlider(
                items: _propertyBanners.asMap().entries.map((entry) {
                  int index = entry.key;
                  bool isCenter =
                      hasInitialized && index == _propertyCarouselStatus;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: EdgeInsets.only(
                        top: isCenter ? 0 : 10,
                        bottom: isCenter ? (screenWidth > 600 ? 100 : 60) : 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _handlePromotionTap(index),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.75,
                              height: screenWidth > 600
                                  ? MediaQuery.of(context).size.height * 0.35
                                  : MediaQuery.of(context).size.height * 0.28,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                    '${AppConfigProvider.imageURL}${_propertyBanners[index]['image']}',
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: Container(
                                          color: Colors.grey.shade300));
                                }),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 18,
                            left: 20,
                            child: GestureDetector(
                              onTap: () => _handlePromotionTap(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 15),
                                decoration: BoxDecoration(
                                    color: AppColor.secondaryColor,
                                    borderRadius: BorderRadius.circular(17)),
                                child: Text(AppLanguage.exploreText[language],
                                    style: const TextStyle(
                                        color: AppColor.themeColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: AppFont.fontFamily)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                carouselController: _propertyCarouselController,
                options: CarouselOptions(
                  initialPage: _propertyCarouselStatus,
                  height: screenWidth > 600
                      ? MediaQuery.of(context).size.height * 0.35
                      : MediaQuery.of(context).size.height * 0.28,
                  viewportFraction: 0.7,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                  onPageChanged: (index, reason) =>
                      setState(() => _propertyCarouselStatus = index),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(promotionsList.length, (index) {
                  return GestureDetector(
                    onTap: () => carouselController.animateToPage(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        height: MediaQuery.of(context).size.width * 2 / 100,
                        width: MediaQuery.of(context).size.width * 2 / 100,
                        decoration: BoxDecoration(
                            color: _propertyCarouselStatus == index
                                ? Colors.blue
                                : Colors.grey,
                            shape: BoxShape.circle),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // SEA: ACTIVITY TABS
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildActivityTabs(BuildContext context, double screenWidth) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          children: List.generate(activitiesList.length, (index) {
            return Padding(
              padding: language == 0
                  ? EdgeInsets.only(
                      left: index == 0 ? (screenWidth > 600 ? 20 : 18) : 10,
                      right: index == activitiesList.length - 1 ? 10 : 0)
                  : EdgeInsets.only(
                      right: index == 0 ? (screenWidth > 600 ? 20 : 18) : 10,
                      left: index == activitiesList.length - 1 ? 10 : 0),
              child: GestureDetector(
                onTap: () {
                  if (selectActivity == activitiesList[index]['trip_type_id']) {
                    setState(() => selectActivity = 0);
                  } else {
                    setState(() =>
                        selectActivity = activitiesList[index]['trip_type_id']);
                    getDestinationAccordingActivity(
                        userId, context, screenWidth);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: selectActivity ==
                              activitiesList[index]['trip_type_id']
                          ? AppColor.themeColor
                          : AppColor.boxshadowColor,
                      borderRadius: BorderRadius.circular(50)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 5 / 100,
                        height: MediaQuery.of(context).size.width * 5 / 100,
                        child: Image.network(
                            "${AppConfigProvider.imageURL}${activitiesList[index]['vector_image']}"),
                      ),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 1 / 100),
                      Text(activitiesList[index]['name_english'][language],
                          style: TextStyle(
                              color: selectActivity ==
                                      activitiesList[index]['trip_type_id']
                                  ? AppColor.secondaryColor
                                  : AppColor.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFont.fontFamily)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // SEA: PROMOTIONS CAROUSEL
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildPromotionsSection(BuildContext context, double screenWidth) {
    return Column(
      children: [
        SizedBox(
          width: screenWidth > 600
              ? MediaQuery.of(context).size.width * 95 / 100
              : MediaQuery.of(context).size.width * 90 / 100,
          child: Text(AppLanguage.promotionsText[language],
              style: const TextStyle(
                  color: AppColor.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFont.fontFamily)),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 2 / 100),
        Center(
          child: Column(
            children: [
              CarouselSlider(
                items: promotionsList.asMap().entries.map((entry) {
                  int index = entry.key;
                  bool isCenter = hasInitialized && index == status;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: EdgeInsets.only(
                        top: isCenter ? 0 : 10,
                        bottom: isCenter ? (screenWidth > 600 ? 100 : 60) : 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _handlePromotionTap(index),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.75,
                              height: screenWidth > 600
                                  ? MediaQuery.of(context).size.height * 0.35
                                  : MediaQuery.of(context).size.height * 0.28,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                    '${AppConfigProvider.imageURL}${promotionsList[index]['image']}',
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: Container(
                                          color: Colors.grey.shade300));
                                }),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 18,
                            left: 20,
                            child: GestureDetector(
                              onTap: () => _handlePromotionTap(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 15),
                                decoration: BoxDecoration(
                                    color: AppColor.secondaryColor,
                                    borderRadius: BorderRadius.circular(17)),
                                child: Text(AppLanguage.exploreText[language],
                                    style: const TextStyle(
                                        color: AppColor.themeColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: AppFont.fontFamily)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                carouselController: carouselController,
                options: CarouselOptions(
                  initialPage: status,
                  height: screenWidth > 600
                      ? MediaQuery.of(context).size.height * 0.35
                      : MediaQuery.of(context).size.height * 0.28,
                  viewportFraction: 0.7,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                  onPageChanged: (index, reason) =>
                      setState(() => status = index),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(promotionsList.length, (index) {
                  return GestureDetector(
                    onTap: () => carouselController.animateToPage(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        height: MediaQuery.of(context).size.width * 2 / 100,
                        width: MediaQuery.of(context).size.width * 2 / 100,
                        decoration: BoxDecoration(
                            color: status == index ? Colors.blue : Colors.grey,
                            shape: BoxShape.circle),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handlePromotionTap(int index) {
    if (promotionsList[index]['type'] == 0) {
      if (promotionsList[index]['link'] != null) {
        openUrl(url: promotionsList[index]['link']);
      }
    } else if (promotionsList[index]['type'] == 1) {
      if (promotionsList[index]['advertisement_type'] == 0) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PrivateTripDetailsScreen(
                    tripId: promotionsList[index]['trip_id'].toString())));
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PublicTripDetailsScreen(
                    tripId: promotionsList[index]['trip_id'].toString())));
      }
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // SEA: POPULAR DESTINATIONS HEADER
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildPopularDestinationsHeader(
      BuildContext context, double screenWidth) {
    return SizedBox(
      width: screenWidth > 600
          ? MediaQuery.of(context).size.width * 95 / 100
          : MediaQuery.of(context).size.width * 90 / 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppLanguage.popularDestinationText[language],
              style: const TextStyle(
                  color: AppColor.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFont.fontFamily)),
          if (popularDestinationList.isNotEmpty)
            GestureDetector(
              onTap: () => viewMoreDestinationBottomSheet(context, screenWidth),
              child: Text(AppLanguage.viewMoreText[language],
                  style: const TextStyle(
                      color: AppColor.themeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFont.fontFamily)),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // SEA: DESTINATIONS LIST
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildDestinationsList(BuildContext context, double screenWidth) {
    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              children: List.generate(hasTripDestinationsList.length, (index) {
                return Container(
                  padding: language == 1
                      ? EdgeInsets.only(
                          right:
                              index == 0 ? (screenWidth > 600 ? 20 : 18) : 10,
                          left: index == hasTripDestinationsList.length - 1
                              ? 10
                              : 0)
                      : EdgeInsets.only(
                          left: index == 0 ? (screenWidth > 600 ? 20 : 18) : 10,
                          right: index == hasTripDestinationsList.length - 1
                              ? 10
                              : 0),
                  child: GestureDetector(
                    onTap: () {
                      if (selectActivity == 0) {
                        getActivityAccordingDestination(context, screenWidth,
                            hasTripDestinationsList[index]['destination_id']);
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Beaches(
                                    status: 0,
                                    activityId: selectActivity.toString(),
                                    destinationId:
                                        hasTripDestinationsList[index]
                                                ['destination_id']
                                            .toString(),
                                    toOpen: "")));
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 40 / 100,
                      height: MediaQuery.of(context).size.height * 25 / 100,
                      padding: language == 1
                          ? const EdgeInsets.only(right: 15)
                          : const EdgeInsets.only(left: 15),
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: hasTripDestinationsList[index]
                                          ['destination_image'] !=
                                      null
                                  ? NetworkImage(
                                      "${AppConfigProvider.imageURL}${hasTripDestinationsList[index]['destination_image']}")
                                  : const AssetImage(AppImage.imageFrameImage)
                                      as ImageProvider,
                              fit: BoxFit.cover),
                          borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              hasTripDestinationsList[index]
                                      ['destination_english'][language] ??
                                  "",
                              style: const TextStyle(
                                  color: AppColor.secondaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppFont.fontFamily)),
                          if (hasTripDestinationsList[index]['rating']
                                  .toString() !=
                              "0.00")
                            Container(
                              width: screenWidth > 600
                                  ? MediaQuery.of(context).size.width * 12 / 100
                                  : MediaQuery.of(context).size.width *
                                      16 /
                                      100,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                  color:
                                      AppColor.secondaryColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(25)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: screenWidth > 600
                                        ? MediaQuery.of(context).size.width *
                                            3 /
                                            100
                                        : MediaQuery.of(context).size.width *
                                            4 /
                                            100,
                                    height: MediaQuery.of(context).size.width *
                                        4 /
                                        100,
                                    child: Image.asset(AppImage.ratingIcon),
                                  ),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          1 /
                                          100),
                                  SizedBox(
                                    width: screenWidth > 600
                                        ? MediaQuery.of(context).size.width *
                                            6 /
                                            100
                                        : MediaQuery.of(context).size.width *
                                            8 /
                                            100,
                                    child: Text(
                                        hasTripDestinationsList[index]['rating']
                                            .toString(),
                                        style: const TextStyle(
                                            color: AppColor.secondaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: AppFont.fontFamily)),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 2 / 100),
      ],
    );
  }

  Widget _buildNoDestinationMsg(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width * 90 / 100,
          child: Text(AppLanguage.noDestinationAvailableText[language],
              style: const TextStyle(
                  fontFamily: AppFont.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColor.primaryColor)),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 2 / 100),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // PROPERTY: POPULAR PROPERTIES LIST (filtered by selected tab)
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildPopularPropertiesSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLanguage.mostPopularpropertiesText[language],
                style: const TextStyle(
                    color: AppColor.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFont.fontFamily),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const PropertyHomeScreen(initialView: 'Grid'))),
                child: Text(AppLanguage.viewMoreText[language],
                    style: const TextStyle(
                        color: AppColor.themeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFont.fontFamily)),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 1.5 / 100),
        SizedBox(
          height: size.height * 0.28,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsetsDirectional.only(
              start: size.width * 0.05,
              end: size.width * 0.05,
            ),
            itemCount: popularPropertiesList.length,
            itemBuilder: (context, index) {
              final property = popularPropertiesList[index];
              final realIndex = popularPropertiesList.indexOf(property);
              return Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index == popularPropertiesList.length - 1
                      ? 0
                      : size.width * 0.03,
                ),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PropertyDetailsScreen(
                                propertyAdId: popularPropertiesList[index]
                                    ['property_ad_id'],
                              ))),
                  child: Container(
                    width: size.width * 0.45,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: property['image_path'] != null
                                ? NetworkImage(
                                    "${AppConfigProvider.imageURL}${property['image_path']}")
                                : const AssetImage(AppImage.dummyIcon)
                                    as ImageProvider,
                            fit: BoxFit.cover),
                        borderRadius: BorderRadius.circular(18)),
                    child: Stack(
                      children: [
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7)
                                ]),
                          ),
                        ),
                        // Price badge top-left
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: const BoxDecoration(
                              color: AppColor.themeColor,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLanguage.startingFromText[language],
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: AppFont.fontFamily,
                                        color: Colors.white)),
                                Text("${property['starting_price'] ?? ""} KWD",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: AppFont.fontFamily,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                        // Remain badge top-right
                        Positioned(
                          top: 6,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              deeplinkingProp(
                                  context, property['property_ad_id']);
                            },
                            child: Image.asset(
                              AppImage.shareIcon,
                              width: size.width * 0.06,
                              height: size.width * 0.06,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property['property_name_english'] ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: AppFont.fontFamily,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${AppLanguage.cityText[language]} \u2022 ${property['city_name'][language] ?? ""}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFont.fontFamily,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${AppLanguage.propertyTypeText[language]} \u2022 ${property['property_type_name'][language] ?? ""}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFont.fontFamily,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (property['rating'] != 0)
                                    Container(
                                      width: screenWidth > 600
                                          ? MediaQuery.of(context).size.width *
                                              10 /
                                              100
                                          : MediaQuery.of(context).size.width *
                                              11 /
                                              100,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 2),
                                      decoration: BoxDecoration(
                                          color: AppColor.secondaryColor
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(25)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: screenWidth > 600
                                                ? MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    2 /
                                                    100
                                                : MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    3 /
                                                    100,
                                            height: screenWidth > 600
                                                ? MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    2 /
                                                    100
                                                : MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    3 /
                                                    100,
                                            child: Image.asset(
                                                AppImage.ratingIcon),
                                          ),
                                          SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  1 /
                                                  100),
                                          Text(
                                            property['rating'].toString(),
                                            style: const TextStyle(
                                                color: AppColor.secondaryColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: AppFont.fontFamily),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          1 /
                                          100),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 5),
                                    decoration: BoxDecoration(
                                      color: AppColor.secondaryColor
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Text(
                                      "${"${(property['max_adult'] ?? 0) + (property['max_child'] ?? 0)}"} ${AppLanguage.guestsext[language]}",
                                      style: const TextStyle(
                                          color: AppColor.secondaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppFont.fontFamily),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Image.asset(
                                      (popularPropertiesList[realIndex]
                                                  ['favourite_status'] ==
                                              1)
                                          ? AppImage.removeFavouriteIcon
                                          : AppImage.addFavouriteIcons,
                                      width: size.width * 0.06,
                                      height: size.width * 0.06,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: size.height * 0.02),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // BOTTOM SHEETS
  // ────────────────────────────────────────────────────────────────────────
  setSearch(BuildContext context, screenWidth) {
    setState(() => isSearch = !isSearch);
    Navigator.pop(context);
    viewMoreDestinationBottomSheet(context, screenWidth);
  }

  setCitySearch(BuildContext context, screenWidth, propertyAdId) {
    setState(() => isSearch = !isSearch);
    Navigator.pop(context);
    showAllCities(context, screenWidth, propertyAdId, () {});
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
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      context: contextUp,
      backgroundColor: AppColor.secondaryColor,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: ((context, setState) {
          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Padding(
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
                          topRight: Radius.circular(30))),
                  child: Column(children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 4 / 100),
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
                          GestureDetector(
                            onTap: () => setSearch(context, screenWidth),
                            child: SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    12 /
                                    100,
                                height: MediaQuery.of(context).size.width *
                                    12 /
                                    100,
                                child: Image.asset(AppImage.searchRoundIcon)),
                          ),
                        ],
                      ),
                    ),
                    if (isSearch)
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 80 / 100,
                          height: MediaQuery.of(context).size.height * 6 / 100,
                          child: TextFormField(
                            readOnly: false,
                            style: AppConstant.textFilledHeading,
                            textAlignVertical: TextAlignVertical.center,
                            keyboardType: TextInputType.name,
                            autofocus: isSearch,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(AppImage.searchIcon1,
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
                                                100),
                                  ]),
                              border: const OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: AppColor.textColor),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25))),
                              enabledBorder: const OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: AppColor.textColor),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25))),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: AppColor.textColor),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25))),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 15),
                              filled: false,
                              counterText: '',
                              hintText: AppLanguage.searchInputText[language],
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
                        height: MediaQuery.of(context).size.height * 3 / 100),
                    Expanded(
                        child: SingleChildScrollView(
                            child: Column(children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        alignment: Alignment.center,
                        child: Wrap(
                          spacing: 15,
                          runSpacing: 12,
                          children: List.generate(
                              bottomSheetPopularDestinationList.length,
                              (index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                if (selectActivity == 0) {
                                  getActivityAccordingDestination(
                                      contextUp,
                                      screenWidth,
                                      bottomSheetPopularDestinationList[index]
                                          ['destination_id']);
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
                                              toOpen: "")));
                                }
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width *
                                    27 /
                                    100,
                                height: MediaQuery.of(context).size.height *
                                    18 /
                                    100,
                                padding: const EdgeInsets.only(left: 15),
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: bottomSheetPopularDestinationList[
                                                        index]
                                                    ['destination_image'] !=
                                                null
                                            ? NetworkImage(
                                                "${AppConfigProvider.imageURL}${bottomSheetPopularDestinationList[index]['destination_image']}")
                                            : const AssetImage(
                                                    AppImage.dummyIcon)
                                                as ImageProvider,
                                        fit: BoxFit.cover),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: language == 0
                                      ? CrossAxisAlignment.start
                                      : CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        bottomSheetPopularDestinationList[index]
                                                    ['destination_english']
                                                [language] ??
                                            "",
                                        style: const TextStyle(
                                            color: AppColor.secondaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: AppFont.fontFamily)),
                                    if (bottomSheetPopularDestinationList[index]
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        decoration: BoxDecoration(
                                            color: AppColor.secondaryColor
                                                .withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(25)),
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: screenWidth > 600
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        3 /
                                                        100
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        4 /
                                                        100,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    4 /
                                                    100,
                                                child: Image.asset(
                                                    AppImage.ratingIcon),
                                              ),
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      1 /
                                                      100),
                                              SizedBox(
                                                width: screenWidth > 600
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        6 /
                                                        100
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        8 /
                                                        100,
                                                child: Text(
                                                    bottomSheetPopularDestinationList[
                                                            index]['rating']
                                                        .toString(),
                                                    style: const TextStyle(
                                                        color: AppColor
                                                            .secondaryColor,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily: AppFont
                                                            .fontFamily)),
                                              ),
                                            ]),
                                      ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
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
                          height: MediaQuery.of(context).size.height * 2 / 100),
                    ]))),
                  ]),
                ),
              ),
            ),
          );
        }));
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
                topLeft: Radius.circular(30), topRight: Radius.circular(30))),
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
                          topRight: Radius.circular(30))),
                  child: Column(children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 4 / 100),
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        child: Text(AppLanguage.selectDestinationText[language],
                            style: TextStyle(
                                color: AppColor.primaryColor,
                                fontFamily: AppFont.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: screenWidth > 600 ? 20 : 16))),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 3 / 100),
                    Expanded(
                        child: SingleChildScrollView(
                            child: Column(children: [
                      if (filteredDestinationsList.isNotEmpty)
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 90 / 100,
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
                                              toOpen: "")));
                                  setState(() => selectActivity = 0);
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width *
                                      27 /
                                      100,
                                  height: MediaQuery.of(context).size.height *
                                      18 /
                                      100,
                                  padding: const EdgeInsets.only(left: 15),
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: filteredDestinationsList[index]
                                                      ['destination_image'] !=
                                                  null
                                              ? NetworkImage(
                                                  "${AppConfigProvider.imageURL}${filteredDestinationsList[index]['destination_image']}")
                                              : const AssetImage(
                                                      AppImage.dummyIcon)
                                                  as ImageProvider,
                                          fit: BoxFit.cover),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: language == 0
                                          ? CrossAxisAlignment.start
                                          : CrossAxisAlignment.end,
                                      children: [
                                        Padding(
                                            padding: const EdgeInsets.all(8.0),
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
                                                        AppFont.fontFamily))),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                2 /
                                                100),
                                      ]),
                                ),
                              );
                            }),
                          ),
                        ),
                      if (filteredDestinationsList.isEmpty)
                        Column(children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height *
                                  15 /
                                  100),
                          SizedBox(
                              width: screenWidth * 75 / 100,
                              child: Text(
                                  AppLanguage.destinationNoDataMsg[language],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontFamily: AppFont.fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.primaryColor))),
                        ]),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 2 / 100),
                    ]))),
                  ]),
                ),
              ),
            );
          });
        }).then((_) => onDismiss());
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
                topLeft: Radius.circular(30), topRight: Radius.circular(30))),
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
                          topRight: Radius.circular(30))),
                  child: Column(children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 4 / 100),
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        child: Text(AppLanguage.selectActivityText[language],
                            style: TextStyle(
                                color: AppColor.primaryColor,
                                fontFamily: AppFont.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: screenWidth > 600 ? 20 : 16))),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 3 / 100),
                    Expanded(
                        child: SingleChildScrollView(
                            child: Column(children: [
                      if (filteredActivityList.isNotEmpty)
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 90 / 100,
                          child: Wrap(
                            spacing: 15,
                            runSpacing: 12,
                            children: List.generate(filteredActivityList.length,
                                (index) {
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
                                              toOpen: "")));
                                  setState(() => selectActivity = 0);
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width *
                                      27 /
                                      100,
                                  height: MediaQuery.of(context).size.height *
                                      18 /
                                      100,
                                  padding: const EdgeInsets.only(left: 15),
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: filteredActivityList[index]
                                                      ['image'] !=
                                                  null
                                              ? NetworkImage(
                                                  "${AppConfigProvider.imageURL}${filteredActivityList[index]['image']}")
                                              : const AssetImage(
                                                      AppImage.dummyIcon)
                                                  as ImageProvider,
                                          fit: BoxFit.cover),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
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
                                                          AppFont.fontFamily))),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                2 /
                                                100),
                                      ]),
                                ),
                              );
                            }),
                          ),
                        ),
                      if (filteredActivityList.isEmpty)
                        Column(children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height *
                                  15 /
                                  100),
                          SizedBox(
                              width: screenWidth * 75 / 100,
                              child: Text(
                                  AppLanguage.activityNoDataMsg[language],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontFamily: AppFont.fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.primaryColor))),
                        ]),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 2 / 100),
                    ]))),
                  ]),
                ),
              ),
            );
          });
        }).then((_) => onDismiss());
  }

  // ── Show All Cities ──────────────────────────────────────────────────────
  void showAllCities(BuildContext contextUp, screenWidth, int propertyAdId,
      VoidCallback onDismiss) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      constraints: BoxConstraints.expand(
          width: screenWidth,
          height: isSearch
              ? MediaQuery.of(contextUp).size.height * 96 / 100
              : MediaQuery.of(contextUp).size.height * 60 / 100),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
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
                            topRight: Radius.circular(30))),
                    child: Column(children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 4 / 100),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLanguage.selectCityText[language],
                                style: TextStyle(
                                    color: AppColor.primaryColor,
                                    fontFamily: AppFont.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: screenWidth > 600 ? 20 : 16)),
                            GestureDetector(
                              onTap: () => setCitySearch(
                                  context, screenWidth, propertyAdId),
                              child: SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      12 /
                                      100,
                                  height: MediaQuery.of(context).size.width *
                                      12 /
                                      100,
                                  child: Image.asset(AppImage.searchRoundIcon)),
                            ),
                          ],
                        ),
                      ),
                      if (isSearch)
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 80 / 100,
                            height:
                                MediaQuery.of(context).size.height * 6 / 100,
                            child: TextFormField(
                              readOnly: false,
                              style: AppConstant.textFilledHeading,
                              textAlignVertical: TextAlignVertical.center,
                              keyboardType: TextInputType.name,
                              autofocus: isSearch,
                              onChanged: (value) {
                                setState(() {
                                  if (value.isNotEmpty) {
                                    searchResultCity(value);
                                  } else {
                                    cityList = citySearchList;
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(AppImage.searchIcon1,
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
                                                  100),
                                    ]),
                                border: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppColor.textColor),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(25))),
                                enabledBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppColor.textColor),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(25))),
                                focusedBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppColor.textColor),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(25))),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 15),
                                filled: false,
                                counterText: '',
                                hintText: AppLanguage.searchInputText[language],
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
                          height: MediaQuery.of(context).size.height * 3 / 100),
                      Expanded(
                          child: SingleChildScrollView(
                              child: Column(children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 90 / 100,
                          alignment: Alignment.center,
                          child: Wrap(
                            spacing: 15,
                            runSpacing: 12,
                            children: List.generate(cityList.length, (index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => PropertyScreen(
                                                propertyAdId:
                                                    _selectedPropertyTab
                                                        .toString(),
                                                cityId: cityList[index]
                                                        ['city_id']
                                                    .toString(),
                                              )));

                                  // if (selectActivity == 0) {
                                  //   getActivityAccordingDestination(
                                  //       contextUp,
                                  //       screenWidth,
                                  //       cityList[index]['city_id']);
                                  // } else {
                                  //   Navigator.push(
                                  //       context,
                                  //       MaterialPageRoute(
                                  //           builder: (context) => Beaches(
                                  //               status: 0,
                                  //               activityId:
                                  //                   selectActivity.toString(),
                                  //               destinationId: cityList[index]
                                  //                       ['city_id']
                                  //                   .toString(),
                                  //               toOpen: "")));
                                  // }
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width *
                                      27 /
                                      100,
                                  height: MediaQuery.of(context).size.height *
                                      15 /
                                      100,
                                  padding: const EdgeInsets.only(left: 15),
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: cityList[index]
                                                      ['city_image'] !=
                                                  null
                                              ? NetworkImage(
                                                  "${AppConfigProvider.imageURL}${cityList[index]['city_image']}")
                                              : const AssetImage(
                                                      AppImage.dummyIcon)
                                                  as ImageProvider,
                                          fit: BoxFit.cover),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: language == 0
                                        ? CrossAxisAlignment.start
                                        : CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          cityList[index]['city_name']
                                                  [language] ??
                                              "",
                                          style: const TextStyle(
                                              color: AppColor.secondaryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily)),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              1 /
                                              100),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 2 / 100),
                      ]))),
                    ]),
                  ),
                ),
              ),
            );
          }),
        );
      },
    ).then((_) => onDismiss());
  }

  // ── Property Type Card ────────────────────────────────────────────────
  // Widget _propertyTypeCard({
  //   required BuildContext context,
  //   required StateSetter setModalState,
  //   required String imagePath,
  //   required String label,
  // }) {
  //   final size = MediaQuery.of(context).size;
  //   // final isSelected = _selectedPropertyType == label;

  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.push(context,
  //           MaterialPageRoute(builder: (context) => const PropertyScreen()));
  //     },
  //     child: Column(
  //       children: [
  //         // Image card
  //         Expanded(
  //           child: AnimatedContainer(
  //             duration: const Duration(milliseconds: 180),
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(15),
  //               // border: Border.all(
  //               //   color: isSelected
  //               //       ? AppColor.themeColor
  //               //       : AppColor.boxshadowColor,
  //               //   width: isSelected ? 2.5 : 1,
  //               // ),
  //               // boxShadow: isSelected
  //               //     ? [
  //               //         BoxShadow(
  //               //           color: AppColor.themeColor.withOpacity(0.25),
  //               //           blurRadius: 8,
  //               //           spreadRadius: 1,
  //               //         )
  //               //       ]
  //               //     : [],
  //               image: DecorationImage(
  //                 image: AssetImage(imagePath),
  //                 fit: BoxFit.cover,
  //                 // Darken slightly when NOT selected so selected pops
  //                 // colorFilter: isSelected
  //                 //     ? null
  //                 //     : ColorFilter.mode(
  //                 //         Colors.black.withOpacity(0.15),
  //                 //         BlendMode.darken,
  //                 //       ),
  //               ),
  //             ),
  //           ),
  //         ),
  //         SizedBox(height: size.height * 0.008),
  //         // Label
  //         Text(
  //           label,
  //           textAlign: TextAlign.center,
  //           style: const TextStyle(
  //             fontSize: 12,
  //             fontWeight: FontWeight.w500,
  //             fontFamily: AppFont.fontFamily,
  //             color: Colors.black87,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
