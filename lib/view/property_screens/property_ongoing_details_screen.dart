import 'package:boatapp/controller/app_button.dart';
import 'package:boatapp/controller/app_color.dart';
import 'package:boatapp/controller/app_constant.dart';
import 'package:boatapp/controller/app_font.dart';
import 'package:boatapp/controller/app_header.dart';
import 'package:boatapp/controller/app_image.dart';
import 'package:boatapp/controller/app_language.dart';
import 'package:boatapp/view/other_screen/help_support_screen.dart';
import 'package:boatapp/view/property_screens/viewAll_property_screen.dart';
import 'package:boatapp/view/property_screens/view_property_details_screen.dart';
import 'package:flutter/material.dart';

class PropertyOngoingDetailScreen extends StatelessWidget {
  PropertyOngoingDetailScreen({super.key});

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

  // horizontal padding value reused everywhere
  static const double _hPad = 16;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header row ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AppHeader(
                        text: AppLanguage.detailsText[language],
                        onPress: () => Navigator.pop(context),
                      ),
                    ),
                    Text(
                      'ID : #4567687687',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFont.fontFamily,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Status / Greenleaf container — FULL WIDTH ────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _hPad - 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppLanguage.ongoingText[language],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFont.fontFamily,
                                    color: AppColor.darkBlueColor,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ViewPropertyDetailsScreen()));
                                  },
                                  child: const Text(
                                    'View Details',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: AppFont.fontFamily,
                                        color: Color(0xFF17A2B8),
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColor.themeColor),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              AppLanguage.greenLeafInnText[AppLanguage.language],
                              style: const TextStyle(
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
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          AppImage.shipImage,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Location Address ─────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: _hPad),
                child: Text(
                  'Location Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Text(
                  'Fintas, Kuwait, along the Arabian Gulf coast',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // ── Map — full width ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(AppImage.mapImage),
                ),
              ),

              const SizedBox(height: 15),

              // ── Booking Details ──────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: _hPad),
                child: Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _detailRow(
                  Icons.calendar_today_outlined,
                  'Jan 06, 2025',
                  'Booking Date',
                  'Change',
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _detailRow(
                  Icons.access_time,
                  '1 Day',
                  'Booking Time',
                  'Change',
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _detailRow(
                  Icons.people_outline,
                  '4 Adults • 2 Children',
                  'Guests',
                  'Change',
                ),
              ),

              SizedBox(height: size.height * 4 / 100),

              // ── Description ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Text(
                  AppLanguage.descriptionText[language],
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Text(
                  AppLanguage.blueNatureText[language],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),

              SizedBox(height: size.height * 4 / 100),

              // ── What this place offers ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Text(
                  AppLanguage.whatThisplaceOfferText[language],
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _amenitiesGrid(context),
              ),

              SizedBox(height: size.height * 0.02),

              // ── Cancellation Policy ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: GestureDetector(
                  onTap: () => _showCancellationPolicyDialog(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(
                        AppImage.cancellationPolicyicon,
                        width: size.width * 0.045,
                      ),
                      SizedBox(width: size.width * 0.03),
                      Text(
                        AppLanguage.cancellationPolicyText[language],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.fontFamily,
                          color: AppColor.themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // ── Billing Details — full width ─────────────────────────
              Container(
                width: double.infinity,
                color: Colors.grey.shade50,
                padding: const EdgeInsets.symmetric(
                    horizontal: _hPad, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Billing Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppFont.fontFamily,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _billingRow('1 Day', '64 KWD', ''),
                    const Divider(height: 32),
                    _billingRow('Grand Total', '64 KWD', '', isBold: true),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Buttons ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: AppButton(
                  text: 'Chat',
                  onPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HelpSupport()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: AppButton(
                  text: 'Location',
                  onPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PropertyHomeScreen(
                          initialView: 'Map',
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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
          insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.cancellationPolicyText[language],
                  style: const TextStyle(
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
            iconWidget = Image.asset(AppImage.tvIcon, width: size.width * 0.045, height: size.width * 0.045, color: AppColor.primaryColor);
            break;
          case 'Wifi':
            iconWidget = Image.asset(AppImage.wifiIcon, width: size.width * 0.045, height: size.width * 0.045, color: AppColor.primaryColor);
            break;
          case 'AC':
            iconWidget = Image.asset(AppImage.acIcon, width: size.width * 0.045, height: size.width * 0.045, color: AppColor.primaryColor);
            break;
          case 'Fridge':
            iconWidget = Image.asset(AppImage.fridgeIcon, width: size.width * 0.045, height: size.width * 0.045, color: AppColor.primaryColor);
            break;
          case 'Bedding':
            iconWidget = Image.asset(AppImage.beddingIcon, width: size.width * 0.045, height: size.width * 0.045, color: AppColor.primaryColor);
            break;
          case 'Microwave':
            iconWidget = Image.asset(AppImage.microwaveIcon, width: size.width * 0.045, height: size.width * 0.045, color: AppColor.primaryColor);
            break;
          case 'Kettle':
            iconWidget = Image.asset(AppImage.kettleIcon, width: size.width * 0.045, height: size.width * 0.045, color: AppColor.primaryColor);
            break;
          case 'Coffee Machine':
            iconWidget = Image.asset(AppImage.coffeeIcon, width: size.width * 0.045, height: size.width * 0.045, color: AppColor.primaryColor);
            break;
          default:
            iconWidget = Image.asset(AppImage.tvIcon, width: size.width * 0.045, height: size.width * 0.045, color: AppColor.primaryColor);
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            SizedBox(width: size.width * 0.015),
            Expanded(
              child: Text(
                amenity,
                style: TextStyle(fontSize: 13, fontFamily: AppFont.fontFamily, color: AppColor.primaryColor, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

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
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: AppFont.fontFamily, color: Colors.black)),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, fontFamily: AppFont.fontFamily, color: Colors.grey.shade600)),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            action,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: AppFont.fontFamily, color: AppColor.primaryColor, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _billingRow(String label, String amount, String subtitle, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, fontFamily: AppFont.fontFamily, color: Colors.black)),
            Text(amount, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600, fontFamily: AppFont.fontFamily, color: Colors.black)),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, fontFamily: AppFont.fontFamily, color: Colors.grey.shade600)),
        ],
      ],
    );
  }

  Widget _billingSubRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, fontFamily: AppFont.fontFamily, color: Colors.grey.shade700)),
        Text(amount, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: AppFont.fontFamily, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _addonItem(String title, String price, int quantity) {
    return Row(
      children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade300), child: Icon(Icons.image, color: Colors.grey.shade500)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: AppFont.fontFamily, color: Colors.black87))),
        if (quantity > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
            child: Text('Qty: $quantity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, fontFamily: AppFont.fontFamily, color: Colors.black87)),
          ),
        if (price.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: AppFont.fontFamily, color: Colors.black)),
        ],
      ],
    );
  }
}