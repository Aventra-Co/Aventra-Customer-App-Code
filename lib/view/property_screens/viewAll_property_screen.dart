import 'dart:convert';
import 'package:boatapp/controller/app_shimmers.dart';
import 'package:http/http.dart' as http;
import 'package:boatapp/controller/app_color.dart';
import 'package:boatapp/controller/app_constant.dart';
import 'package:boatapp/controller/app_font.dart';
import 'package:boatapp/controller/app_header.dart';
import 'package:boatapp/controller/app_image.dart';
import 'package:boatapp/controller/app_language.dart';
import 'package:flutter/material.dart';
import 'package:boatapp/view/property_screens/property_detail_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_config_provider.dart';

class PropertyHomeScreen extends StatefulWidget {
  final String initialView;

  const PropertyHomeScreen({super.key, this.initialView = "List"});

  @override
  State<PropertyHomeScreen> createState() => _PropertyHomeScreenState();
}

class _PropertyHomeScreenState extends State<PropertyHomeScreen> {
  late String selectedView;
  int userId = 0;
  dynamic userDetails;
  bool isApiCalling = false;
  bool isLoading = true;

  // ── Search ────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<dynamic> get _filteredProperties {
    if (_searchQuery.isEmpty) return properties;
    return properties
        .where((p) =>
            p['property_name_english']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            p['city_name'][language]
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }
  // ─────────────────────────────────────────────────────────────────────

  List<dynamic> properties = [];

  @override
  void initState() {
    super.initState();
    getUserDetails();
    selectedView = widget.initialView;
  }

  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");
    setState(() => isApiCalling = true);
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      userId = data['user_id'];
    }
    isApiCalling = false;
    getAllAdvertisementApi(userId);
    setState(() {});
  }

  Future<void> getAllAdvertisementApi(userId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}getall_advertisements?user_id=$userId");
    print("url $url");
    String token = AppConstant.token;
    Map<String, String> headers = {'Authorization': 'Bearer $token'};
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        if (res['success'] == true) {
          var item = res['data'];
          properties = (item != "NA") ? item : [];
          item = res['banner_arr'];
          setState(() => isLoading = false);
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  deeplinkingProp(BuildContext context, propertyAdId) async {
    var shareUrl =
        "${AppConfigProvider.apiUrl}deepLink?link=aventra://property_ad_id/${Uri.encodeComponent(propertyAdId.toString())}";
    final RenderBox box = context.findRenderObject() as RenderBox;
    await Share.share("Aventra App! $shareUrl",
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.white,
        statusBarIconBrightness: Brightness.dark));

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            AppHeader(
              text: AppLanguage.mostPopularpropertiesText[language],
              onPress: () => Navigator.pop(context),
            ),

            SizedBox(height: size.height * 0.01),

            // ── Search Bar ───────────────────────────────────────────
            _buildSearchBar(size),
            SizedBox(height: size.height * 0.015),

            Expanded(
                child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.020),
                  // ── Grid ─────────────────────────────────────────────────
                  isLoading
                      ? favGridShimmerEffect(context)
                      : _filteredProperties.isEmpty
                          ? Padding(
                              padding: EdgeInsets.only(top: size.height * 0.1),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off,
                                      size: 60, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No properties found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.04),
                              itemCount: _filteredProperties.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemBuilder: (context, index) {
                                return _propertyGridCard(
                                    _filteredProperties[index], index);
                              },
                            ),

                  SizedBox(height: size.height * 0.05),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }

  // ── Search Bar Widget ─────────────────────────────────────────────────
  Widget _buildSearchBar(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: size.height * 0.060,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  fontFamily: AppFont.fontFamily,
                  color: AppColor.primaryColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Icon(
                      Icons.search,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  // Clear button when text is entered
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(Icons.close,
                              color: Colors.grey.shade400, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  counterText: '',
                ),
              ),
            ),
          ),

          SizedBox(width: size.width * 0.03),

          // Filter Button
          GestureDetector(
            onTap: () {
              showFilterModal(context);
            },
            child: Container(
              width: size.height * 0.055,
              height: size.height * 0.055,
              decoration: BoxDecoration(
                color: AppColor.themeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.themeColor.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── View Toggle Button ────────────────────────────────────────────────
  Widget _viewButton(String label, String activeImage, String inactiveImage) {
    final isSelected = selectedView == label;
    return GestureDetector(
      onTap: () => setState(() => selectedView = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              isSelected ? activeImage : inactiveImage,
              width: 18,
              height: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: AppFont.fontFamily,
                color: isSelected
                    ? AppColor.secondaryColor
                    : AppColor.textLightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── List Card ─────────────────────────────────────────────────────────
  Widget _propertyCard(Map<String, dynamic> property, int index) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PropertyDetailsScreen(
                  propertyAdId: property['property_ad_id'],
                )),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(property['image']),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 12,
              child: GestureDetector(
                onTap: () => setState(() {
                  properties[index]['isFavorite'] =
                      !properties[index]['isFavorite'];
                }),
                child: Container(
                  width: size.width * 0.07,
                  height: size.height * 0.07,
                  decoration: const BoxDecoration(
                    color: AppColor.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    property['isFavorite']
                        ? AppImage.removeFavouriteIcon
                        : AppImage.addFavouriteIcons,
                    width: size.width * 0.07,
                    height: size.width * 0.07,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property['name'],
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFont.fontFamily,
                          color: AppColor.secondaryColor)),
                  const SizedBox(height: 4),
                  Text(property['location'],
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.fontFamily,
                          color: AppColor.secondaryColor)),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColor.themeColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                    text: property['price'],
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor),
                  ),
                  const TextSpan(
                    text: '/Day',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor),
                  ),
                ])),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grid Card ─────────────────────────────────────────────────────────
  Widget _propertyGridCard(Map<String, dynamic> property, int index) {
    final size = MediaQuery.of(context).size;
    double screenWidth = MediaQuery.of(context).size.width;
    // find real index in original list for favorite toggle
    final realIndex = properties.indexOf(property);

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PropertyDetailsScreen(
                    propertyAdId: property['property_ad_id'],
                  ))),
      child: Container(
        width: size.width * 0.45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
              image: NetworkImage(
                  "${AppConfigProvider.imageURL}${property['cover_image']}"),
              fit: BoxFit.cover),
        ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                    Text("${property['starting_price']?.toString() ?? ""} KWD",
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
                  deeplinkingProp(context, property['property_ad_id']);
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
                      if (property['rating'].toString() != "0.00")
                        Container(
                          width: screenWidth > 600
                              ? MediaQuery.of(context).size.width * 10 / 100
                              : MediaQuery.of(context).size.width * 11 / 100,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 2),
                          decoration: BoxDecoration(
                              color: AppColor.secondaryColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(25)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: screenWidth > 600
                                    ? MediaQuery.of(context).size.width *
                                        2 /
                                        100
                                    : MediaQuery.of(context).size.width *
                                        3 /
                                        100,
                                height: screenWidth > 600
                                    ? MediaQuery.of(context).size.width *
                                        2 /
                                        100
                                    : MediaQuery.of(context).size.width *
                                        3 /
                                        100,
                                child: Image.asset(AppImage.ratingIcon),
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
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
                          width: MediaQuery.of(context).size.width * 1 / 100),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 5),
                        decoration: BoxDecoration(
                          color: AppColor.secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          "${(property['max_adult'] ?? 0 + (property['max_child'] ?? 0))} ${AppLanguage.guestsext[language]}",
                          style: const TextStyle(
                              color: AppColor.secondaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          if (realIndex != -1) {
                            setState(() => properties[realIndex]['isFavorite'] =
                                !(properties[realIndex]['isFavorite'] ??
                                    false));
                          }
                        },
                        child: Image.asset(
                          (property['isFavorite'] ?? false)
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
    );
  }
