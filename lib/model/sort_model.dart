
import 'package:boatapp/controller/app_font.dart';
import 'package:boatapp/controller/app_language.dart';
import 'package:flutter/material.dart';

import '../controller/app_constant.dart';

void showSortBottomSheet(
  BuildContext context, {
  required String selectedSort,
  required ValueChanged<String> onSelected,
}) {

  String currentSort = selectedSort;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final size = MediaQuery.of(context).size;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            width: size.width,
            padding: const EdgeInsets.symmetric(vertical: 24),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppLanguage.sorttext[language],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFont.fontFamily,
                      // color: AppColor.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: Text(
                      "${AppLanguage.ratingText[language]}: ${AppLanguage.highToLowText[language]}",
                      style: const TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w400)),
                  value:
                      "${AppLanguage.ratingText[language]}: ${AppLanguage.highToLowText[language]}",
                  groupValue: currentSort,
                  activeColor: const Color(0xFF17A2B8),
                  controlAffinity: ListTileControlAffinity.trailing,
                  visualDensity:
                      const VisualDensity(horizontal: -4, vertical: -4),
                  dense: true,
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => currentSort = value);
                    Navigator.pop(context);
                    onSelected(value);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                RadioListTile<String>(
                  title: Text(
                      "${AppLanguage.costText[language]}: ${AppLanguage.highToLowText[language]}",
                      style: const TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w400)),
                  value:
                      "${AppLanguage.costText[language]}: ${AppLanguage.highToLowText[language]}",
                  groupValue: currentSort,
                  activeColor: const Color(0xFF17A2B8),
                  controlAffinity: ListTileControlAffinity.trailing,
                  visualDensity:
                      const VisualDensity(horizontal: -4, vertical: -4),
                  dense: true,
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => currentSort = value);
                    Navigator.pop(context);
                    onSelected(value);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                RadioListTile<String>(
                  title: Text(
                      "${AppLanguage.costText[language]}: ${AppLanguage.lowToHighText[language]}",
                      style: const TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w400)),
                  value:
                      "${AppLanguage.costText[language]}: ${AppLanguage.lowToHighText[language]}",
                  groupValue: currentSort,
                  activeColor: const Color(0xFF17A2B8),
                  controlAffinity: ListTileControlAffinity.trailing,
                  visualDensity:
                      const VisualDensity(horizontal: -4, vertical: -4),
                  dense: true,
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => currentSort = value);
                    Navigator.pop(context);
                    onSelected(value);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                SizedBox(height: size.height * 0.18),
              ],
            ),
          );
        },
      );
    },
  );
}
