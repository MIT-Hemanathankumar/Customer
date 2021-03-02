import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class NetworkUtil {
  // next three lines makes this class a Singleton
  static NetworkUtil _instance = new NetworkUtil.internal();

  NetworkUtil.internal();

  factory NetworkUtil() => _instance;

  final JsonDecoder _decoder = new JsonDecoder();

  Future<bool> check() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  Future<dynamic> get(String url, String token) {
    print('$url $token');
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": 'bearer $token'
    };
    return http.get(url, headers: headers).then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Session Expired, Login Again",
            toastLength: Toast.LENGTH_LONG);
        return '401';
      } else if (statusCode < 200 || statusCode > 400 || json == null) {
        //throw new Exception("Error while fetching data");
        return 'Something went wrong';
      }
      return _decoder.convert(res);
    });
  }

  Future<dynamic> getMethod(String url) {
    Map<String, String> headers = {
      "Content-type": "application/json",
      //"Authorization": 'bearer $token'
    };
    return http.get(url, headers: headers).then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Session Expired, Login Again",
            toastLength: Toast.LENGTH_LONG);
        return '401';
      } else if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
  }

  Future<dynamic> postLogin(String url, {Map headers, body, encoding}) {
    return http
        .post(url, body: body, headers: headers, encoding: encoding)
        .then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
  }

  Future<dynamic> post(url,
      Map<String, dynamic> data,
      String token) {
    Map<String, String> head = {
      'Accept': 'application/json',
      'Content-type' : 'application/json',
      'Authorization': 'Bearer $token'
    };
    final j = json.encode(data);
    return http
        .post(url,
            body: j,
      headers: head)
        .then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Session Expired, Login Again",
            toastLength: Toast.LENGTH_LONG);
        return '401';
      } else if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
  }

  Future<dynamic> postSignup(url,
      Map<String, dynamic> data,) {
    Map<String, String> head = {
      'Accept': 'application/json',
      'Content-type' : 'application/json'
     // 'Authorization': 'Bearer $token'
    };
    final j = json.encode(data);
    return http
        .post(url,
        body: j,
        headers: head)
        .then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Session Expired, Login Again",
            toastLength: Toast.LENGTH_LONG);
        return '401';
      } else if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
  }


  Future<dynamic> postSign(
      String url,
      String deliveryId,
      String sign,
      String token) {
    Map<String, String> head = {
      'Accept': 'application/json',
      'Content-type' : 'application/json',
      'Authorization': 'Bearer $token'
    };
    Map<String, dynamic> jsonObject = {
      'deliveryId': int.parse(deliveryId),
      'baseSignature': sign,
    };
    final j = json.encode(jsonObject);
    return http
        .post(url,
        body: j,
        headers: head)
        .then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Session Expired, Login Again",
            toastLength: Toast.LENGTH_LONG);
        return '401';
      } else if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
  }


}
