
import 'package:boatapp/view/property_screens/property_bookinghistory_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import 'view_property_details_screen.dart';

class PropertyPendingDetailsScreen extends StatelessWidget {
  PropertyPendingDetailsScreen({super.key});

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                  Text("ID : #4567687687",
                      style: const TextStyle(
                          color: AppColor.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFont.fontFamily)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.02),
                    SizedBox(height: size.height * 0.02),
                    Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 12, horizontal: size.width * 0.05),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      AppLanguage.pendingText[language],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: AppFont.fontFamily,
                                        color: AppColor.pendingColor,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ViewPropertyDetailsScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        AppLanguage.viewDetailsText[language],
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: AppFont.fontFamily,
                                            color: Color(0xFF17A2B8),
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppColor.completedColor),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLanguage
                                          .oceanExplorer3000Text[language],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: AppFont.fontFamily,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Luxury Yacht • Fintas Beach',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: AppFont.fontFamily,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              AppImage.shipImage,
                              width: size.width * 0.18,
                              height: size.width * 0.18,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.02),

                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Address
                          Text(
                            AppLanguage.locationAddressText[language],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: size.height * 0.01),
                          Text(
                            'Fintas, Kuwait, along the Arabian \nGulf coast',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              AppImage.mapImage,
                            ),
                          ),

                          SizedBox(height: size.height * 0.04),

                          // Booking Details
                          Text(
                            AppLanguage.bookingDetailsText[language],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily,
                              // color: Colors.black,
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),

                          _detailRow(
                              context,
                              size,
                              Icons.calendar_today_outlined,
                              'Jan 06,2025',
                              AppLanguage.bookingDate[language],
                              'Change',
                              0),
                          SizedBox(height: size.height * 0.02),
                          GestureDetector(
                            onTap: () {},
                            child: _detailRow(context, size, Icons.access_time,
                                'One Day', 'Booking Time', 'Change', 1),
                          ),
                          SizedBox(height: size.height * 0.02),
                          _detailRow(
                              context,
                              size,
                              Icons.people_outline,
                              '4 Adults • 2 Children',
                              AppLanguage.guestText[language],
                              'Change',
                              2),
                          SizedBox(height: size.height * 0.03),

                          // Description
                          Text(
                            AppLanguage.descriptionText[language],
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: size.height * 0.015),
                          Text(
                            'Blue Nature is a 5 star complemented with 80 well bedroom and suit, modern residence with prime location within the city center.',
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
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: size.height * 0.01),
                          _amenitiesGrid(context),

                          SizedBox(height: size.height * 0.02),

                          GestureDetector(
                            onTap: () => _showCancellationPolicyDialog(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Image.asset(
                                  AppImage.cancellationPolicyicon,
                                  width: size.width * 0.045,
                                ),
                                SizedBox(width: size.width * 0.02),
                                Text(
                                  AppLanguage.cancellationPolicyText[language],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFont.fontFamily,
                                    color: AppColor.themeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),

                    // Billing Details
                    Container(
                      padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.02,
                          horizontal: size.width * 0.04),
                      color: AppColor.lightGreen,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: size.height * 0.018),
                            Text(
                              AppLanguage.billingDetailsText[language],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: size.height * 2 / 100),
                            _billingRow(size, '1 Day', '64 KWD', ''),
                            Divider(height: size.height * 2 / 100),
                            _billingRow(size, 'Grand Total', '64 KWD', '',
                                isBold: true),
                            Divider(height: size.height * 2 / 100),
                            SizedBox(height: size.height * 0.02),
                          ]),
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Cancel Booking
                    InkWell(
                      onTap: () {
                        _showCancelBookingModal(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.014,
                            horizontal: size.width * 0.05),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Cancel Booking',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFont.fontFamily,
                                    // color: Colors.grey,
                                  ),
                                ),
                                SizedBox(width: size.width * 0.015),
                                Icon(Icons.info_outline,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amenitiesGrid(context) {
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
                style:const TextStyle(
                  fontSize: 13,
                  fontFamily: AppFont.fontFamily,
                  color: AppColor.primaryColor,
                  fontWeight: FontWeight.w500
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
    BuildContext context,
    Size size,
    IconData icon,
    String value,
    String label,
    String action,
    index,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xFF17A2B8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Color(0xFF17A2B8)),
        ),
        SizedBox(width: size.width * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFont.fontFamily,
                  // color: Colors.black,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFont.fontFamily,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            if (index == 0) {
              _showCalenderDateModal(context);
            } else if (index == 1) {
              _showBookingTimeModal(context);
            } else if (index == 2) {
              _showGuestModal(context);
            }
          },
          child: Text(
            action,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: AppFont.fontFamily,
              color: AppColor.primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 2.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade400),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }

  Widget _billingRow(Size size, String label, String amount, String subtitle,
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
                fontSize: 16,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                fontFamily: AppFont.fontFamily,
                color: Colors.black,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppFont.fontFamily,
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          SizedBox(height: size.height * 0.005),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              fontFamily: AppFont.fontFamily,
              color: AppColor.completedColor,
            ),
          ),
        ],
      ],
    );
  }

  void _showCancellationPolicyDialog(context) {
    final size = MediaQuery.of(context).size;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, //
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.cancellationPolicyText[language],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFont.fontFamily,
                    color: AppColor.themeColor,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Text(
                  'Cancellations made more than 5 days before the check-in date will receive a full refund of the total booking amount. Cancellations made between 2 to 5 days before the check-in date will receive a 50% refund. No refunds will be issued for cancellations made within 2 days of the check-in date.',
                  style: TextStyle(
                    fontSize: 13.8,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: size.height * 0.02),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _billingSubRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontFamily: AppFont.fontFamily,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: AppFont.fontFamily,
          ),
        ),
      ],
    );
  }

  void _showBookingTimeModal(BuildContext context) {
    String selectedPrice = 'One day (2pm till next day 12 afternoon)';

    final List<Map<String, String>> priceOptions = [
      {
        'title': 'One day (2pm till next day 12 afternoon)',
        'price': '200 KWD',
      },
      {
        'title': 'Weekday (Sun-Wed)',
        'price': '300 KWD',
      },
      {
        'title': 'Weekend (Thu-Sat)',
        'price': '350 KWD',
      },
      {
        'title': 'Full week (Sun-Sat)',
        'price': '500 KWD',
      },
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final size = MediaQuery.of(context).size;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: size.width * 8 / 100,
                    height: size.height * 8 / 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.01),

                // ✅ Main bottomsheet container
                Container(
                  padding: EdgeInsets.all(size.width * 0.05),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: size.height * 0.01),

                      // Title
                      const Text(
                        'Booking Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppFont.fontFamily,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(height: size.height * 0.02),

                      // Radio options
                      ...priceOptions.map((option) {
                        final isSelected = selectedPrice == option['title'];
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedPrice = option['title']!;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: size.height * 0.012),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColor.themeColor
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 11,
                                            height: 11,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColor.themeColor,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                SizedBox(width: size.width * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option['title']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        option['price']!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppFont.fontFamily,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      SizedBox(height: size.height * 0.025),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: size.height * 0.06,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCalenderDateModal(BuildContext context) {
    DateTime _selectedDay = DateTime.now();
    DateTime _focusedDay = DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final size = MediaQuery.of(context).size;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Floating close button center mein
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: size.width * 0.08,
                    height: size.height * 0.08,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.01),

                // ✅ Main white container
                Container(
                  padding: EdgeInsets.all(size.width * 0.05),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: size.height * 0.01),

                      // Title
                      const Text(
                        'Booking Date',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppFont.fontFamily,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(height: size.height * 0.02),

                      // Legend row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _legendItem(
                              context, AppLanguage.bookNowText[language], null),
                          SizedBox(width: size.width * 0.08),
                          _legendItem(
                              context, 'Availability', const Color(0xFF009FE3)),
                          _legendItem(context, 'Selected', AppColor.themeColor),
                        ],
                      ),

                      SizedBox(height: size.height * 0.01),

                      // Calendar
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setModalState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setModalState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },
                        calendarBuilders: CalendarBuilders(
                          headerTitleBuilder: (context, date) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.02),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMMM').format(date),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('yyyy').format(date),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: false,
                          headerPadding: EdgeInsets.symmetric(
                              vertical: size.height * 0.01),
                          leftChevronIcon: const SizedBox.shrink(),
                          rightChevronIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.017,
                                  vertical: size.height * 0.008,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(Icons.chevron_left,
                                    color: AppColor.themeColor, size: 20),
                              ),
                              SizedBox(width: size.width * 0.01),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.017,
                                  vertical: size.height * 0.008,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(Icons.chevron_right,
                                    color: AppColor.themeColor, size: 20),
                              ),
                            ],
                          ),
                          leftChevronMargin: EdgeInsets.zero,
                          rightChevronMargin: EdgeInsets.zero,
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.white,
                          ),
                          weekendStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.white,
                          ),
                          decoration: BoxDecoration(color: AppColor.themeColor),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: AppColor.themeColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.black87,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppColor.themeColor,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.white,
                          ),
                          defaultTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.black87,
                          ),
                          weekendTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.black87,
                          ),
                          outsideTextStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.grey.shade400,
                          ),
                          cellMargin: const EdgeInsets.all(6),
                        ),
                      ),

                      SizedBox(height: size.height * 0.025),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: size.height * 0.06,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.02),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGuestModal(BuildContext context) {
    int adultCount = 0;
    int childCount = 4;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final size = MediaQuery.of(context).size;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: size.width * 0.08,
                    height: size.height * 0.08,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.black, size: 18),
                  ),
                ),

                SizedBox(height: size.height * 0.01),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.05,
                    vertical: size.height * 0.025,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: size.height * 0.01),

                      // Title
                      const Text(
                        'Guests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppFont.fontFamily,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(height: size.height * 0.03),

                      // Adult row
                      _guestCounterRow(
                        context,
                        label: 'Adult',
                        count: adultCount,
                        onDecrement: () {
                          if (adultCount > 0) {
                            setModalState(() => adultCount--);
                          }
                        },
                        onIncrement: () {
                          setModalState(() => adultCount++);
                        },
                      ),

                      Divider(
                          color: Colors.grey.shade200,
                          height: size.height * 0.04),

                      // Child row
                      _guestCounterRow(
                        context,
                        label: 'Child',
                        count: childCount,
                        onDecrement: () {
                          if (childCount > 0) {
                            setModalState(() => childCount--);
                          }
                        },
                        onIncrement: () {
                          setModalState(() => childCount++);
                        },
                      ),

                      SizedBox(height: size.height * 0.03),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: size.height * 0.06,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.02),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _guestCounterRow(
    BuildContext context, {
    required String label,
    required int count,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: AppFont.fontFamily,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            // Decrement button
            GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child:
                    const Icon(Icons.remove, size: 16, color: Colors.black87),
              ),
            ),

            SizedBox(width: size.width * 0.04),

            // Count
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppFont.fontFamily,
                color: Colors.black,
              ),
            ),

            SizedBox(width: size.width * 0.04),

            // Increment button
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(BuildContext context, label, Color? dotColor) {
    final size = MediaQuery.of(context).size;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: AppFont.fontFamily,
            color: Colors.black87,
          ),
        ),
        if (dotColor != null) ...[
          SizedBox(width: size.width * 0.015),
          Container(
            width: size.width * 0.035,
            height: size.width * 0.035,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelBookingModal(BuildContext context) {
    String selectedReason = '';
    final TextEditingController descController = TextEditingController();

    final List<String> cancelReasons = [
      'Found another property',
      'Price too high',
      'Location not suitable',
      'Location too far',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final size = MediaQuery.of(context).size;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: size.width * 0.08,
                      height: size.height * 0.08,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.black, size: 18),
                    ),
                  ),

                  SizedBox(height: size.height * 0.01),

                  // Main white container
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.05,
                      vertical: size.height * 0.025,
                    ),
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
                        SizedBox(height: size.height * 0.01),

                        // Title
                        Center(
                          child: Text(
                            'Cancel Reasons',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.02),

                        // Radio options
                        ...cancelReasons.map((reason) {
                          final isSelected = selectedReason == reason;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedReason = reason;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: size.height * 0.012),
                              child: Row(
                                children: [
                                  // Radio button
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColor.themeColor
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 11,
                                              height: 11,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColor.themeColor,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: size.width * 0.03),
                                  Text(
                                    reason,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        SizedBox(height: size.height * 0.02),

                        // Describe the issue label
                        Text(
                          'Describe the issue',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: size.height * 0.01),

                        // Text field
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: descController,
                            maxLines: 4,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Write more details here to help us understand the problem...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.grey.shade400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(size.width * 0.03),
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.025),

                        // Confirm Cancel button
                        SizedBox(
                          width: double.infinity,
                          height: size.height * 0.06,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PropertyBookingHistoryDetailScreen(iscompleted: false)
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.themeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Confirm Booking Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.02),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
