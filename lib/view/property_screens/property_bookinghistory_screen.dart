import 'package:boatapp/controller/app_button.dart';
import 'package:boatapp/controller/app_color.dart';
import 'package:boatapp/controller/app_constant.dart';
import 'package:boatapp/controller/app_font.dart';
import 'package:boatapp/controller/app_image.dart';
import 'package:boatapp/controller/app_language.dart';
import 'package:boatapp/propertymodule/property_rating.dart';
import 'package:boatapp/view/property_screens/view_property_details_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class PropertyBookingHistoryDetailScreen extends StatelessWidget {
  final bool iscompleted;
  final String? cancelReason;
  PropertyBookingHistoryDetailScreen(
      {super.key, required this.iscompleted, this.cancelReason});

  final List<String> amenities = [
    'TV',
    'Wifi',
    'AC',
    'Fridge',
    'Bedding',
    'Microwave',
    'Kettle',
    'Coffee Machine'
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context);
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              SizedBox(
                height: MediaQuery.of(context).size.height * 7 / 100,
                width: MediaQuery.of(context).size.width * 90 / 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Transform.rotate(
                        angle: language == 1 ? 3.1416 : 0,
                        child: SizedBox(
                          height: MediaQuery.of(context).size.width * 5 / 100,
                          width: MediaQuery.of(context).size.width * 5 / 100,
                          child: Image.asset(
                            AppImage.navigateBackIcon,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 4 / 100,
                      width: MediaQuery.of(context).size.width * 4 / 100,
                    ),
                    Text(AppLanguage.detailsText[language],
                        style: const TextStyle(
                            color: AppColor.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily)),
                    const Spacer(),
                    const Text("ID : #4567687687",
                        style: TextStyle(
                            color: AppColor.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFont.fontFamily)),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section 1: everything above billing ──────────
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: size.width * 0.04),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status badge and View Details
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            iscompleted
                                                ? AppLanguage
                                                    .completedText[language]
                                                : AppLanguage
                                                    .cancelledText[language],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily,
                                              color: iscompleted
                                                  ? AppColor.themeColor
                                                  : Colors.red,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const ViewPropertyDetailsScreen()));
                                            },
                                            child: Text(
                                              AppLanguage
                                                  .viewDetailsText[language],
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  color: Color(0xFF17A2B8),
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor:
                                                      AppColor.themeColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        AppLanguage.greenLeafInnText[language],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppFont.fontFamily,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      AppImage.greenLeafImage,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Location Address
                            Text(
                              AppLanguage.locationAddressText[language],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Fintas, Kuwait, along the Arabian Gulf coast',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 15),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(AppImage.mapImage),
                            ),

                            const SizedBox(height: 15),

                            // Booking Details
                            Text(
                              AppLanguage.bookingDetailsText[language],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _detailRow(
                              Icons.calendar_today_outlined,
                              'Jan 06,2025',
                              'Booking Date',
                              'Change',
                            ),
                            const SizedBox(height: 16),
                            _detailRow(
                              Icons.access_time,
                              '1 Day',
                              'Booking Time',
                              'Change',
                            ),
                            const SizedBox(height: 16),
                            _detailRow(
                              Icons.people_outline,
                              '4 Adults • 2 Children',
                              AppLanguage.guestText[language],
                              'Change',
                            ),
                            const SizedBox(height: 24),

                            // Description
                            Text(
                              AppLanguage.descriptionText[language],
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: size.height * 0.02),
                            Text(
                              AppLanguage.blueNatureText[language],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: size.height * 3 / 100),

                            Text(
                              AppLanguage.whatThisplaceOfferText[language],
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: size.height * 0.01),
                            _amenitiesGrid(context),
                            SizedBox(height: size.height * 0.03),
                          ],
                        ),
                      ),

                      // ── Section 2: Billing — FULL WIDTH ─────────────
                      Container(
                        width: double.infinity,
                        color: AppColor.background,
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLanguage.billingDetailsText[language],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: size.height * 2 / 100),
                            _billingRow('1 Day', '64 KWD', ''),
                            SizedBox(height: size.height * 3 / 100),
                            Divider(height: size.height * 2 / 100),
                            _billingRow('Grand Total', '64 KWD', '',
                                isBold: true),
                            SizedBox(height: size.height * 3 / 100),
                          ],
                        ),
                      ),

                      SizedBox(height: size.height * 2 / 100),

                      // ── Section 3: Cancel reason / Rate Now ──────────
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: size.width * 0.04),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!iscompleted && cancelReason != true) ...[
                              SizedBox(height: size.height * 1 / 100),
                              GestureDetector(
                                onTap: () {
                                  _cancelPolicyBottomSheet(context);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: size.width * 2 / 100,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLanguage.cancelReaText[language],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily,
                                          color: Colors.red,
                                        ),
                                      ),
                                      SizedBox(height: size.height * 0.5 / 100),
                                      Text(
                                        AppLanguage
                                            .foundAnotherpropertyText[language],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: AppFont.fontFamily,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (iscompleted)
                              AppButton(
                                text: AppLanguage.rateNowText[language],
                                onPress: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: ((context) =>
                                              const PropertyRateNow())));
                                },
                              ),
                            SizedBox(height: size.height * 5 / 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cancel policy bottom sheet ─────────────────────────────────────────
  void _cancelPolicyBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColor.secondaryColor.withOpacity(0.1),
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Directionality(
                textDirection:
                    language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                child: Container(
                  width: MediaQuery.of(context).size.width * 100 / 100,
                  height: MediaQuery.of(context).size.height * 100 / 100,
                  color: AppColor.secondaryColor.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 80 / 100,
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 15),
                        decoration: BoxDecoration(
                            color: AppColor.secondaryColor,
                            borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLanguage.cancellationPolicyText[language],
                              style: const TextStyle(
                                  color: AppColor.themeColor,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    1 /
                                    100),
                            Text(
                              AppLanguage.cancelDetailsText[language],
                              style: const TextStyle(
                                  color: AppColor.primaryColor,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    3 /
                                    100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  // ── Helper widgets ─────────────────────────────────────────────────────
  Widget _detailRow(IconData icon, String value, String label, String action) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF17A2B8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF17A2B8)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFont.fontFamily,
                  color: Colors.black,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFont.fontFamily,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amenitiesGrid(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: amenities.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 6,
      ),
      itemBuilder: (context, index) {
        final amenity = amenities[index];
        Widget iconWidget;
        switch (amenity) {
          case 'TV':
            iconWidget = Image.asset(AppImage.tvIcon,
                width: size.width * 0.045,
                height: size.width * 0.045,
                color: AppColor.primaryColor);
            break;
          case 'Wifi':
            iconWidget = Image.asset(AppImage.wifiIcon,
                width: size.width * 0.045,
                height: size.width * 0.045,
                color: AppColor.primaryColor);
            break;
          case 'AC':
            iconWidget = Image.asset(AppImage.acIcon,
                width: size.width * 0.045,
                height: size.width * 0.045,
                color: AppColor.primaryColor);
            break;
          case 'Fridge':
            iconWidget = Image.asset(AppImage.fridgeIcon,
                width: size.width * 0.045,
                height: size.width * 0.045,
                color: AppColor.primaryColor);
            break;
          case 'Bedding':
            iconWidget = Image.asset(AppImage.beddingIcon,
                width: size.width * 0.045,
                height: size.width * 0.045,
                color: AppColor.primaryColor);
            break;
          case 'Microwave':
            iconWidget = Image.asset(AppImage.microwaveIcon,
                width: size.width * 0.045,
                height: size.width * 0.045,
                color: AppColor.primaryColor);
            break;
          case 'Kettle':
            iconWidget = Image.asset(AppImage.kettleIcon,
                width: size.width * 0.045,
                height: size.width * 0.045,
                color: AppColor.primaryColor);
            break;
          case 'Coffee Machine':
            iconWidget = Image.asset(AppImage.coffeeIcon,
                width: size.width * 0.045,
                height: size.width * 0.045,
                color: AppColor.primaryColor);
            break;
          default:
            iconWidget = Image.asset(AppImage.tvIcon,
                width: size.width * 0.045,
                height: size.width * 0.045,
                color: AppColor.primaryColor);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            SizedBox(width: size.width * 0.015),
            Expanded(
              child: Text(
                amenity,
                style: const TextStyle(
                    fontSize: 13,
                    fontFamily: AppFont.fontFamily,
                    color: AppColor.primaryColor,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _billingRow(String label, String amount, String subtitle,
      {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                fontFamily: AppFont.fontFamily,
                color: Colors.black,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                fontFamily: AppFont.fontFamily,
                color: Colors.black,
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              fontFamily: AppFont.fontFamily,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _billingSubRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontFamily: AppFont.fontFamily,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: AppFont.fontFamily,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