// ── Selected filter state ────────────────────────────────────────────

  // ── Filter Modal ──────────────────────────────────────────────────────
  void showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColor.transparentColor,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Select property type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFont.fontFamily,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Grid of property types
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _propertyTypeCard(
                        context: context,
                        setModalState: setModalState,
                        imagePath: AppImage.privateVillaImage,
                        label: 'Private Villa',
                      ),
                      _propertyTypeCard(
                        context: context,
                        setModalState: setModalState,
                        imagePath: AppImage.chaletIstirahaImage,
                        label: 'Chalet / Istiraha',
                      ),
                      _propertyTypeCard(
                        context: context,
                        setModalState: setModalState,
                        imagePath: AppImage.luxuryVillaIcon,
                        label: 'Luxury Villa',
                      ),
                      _propertyTypeCard(
                        context: context,
                        setModalState: setModalState,
                        imagePath: AppImage.farmHouseImage,
                        label: 'Farm House',
                      ),
                      _propertyTypeCard(
                        context: context,
                        setModalState: setModalState,
                        imagePath: AppImage.resortVillaImage,
                        label: 'Resort Villa',
                      ),
                      _propertyTypeCard(
                        context: context,
                        setModalState: setModalState,
                        imagePath: AppImage.tentInDesertImage,
                        label: 'Tent in Desert',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Property Type Card ────────────────────────────────────────────────
  Widget _propertyTypeCard({
    required BuildContext context,
    required StateSetter setModalState,
    required String imagePath,
    required String label,
  }) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Column(
        children: [
          // Image card
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                // border: Border.all(
                //   color: isSelected
                //       ? AppColor.themeColor
                //       : AppColor.boxshadowColor,
                //   width: isSelected ? 2.5 : 1,
                // ),
                // boxShadow: isSelected
                //     ? [
                //         BoxShadow(
                //           color: AppColor.themeColor.withOpacity(0.25),
                //           blurRadius: 8,
                //           spreadRadius: 1,
                //         )
                //       ]
                //     : [],
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                  // Darken slightly when NOT selected so selected pops
                  // colorFilter: isSelected
                  //     ? null
                  //     : ColorFilter.mode(
                  //         Colors.black.withOpacity(0.15),
                  //         BlendMode.darken,
                  //       ),
                ),
              ),
            ),
          ),
          SizedBox(height: size.height * 0.008),
          // Label
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: AppFont.fontFamily,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
