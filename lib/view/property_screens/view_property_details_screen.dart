import 'package:flutter/material.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';

class ViewPropertyDetailsScreen extends StatefulWidget {
  final dynamic adDetails;
  const ViewPropertyDetailsScreen({
    super.key,
    required this.adDetails,
  });

  @override
  State<ViewPropertyDetailsScreen> createState() =>
      _ViewPropertyDetailsScreenState();
}

class _ViewPropertyDetailsScreenState extends State<ViewPropertyDetailsScreen> {
  dynamic adDetails = {};

  @override
  void initState() {
    super.initState();
    adDetails = widget.adDetails;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 6 / 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top Space
              SizedBox(height: size.height * 3 / 100),

              /// Header Row
              Row(
                children: [
                  /// Back Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Image.asset(
                      AppImage.backnav,
                      color: Colors.black,
                      height: size.width * 6 / 100,
                    ),
                  ),

                  SizedBox(width: size.width * 20 / 100),

                  /// Title
                  Text(
                    AppLanguage.propertyDetailsText[language],
                    style: const TextStyle(
                      fontFamily: AppFont.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 5 / 100),

              /// Property Info
              _detailRow(AppLanguage.propertyNameText[language],
                  adDetails['property_name_english'] ?? "", size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow("${AppLanguage.propertyTypeText[language]}:",
                  adDetails['property_type_name'][language] ?? "", size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow(AppLanguage.propertyAddressText[language],
                  adDetails['address'] ?? '', size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow(
                  "${AppLanguage.roomsText[language]}:",
                  "${adDetails['no_of_rooms']?.toString() ?? "0"} ${AppLanguage.roomsText[language]}",
                  size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow(
                  "${AppLanguage.hallsText[language]}:",
                  "${adDetails['no_of_halls']?.toString() ?? "0"} ${AppLanguage.hallsText[language]}",
                  size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow(AppLanguage.outdoorSeatingText[language],
                  adDetails['outdoor_seating'] ?? "NA", size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow(
                  "${AppLanguage.washroomsText[language]}:",
                  "${adDetails['no_of_washroom']?.toString() ?? "0"} ${AppLanguage.washroomsText[language]}",
                  size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow(AppLanguage.poolText[language],
                  adDetails['pool'] ?? "NA", size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value, Size size) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Title
        SizedBox(
          width: size.width * 35 / 100,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: AppFont.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          width: size.width * 8 / 100,
        ),

        /// Value
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: AppFont.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
