import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_header.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';

class ContactUs extends StatefulWidget {
  static String routeName = "./ContactUs";
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController messageTextEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
          body: SafeArea(
              child: Container(
                  width: MediaQuery.of(context).size.width * 100 / 100,
                  height: MediaQuery.of(context).size.height * 100 / 100,
                  color: AppColor.secondaryColor,
                  child: Column(children: [
                    const NoInternetBanner(),
                    AppHeader(
                        text: AppLanguage.contactUsText[language],
                        onPress: () {
                          Navigator.pop(context);
                        }),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 2 / 100,
                    ),
                    Column(
                      children: [
                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 2 / 100),

                        // -----------first Number -------------
                        // CustomInputTextFormField(
                        //     readOnly: false,
                        //     fillColorStatus: 0,
                        //     controller: nameTextEditingController,
                        //     hintText: AppLanguage.nameInputText[language],
                        //     image: AppImage.userNameIcon,
                        //     keyboardtype: TextInputType.name,
                        //     maxLength: AppConstant.fullnameLength),

                        // SizedBox(
                        //     height:
                        //         MediaQuery.of(context).size.height * 1.5 / 100),

                        // // ----------- email Input -------------
                        // CustomInputTextFormField(
                        //     readOnly: false,
                        //     fillColorStatus: 0,
                        //     controller: emailTextEditingController,
                        //     hintText: AppLanguage.emailInputText[language],
                        //     image: AppImage.emailcon,
                        //     keyboardtype: TextInputType.emailAddress,
                        //     maxLength: AppConstant.emailMaxLength),
                        // SizedBox(
                        //     height:
                        //         MediaQuery.of(context).size.height * 3 / 100),

                        // ----------- Message Input -------------
                        Container(
                          width: MediaQuery.of(context).size.width * 90 / 100,
                          child: TextFormField(
                            style:
                                TextStyle(height: 1, color: AppColor.textColor),
                            keyboardType: TextInputType.multiline,
                            controller: messageTextEditingController,
                            maxLines: 7,
                            maxLength: AppConstant.describeLength,
                            decoration: InputDecoration(
                                prefixIcon: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              5 /
                                              100,
                                      width: MediaQuery.of(context).size.width *
                                          5 /
                                          100,
                                      child: Image.asset(
                                        AppImage.editIcon,
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                11 /
                                                100),
                                  ],
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(11)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(11)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(11)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 15),
                                fillColor: AppColor.secondaryColor,
                                filled: true,
                                counterText: '',
                                hintText: AppLanguage.descriptionText[language],
                                hintStyle: AppConstant.textFilledStyle),
                          ),
                        ),

                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 5 / 100),
                        AppButton(
                            text: AppLanguage.submitButtonText[language],
                            onPress: () {
                              Navigator.pop(
                                context,
                              );
                            }),
                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 5 / 100),
                      ],
                    )
                  ])))),
    );
  }
}
