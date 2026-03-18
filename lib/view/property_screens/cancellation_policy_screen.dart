// import 'package:boatapp/controller/app_color.dart';
// import 'package:boatapp/controller/app_constant.dart';
// import 'package:boatapp/controller/app_font.dart';
// import 'package:boatapp/controller/app_header.dart';
// import 'package:boatapp/controller/app_language.dart';
// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';

// class CancellationPolicy extends StatefulWidget {
//   const CancellationPolicy({super.key});

//   @override
//   State<CancellationPolicy> createState() => _CancellationPolicyState();
// }

// class _CancellationPolicyState extends State<CancellationPolicy> {
//   DateTime _focusedDay = DateTime.now();
//   DateTime? _selectedDay;
//   int adults = 6;
//   int children = 4;

//    @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _showCancellationPolicyDialog();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: SafeArea(
//             child: SingleChildScrollView(
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           AppHeader(
//               text: AppLanguage.bookNowText[language],
//               onPress: () {
//                 Navigator.pop(context);
//               }),
              
//               SizedBox(height: 25),

//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _legendItem('Book Now', null),
//                SizedBox(width: 30),
//               _legendItem('Availability',AppColor.themeColor),
//               _legendItem('Selected', Color(0xFF0D9488)),
//             ],
//           ),
//           TableCalendar(
//             firstDay: DateTime.utc(2020, 1, 1),
//             lastDay: DateTime.utc(2030, 12, 31),
//             focusedDay: _focusedDay,
//             selectedDayPredicate: (day) {
//               return isSameDay(_selectedDay, day);
//             },
//             onDaySelected: (selectedDay, focusedDay) {
//               setState(() {
//                 _selectedDay = selectedDay;
//                 _focusedDay = focusedDay;
//               });
//             },
//             onPageChanged: (focusedDay) {
//               _focusedDay = focusedDay;
//             },
//             // Calendar format
//             calendarFormat: CalendarFormat.month,
//             availableCalendarFormats: const {
//               CalendarFormat.month: 'Month',
//             },

//             // Header style
//             headerStyle: HeaderStyle(
//               formatButtonVisible: false,
//               titleCentered: false,
//               titleTextStyle: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//                 fontFamily: AppFont.fontFamily,
//                 color: Colors.black,
//               ),
//               leftChevronIcon: Container(
//                 width: 35,
//                 height: 35,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade200,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.chevron_left,
//                   color: Colors.black87,
//                   size: 20,
//                 ),
//               ),
//               rightChevronIcon: Container(
//                 width: 35,
//                 height: 35,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade200,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.chevron_right,
//                   color: Colors.black87,
//                   size: 20,
//                 ),
//               ),
//             ),

//             // Days of week style
//             daysOfWeekStyle: DaysOfWeekStyle(
//               weekdayStyle: TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: AppFont.fontFamily,
//                 color: Colors.white,
//               ),
//               weekendStyle: TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: AppFont.fontFamily,
//                 color: Colors.white,
//               ),
//               decoration: BoxDecoration(
//                 color:AppColor.themeColor,
//               ),
//             ),

//             // Calendar style
//             calendarStyle: CalendarStyle(
//               // Today's date
//               todayDecoration: BoxDecoration(
//                 color:AppColor.themeColor.withOpacity(0.3),
//                 shape: BoxShape.circle,
//               ),
//               todayTextStyle: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: AppFont.fontFamily,
//                 color: Colors.black87,
//               ),

//               // Selected date
//               selectedDecoration: BoxDecoration(
//                 color:AppColor.themeColor,
//                 shape: BoxShape.circle,
//               ),
//               selectedTextStyle: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w700,
//                 fontFamily: AppFont.fontFamily,
//                 color: Colors.white,
//               ),

//               // Default date style
//               defaultTextStyle: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 fontFamily: AppFont.fontFamily,
//                 color: Colors.black87,
//               ),

//               // Weekend style
//               weekendTextStyle: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 fontFamily: AppFont.fontFamily,
//                 color: Colors.black87,
//               ),

//               // Outside month dates
//               outsideTextStyle: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w400,
//                 fontFamily: AppFont.fontFamily,
//                 color: Colors.grey.shade400,
//               ),

//               // Cell padding
//               cellMargin: EdgeInsets.all(6),
//             ),
//           ),

//           SizedBox(height: 24),

//                   // Guest Selection
//                   Text(
//                     'People',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: AppFont.fontFamily,
//                       color: Colors.black,
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   _guestSelector('Adults', adults, (value) {
//                     setState(() {
//                       adults = value;
//                     });
//                   }),
//                   Divider(color: AppColor.boaderColor,),
            
//                   _guestSelector('Child', children, (value) {
//                     setState(() {
//                       children = value;
//                     });
//                   }),
//                  Divider(color: AppColor.boaderColor,),
//                   SizedBox(height: 50),

//                   // Book Now Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         // Handle booking
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColor.themeColor,
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(25),
//                         ),
//                       ),
//                       child: Text(
//                         'Next',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: AppFont.fontFamily,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 150),
//         ]),
//       ),
//     )));
//   }

//   Widget _legendItem(String label, Color? dotColor) {
//     return Row(
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//             fontFamily: AppFont.fontFamily,
//             color: Colors.black87,
//           ),
//         ),
//         if (dotColor != null) ...[
//           SizedBox(width: 6),
//           Container(
//             width: 10,
//             height: 10,
//             decoration: BoxDecoration(
//               color: dotColor,
//               shape: BoxShape.circle,
//             ),
//           ),
//         ],
//       ],
//     );
//   }

//     Widget _guestSelector(String label, int count, Function(int) onChanged) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w400,
//             fontFamily: AppFont.fontFamily,
//             color: Colors.black87,
//           ),
//         ),
//         Row(
//           children: [
//             IconButton(
//               onPressed: () {
//                 if (count > 0) onChanged(count - 1);
//               },
//               icon: Container(
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(Icons.remove, size: 18),
//               ),
//             ),
//             SizedBox(
//               width: 40,
//               child: Text(
//                 '$count',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: AppFont.fontFamily,
//                 ),
//               ),
//             ),
//             IconButton(
//               onPressed: () {
//                 onChanged(count + 1);
//               },
//               icon: Container(
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   color:AppColor.themeColor,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(Icons.add, size: 18, color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//     void _showCancellationPolicyDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Padding(
//             padding: EdgeInsets.all(16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Title
//                 Text(
//                   'Cancellation policy',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     fontFamily: AppFont.fontFamily,
//                     color:AppColor.themeColor,
//                   ),
//                 ),
//                 SizedBox(height: 12),

//                 // Policy text
//                 Text(
//                   'Cancellations made more than 5 days before the check-in date will receive a full refund of the total booking amount. Cancellations made between 2 to 5 days before the check-in date will receive a 50% refund. No refunds will be issued for cancellations made within 2 days of the check-in date.',
//                   style: TextStyle(
//                     fontSize: 13.8,
//                     fontWeight: FontWeight.w400,
//                     fontFamily: AppFont.fontFamily,
//                     color: Colors.black87,
//                     height: 1.5,
//                   ),
//                 ),
//                 SizedBox(height: 16),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//     }
// }
