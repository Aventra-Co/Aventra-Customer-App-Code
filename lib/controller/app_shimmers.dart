import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'app_color.dart';
import 'app_constant.dart';

Widget exploreShimmerEffect(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  return Container(
    alignment: Alignment.center,
    width: MediaQuery.of(context).size.width * 100 / 100,
    child: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            width: screenWidth > 600
                ? MediaQuery.of(context).size.width * 95 / 100
                : MediaQuery.of(context).size.width * 90 / 100,
            height: MediaQuery.of(context).size.height * 18 / 100,
            margin: const EdgeInsets.only(top: 15),
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 5 / 100),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32))),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 2 / 100),

          //activity list
          Container(
            width: MediaQuery.of(context).size.width * 100 / 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                children: List.generate(3, (index) {
                  return Padding(
                      padding: EdgeInsets.only(
                          left: index == 0
                              ? screenWidth > 600
                                  ? 20
                                  : 18
                              : 10,
                          right: index == 3 - 1 ? 10 : 0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        child: Container(
                          child: Text(
                            "adfafdsdfasdfasdf",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                      ));
                }),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 3 / 100),

          //carousel
          Container(
            width: MediaQuery.of(context).size.width * 0.75,
            height: screenWidth > 600
                ? MediaQuery.of(context).size.height * 0.28
                : MediaQuery.of(context).size.height * 0.21,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(13)),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 3 / 100),

          Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 100 / 100,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    children: List.generate(3, (index) {
                      return Container(
                        padding: language == 1
                            ? EdgeInsets.only(
                                right: index == 0
                                    ? screenWidth > 600
                                        ? 20
                                        : 18
                                    : 10,
                                left: index == 3 - 1 ? 10 : 0)
                            : EdgeInsets.only(
                                left: index == 0
                                    ? screenWidth > 600
                                        ? 20
                                        : 18
                                    : 10,
                                right: index == 3 - 1 ? 10 : 0),
                        child: Row(
                          children: [
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 40 / 100,
                              height:
                                  MediaQuery.of(context).size.height * 25 / 100,
                              padding: language == 1
                                  ? const EdgeInsets.only(right: 15)
                                  : const EdgeInsets.only(left: 15),
                              decoration: BoxDecoration(
                                  color: Colors.grey[300]!,
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 2 / 100),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget myTripShimmerEffect(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: List.generate(
            5, // Number of shimmer items to show
            (index) => Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 18 / 100,
                          height: MediaQuery.of(context).size.height * 13 / 100,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 3),
                          decoration: BoxDecoration(
                              color: Colors.grey[300]!,
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 70 / 100,
                          height: MediaQuery.of(context).size.height * 13 / 100,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 15),
                          decoration: BoxDecoration(
                              color: Colors.grey[300]!,
                              borderRadius: BorderRadius.circular(16)),
                        )
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 2 / 100,
                    ),
                  ],
                )),
      ),
    ),
  );
}

Widget favGridShimmerEffect(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      width: MediaQuery.of(context).size.width * 90 / 100,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10.0,
        children: List.generate(6, (index) {
          return Container(
            width: MediaQuery.of(context).size.width * 44 / 100,
            height: MediaQuery.of(context).size.height * 25 / 100,
            decoration: BoxDecoration(
                color: Colors.grey[300]!,
                borderRadius: BorderRadius.circular(20)),
          );
        }),
      ),
    ),
  );
}

Widget tripsShimmerEffect(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: List.generate(
            3, // Number of shimmer items to show
            (index) => Column(
                  children: [
                    if (index == 0)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100,
                      ),
                    Container(
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      height: MediaQuery.of(context).size.height * 20 / 100,
                      padding: language == 1
                          ? const EdgeInsets.only(top: 12, right: 12)
                          : const EdgeInsets.only(top: 12, left: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300]!,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 2 / 100,
                    ),
                  ],
                )),
      ),
    ),
  );
}

Widget notificationShimmerEffect(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width * 100 / 100,
      child: Column(
        children: [
          Wrap(
            children: List.generate(
              5,
              (index) {
                return Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 2 / 100,
                    ),
                    Container(
                      color: AppColor.secondaryColor,
                      child: Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 2 / 100,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 10 / 100,
                            height:
                                MediaQuery.of(context).size.width * 10 / 100,
                            color: Colors.grey[300]!,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 3 / 100,
                          ),
                          Column(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width *
                                    78 /
                                    100,
                                height: MediaQuery.of(context).size.height *
                                    4 /
                                    100,
                                color: Colors.grey[300]!,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width *
                                    78 /
                                    100,
                                height: MediaQuery.of(context).size.height *
                                    4 /
                                    100,
                                color: Colors.grey[300]!,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    //! ==== Boader ===
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      child: const Divider(
                        thickness: 1,
                        color: AppColor.boaderColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // User info shimmer
        ],
      ),
    ),
  );
}

Widget bookingHistoryShimmerEffect(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      children: List.generate(
          5, // Number of shimmer items to show
          (index) => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        height: MediaQuery.of(context).size.height * 13 / 100,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 15),
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16)),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Row(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width *
                                    20 /
                                    100,
                                height: MediaQuery.of(context).size.width *
                                    20 /
                                    100,
                                decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 2 / 100,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100,
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        40 /
                                        100,
                                    height: MediaQuery.of(context).size.width *
                                        6 /
                                        100,
                                    color: Colors.grey[300],
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100,
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        40 /
                                        100,
                                    height: MediaQuery.of(context).size.width *
                                        6 /
                                        100,
                                    color: Colors.grey[300],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 2 / 100,
                  ),
                ],
              )),
    ),
  );
}
