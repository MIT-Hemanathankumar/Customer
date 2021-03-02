//MARK: URL CONSTANTS
import 'package:flutter/material.dart';

const kBaseUrl = 'https://beta.repeatclick.com/api/api/v1/';
const kImagebaseUrl = 'https://beta.repeatclick.com/api/api/v1/';
const kUrlToLogin = kBaseUrl + 'cuslogin';
const kUrlToRegister = kBaseUrl + 'register';
const kUrlToOtpVerify = kBaseUrl + 'otp_verification';
const kUrlToForgetPassword = kBaseUrl + 'cusforgotpassword';
const kUrlToGetBannerImages = kBaseUrl + 'bannerimages';
const kUrlToCreateChangePass = kBaseUrl + 'updatepassword';

//MARK:- HEADERS
const kHeader = {"Content-Type": "application/json"};

//MARK: SHARED PREFERENCES KEYS CONSTANT

const kUserLoggedInKey = 'userLoggedInStatus';
const kUserIdKey = 'userId';
const kUserDetailsKey = 'userDetails';

//MARK:- COLOURS
const kTealish =  Color(0xFFF8A340);
const kYellowish = Color(0xFFf5e01e);
const kTheme = Color(0xFFF8A340);
const karkblueish = Color(0xFF041f54);

//MARK:- FONTS STYLE
const kTextFieldTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 18.0,
    fontFamily: 'CalibriRegular',
    fontWeight: FontWeight.normal);

const kButtonTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 18.0,
  fontWeight: FontWeight.bold,
  fontFamily: 'CalibriBold',
);
