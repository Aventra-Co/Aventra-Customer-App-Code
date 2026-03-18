import 'package:boatapp/controller/app_color.dart';
import 'package:boatapp/controller/app_font.dart';
import 'package:flutter/material.dart';

void showSortBottomSheet(BuildContext context) {
  String selectedSort = 'Relevance';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final size = MediaQuery.of(context).size;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            width: size.width,
            padding: EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
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
                    'Sort',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFont.fontFamily,
                      // color: AppColor.primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Divider(color: Colors.grey.shade300),
                SizedBox(height: 8),

                RadioListTile<String>(
                  title: Text('Relevance',style: TextStyle(fontFamily: AppFont.fontFamily,fontSize: 14,fontWeight: FontWeight.w400)),
                  value: 'Relevance',
                  groupValue: selectedSort,
                  activeColor: Color(0xFF17A2B8),
                  controlAffinity: ListTileControlAffinity.trailing,
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  dense: true,
                  onChanged: (value) {
                    setModalState(() {
                      selectedSort = value!;
                         Navigator.pop(context);
                    });
                  },
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                ),
                RadioListTile<String>(
                  title: Text('Rating: High To Low',style: TextStyle(fontFamily: AppFont.fontFamily,fontSize: 14,fontWeight: FontWeight.w400)),
                  value: 'Rating: High To Low',
                  groupValue: selectedSort,
                  activeColor: Color(0xFF17A2B8),
                  controlAffinity: ListTileControlAffinity.trailing,
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  dense: true,
                  onChanged: (value) {
                    setModalState(() {
                      selectedSort = value!;
                         Navigator.pop(context);
                    });
                  },
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                ),
                RadioListTile<String>(
                  title: Text('Distance: High To Low',style: TextStyle(fontFamily: AppFont.fontFamily,fontSize: 14,fontWeight: FontWeight.w400)),
                  value: 'Distance: High To Low',
                  groupValue: selectedSort,
                  activeColor: Color(0xFF17A2B8),
                  controlAffinity: ListTileControlAffinity.trailing,
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  dense: true,
                  onChanged: (value) {
                    setModalState(() {
                      selectedSort = value!;
                      Navigator.pop(context);
                    });
                  },
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                ),
                RadioListTile<String>(
                  title: Text('Cost : High To Low',style: TextStyle(fontFamily: AppFont.fontFamily,fontSize: 14,fontWeight: FontWeight.w400)),
                  value: 'Cost : High To Low',
                  groupValue: selectedSort,
                  activeColor: Color(0xFF17A2B8),
                  controlAffinity: ListTileControlAffinity.trailing,
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  dense: true,
                  onChanged: (value) {
                    setModalState(() {
                      selectedSort = value!;
                         Navigator.pop(context);
                    });
                  },
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                ),
                RadioListTile<String>(
                  title: Text('Cost : Low To High',style: TextStyle(fontFamily: AppFont.fontFamily,fontSize: 14,fontWeight: FontWeight.w400)),
                  value: 'Cost : Low To High',
                  groupValue: selectedSort,
                  activeColor: Color(0xFF17A2B8),
                  controlAffinity: ListTileControlAffinity.trailing,
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  dense: true,
                  onChanged: (value) {
                    setModalState(() {
                      selectedSort = value!;
                         Navigator.pop(context);
                    });
                  },
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
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