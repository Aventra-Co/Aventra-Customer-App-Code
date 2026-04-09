import '/controller/app_color.dart';
import '/controller/app_font.dart';
import '/controller/app_image.dart';
import 'package:flutter/material.dart';

Widget _propertyTypeCard(BuildContext context, String imagePath, String label,
    String selectedOption) {
  final size = MediaQuery.of(context).size;

  return GestureDetector(
    onTap: () {
      Navigator.pop(context);
    },
    child: Column(
      children: [
        // Image card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: selectedOption == 'Property'
                  ? Border.all(color: AppColor.boxshadowColor)
                  : null,
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SizedBox(height: size.height * 0.01),
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

void showFilterModal(BuildContext context, String selectedOption) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColor.transparentColor,
    builder: (context) {
      return Container(
        padding: EdgeInsets.all(24),
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
            // Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectedOption == "Sea"
                    ? 'Select sea type'
                    : 'Select property type',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFont.fontFamily,
                  color: Colors.black,
                ),
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
                  _propertyTypeCard(context, AppImage.privateVillaImage,
                      'Private Villa', selectedOption),
                  _propertyTypeCard(context, AppImage.chaletIstirahaImage,
                      'Chalet/Istiraha', selectedOption),
                  _propertyTypeCard(context, AppImage.luxuryVillaIcon,
                      'Luxury Villa', selectedOption),
                  _propertyTypeCard(context, AppImage.farmHouseImage,
                      'Farmhouse', selectedOption),
                  _propertyTypeCard(context, AppImage.resortVillaImage,
                      'Resort Villa', selectedOption),
                  _propertyTypeCard(context, AppImage.tentInDesertImage,
                      'Tent in desert', selectedOption),
                ]),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
