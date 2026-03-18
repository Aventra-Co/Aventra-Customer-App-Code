import 'package:boatapp/controller/app_color.dart';
import 'package:boatapp/controller/app_constant.dart';
import 'package:boatapp/controller/app_font.dart';
import 'package:boatapp/controller/app_image.dart';
import 'package:boatapp/controller/app_language.dart';
import 'package:boatapp/model/property_model.dart';
import 'package:boatapp/model/sort_model.dart';
import 'package:flutter/material.dart';
import 'package:boatapp/view/property_screens/property_detail_screen.dart';

class PropertyScreen extends StatefulWidget {
  final String propertyAdId;
  final String cityId;
  const PropertyScreen(
      {super.key, required this.propertyAdId, required this.cityId});

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  String selectedView = "List";

  final List<Map<String, dynamic>> properties = [
    {
      'name': 'The Greenleaf Inn',
      'location': 'Abdali',
      'property_type': "Farmhouse",
      'price': '16 KWD',
      'max_people': "8",
      'rating': "4.5",
      'image': AppImage.greenLeafImage,
      'isFavorite': false,
    },
    {
      'name': 'Sunset Farmhouse',
      'location': 'Adailiya',
      'price': '16 KWD',
      'property_type': "Resort",
      'max_people': "8",
      'rating': "4.5",
      'image': AppImage.farmHouseImage,
      'isFavorite': false,
    },
    {
      'name': 'Palm Resort Chalet',
      'location': 'Ahmadi',
      'price': '16 KWD',
      'property_type': "Villa",
      'max_people': "8",
      'rating': "4.5",
      'image': AppImage.palmResortImage,
      'isFavorite': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(AppImage.propertyHomeImage),

                  // Back and Search buttons
                  Positioned(
                    top: 10,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: size.width * 0.09,
                          height: size.width * 0.09,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Image.asset(AppImage.bgBackArrow),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        SizedBox(
                          width: size.width * 0.1,
                          height: size.width * 0.1,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Image.asset(AppImage.searchicon2),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Property title
                  Positioned(
                    bottom: 80,
                    left: 24,
                    child: Text(
                      AppLanguage.propertyText[language],
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFont.fontFamily,
                      ),
                    ),
                  ),
                  // View toggle buttons
                  Positioned(
                    bottom: -22,
                    left: 50,
                    right: 50,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColor.secondaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.primaryColor.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: _viewButton(
                                  'List',
                                  AppImage.activelistImageIcon,
                                  AppImage.deactivelistImageIcon)),
                          Expanded(
                              child: _viewButton(
                                  'Grid',
                                  AppImage.activegridImageIcon,
                                  AppImage.deactivegridImageIcon)),
                          Expanded(
                              child: _viewButton(
                                  'Map',
                                  AppImage.activemapImageIcon,
                                  AppImage.deactivemapImageIcon)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 45),
              // Property list
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewButton(String label, String activeImage, String inactiveImage) {
    final isSelected = selectedView == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedView = label;
        });
      },
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

  Widget _propertyCard(Map<String, dynamic> property, int index, screenWidth) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PropertyDetailsScreen(propertyAdId: 1,),
          ),
        );
      },
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
            // Favorite button
            Positioned(
              right: 45,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    properties[index]['isFavorite'] =
                        !properties[index]['isFavorite'];
                  });
                },
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
                      height: size.width * 0.07),
                ),
              ),
            ),

            Positioned(
              right: 12,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: size.width * 0.07,
                  height: size.height * 0.07,
                  decoration: const BoxDecoration(
                    color: AppColor.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(AppImage.shareIcon,
                      width: size.width * 0.07, height: size.width * 0.07),
                ),
              ),
            ),

            // Property info
            Positioned(
              bottom: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFont.fontFamily,
                      color: AppColor.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${AppLanguage.cityText[language]} \u2022 ${property['location']}",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFont.fontFamily,
                      color: AppColor.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${AppLanguage.propertyTypeText[language]} \u2022 ${property['property_type']}",
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
                              : MediaQuery.of(context).size.width * 14 / 100,
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
                                        4 /
                                        100,
                                height: screenWidth > 600
                                    ? MediaQuery.of(context).size.width *
                                        2 /
                                        100
                                    : MediaQuery.of(context).size.width *
                                        4 /
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: AppFont.fontFamily),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 2 / 100),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 5),
                        decoration: BoxDecoration(
                          color: AppColor.secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          "${property['max_people']} ${AppLanguage.guestsext[language]}",
                          style: const TextStyle(
                              color: AppColor.secondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily),
                        ),
                      ),
                    ],
                  ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Starting From",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: property['price'],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily,
                              color: AppColor.secondaryColor,
                            ),
                          ),
                          // const TextSpan(
                          //   text: '/Day',
                          //   style: TextStyle(
                          //     fontSize: 10,
                          //     fontWeight: FontWeight.w400,
                          //     fontFamily: AppFont.fontFamily,
                          //     color: AppColor.secondaryColor,
                          //   ),
                          // ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Grid Card
  Widget _propertyGridCard(
      Map<String, dynamic> property, int index, screenWidth) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PropertyDetailsScreen(propertyAdId: 1,),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(property['image']),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
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
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLanguage.startingFromText[language],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: property['price'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFont.fontFamily,
                              color: AppColor.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              right: 5,
              top: -8,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: size.width * 0.06,
                  height: size.height * 0.06,
                  decoration: const BoxDecoration(
                    color: AppColor.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(AppImage.shareIcon,
                      width: size.width * 0.06, height: size.width * 0.06),
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
                    property['name'] ?? "",
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
                    "${AppLanguage.cityText[language]} \u2022 ${property['location']}",
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
                    "${AppLanguage.propertyTypeText[language]} \u2022 ${property['property_type']}",
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
                              : MediaQuery.of(context).size.width * 14 / 100,
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
                          width: MediaQuery.of(context).size.width * 2 / 100),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 5),
                        decoration: BoxDecoration(
                          color: AppColor.secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          "${property['max_people']} ${AppLanguage.guestsext[language]}",
                          style: const TextStyle(
                              color: AppColor.secondaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    properties[index]['isFavorite'] =
                        !properties[index]['isFavorite'];
                  });
                },
                child: Image.asset(
                    property['isFavorite']
                        ? AppImage.removeFavouriteIcon
                        : AppImage.addFavouriteIcons,
                    width: size.width * 0.06,
                    height: size.width * 0.06),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Map View
  Widget _buildMapView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Image.asset(AppImage.mapImage2)],
      ),
    );
  }

  Widget _buildContent() {
    final size = MediaQuery.of(context).size;
    double screenWidth = MediaQuery.of(context).size.width;
    if (selectedView == 'Map') {
      return _buildMapView();
    }

    return Column(
      children: [
        // Available count, Filter & Sort
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available (50)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFont.fontFamily,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showFilterModal(context, selectedView);
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          AppImage.filterSortImage,
                          width: size.width * 0.03,
                          height: size.height * 0.03,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 15,
                    width: 1,
                    color: AppColor.primaryColor,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  GestureDetector(
                    onTap: () {
                      showSortBottomSheet(context);
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          AppImage.filterSortImage,
                          width: size.width * 0.03,
                          height: size.height * 0.03,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Sort',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        selectedView == 'Grid'
            ? GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: properties.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  return _propertyGridCard(
                      properties[index], index, screenWidth);
                },
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: properties.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return _propertyCard(properties[index], index, screenWidth);
                },
              ),
        SizedBox(height: size.height * 0.15),
      ],
    );
  }
}
