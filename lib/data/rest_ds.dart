import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:user/model/User.dart';
import 'package:user/util/network_utils.dart';

class RestDatasource {
  NetworkUtil _netUtil = new NetworkUtil();
  //demo
  static final String DEMO_BASE_URL = "http://3.7.102.61/pharmatiseapi/api/v1/";
  //live
  //static final String DEMO_BASE_URL = "https://beta.repeatclick.com/api/api/v1/";

  static final LOGIN_URL = DEMO_BASE_URL + "Customer/Login?";
  static final ORDER_HISTORY_LIST_URL = DEMO_BASE_URL + "Customer/Orders";
  static final PROFILE_LIST_URL = DEMO_BASE_URL + "Customer/Profile";
  static final CHANGE_PASSWORD_LIST_URL = DEMO_BASE_URL + "Customer/ChangePassword";
  static final Customer_Medicines_LIST_URL = DEMO_BASE_URL + "Customer/Medicines";
  static final PLACE_ORDER_LIST_URL = DEMO_BASE_URL + "Customer/OrderCreation";
  static final COUNTRY_LIST_URL = DEMO_BASE_URL + "Customer/Countries";
  static final PHARMACY_LIST_URL = DEMO_BASE_URL + "Customer/Pharmacy";
  static final DELIVERY_STATUS_UPDATE_URL = DEMO_BASE_URL + "Delivery/";
  static final DELIVERY_SIGNATURE_UPLOAD_URL = DEMO_BASE_URL + "Delivery/Acknowledge";
  static final SIGNUP_URL = DEMO_BASE_URL + "Customer/Register";
  static final CHECK_EMAIL_VALIDATION_URL = DEMO_BASE_URL + "Customer/ValidateEmail?EmailAccount=";
  static final CHECK_MOBILE_VALIDATION_URL = DEMO_BASE_URL + "Customer/ValidateMobile?MobileNumber=";
  static final HOME_WIDGETS_URL = DEMO_BASE_URL + "attendance/homedata.php?";
  static final PAYMENT_EXEMPTION_URL = DEMO_BASE_URL + "Customer/PaymentExemptions";
  static final COUNTRY_URL = DEMO_BASE_URL + "Customer/Countries";
  static final UPDATE_PROFILE_URL = DEMO_BASE_URL + "Customer/UpdateProfile";
  static final SEND_TOKEN_URL = DEMO_BASE_URL + "Customer/CreateToken";
  static final FORGOT_PASSWORD_URL = DEMO_BASE_URL + "Customer/ForgotPassword?customerEmail=";
  static final MASTER_MEDICINE_URL = DEMO_BASE_URL + "Customer/MasterMedicines?medicineName=";
  static final EXEMPTION_URL = DEMO_BASE_URL + "Customer/PaymentExemptions?pharmacyId=";
  static final SURGERYLIST_URL = DEMO_BASE_URL + "Customer/SurgeryList?pharmacyId=";
  static final SEND_CHAT_URL = DEMO_BASE_URL + "Customer/chat?mesage=";

  Future<Map<String, Object>> loginGetMethod(String username, String password) {
    return _netUtil
        .postLogin(LOGIN_URL + "username=" + username + "&password=" + password)
        .then((dynamic res) {
      //  if (res == null) throw new Exception(res["error_msg"]);

      return res;
    });
  }

  Future<Map<String, Object>> deliverylistGetMethod(
      String userId, String token) {
    return _netUtil.get(ORDER_HISTORY_LIST_URL, token).then((dynamic res) {
      //print(res.toString());
      // if (res == null) throw new Exception(res["error_msg"]);

      return res;
    });
  }


  Future<Map<String, Object>> countrylistGetMethod() {
    return _netUtil.getMethod(COUNTRY_LIST_URL).then((dynamic res) {
      //print(res.toString());
      // if (res == null) throw new Exception(res["error_msg"]);

      return res;
    });
  }


  Future<Map<String, Object>> pharmacylistGetMethod(String pincode) {
    return _netUtil.getMethod(PHARMACY_LIST_URL + "?searchValue=" + pincode).then((dynamic res) {
      //print(res.toString());
      // if (res == null) throw new Exception(res["error_msg"]);

      return res;
    });
  }

  Future<Map<String, Object>> signup(
      Map<String, dynamic> map) {
    return _netUtil
        .postSignup(SIGNUP_URL, map)
        .then((dynamic res) {
      //print(res.toString());
      // if (res == null) throw new Exception(res["error_msg"]);

      return res;
    });
  }

  Future<Map<String, Object>> deliverySignUpload(
      String deliveryId,
      String sign,
      String token) {
    return _netUtil
        .postSign(DELIVERY_SIGNATURE_UPLOAD_URL, deliveryId, sign, token)
        .then((dynamic res) {
      //print(res.toString());
      // if (res == null) throw new Exception(res["error_msg"]);

      return res;
    });
  }

  Future<http.Response> deliveryListGetMethod(String userId, String token) {
    return http.post(
      ORDER_HISTORY_LIST_URL,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'userId': userId,
        'token': token,
      }),
    );
  }

  Future<Map<String, dynamic>> homeMenu(String userId, String token) {
    return _netUtil
        .get(HOME_WIDGETS_URL + "userId=" + userId, token)
        .then((dynamic res) {
      print(res.toString());
      //  if (res == null) throw new Exception(res["error_msg"]);

      return res;
    });
  }

  Future getHomeData(String userId, String userType) {
    var url = HOME_WIDGETS_URL + "userId=" + userId + "&userType=" + userType;
    return http.get(url);
  }

  Future<User> login(String username, String password) {
    return _netUtil.postLogin(LOGIN_URL,
        body: {"username": username, "password": password}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["error_msg"]);
      return new User.map(res["user"]);
    });
  }
}
