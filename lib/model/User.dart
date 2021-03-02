import 'dart:ffi';

class User {
  String _userId;
  String _token;
  String _name;
  String _email;
  String _mobile;

  User(this._userId, this._token, this._name,
      this._email, this._mobile);

  User.map(dynamic obj) {
    this._userId = obj["userId"];
    this._token = obj["token"];
    this._name = obj["name"];
    this._email = obj["email"];
    this._mobile = obj["mobile"];
  }

  String get userId => userId;

  String get token => token;

  String get name => name;

  String get email => email;

  String get mobile => mobile;

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["userId"] = userId;
    map["token"] = token;
    map["name"] = name;
    map["email"] = email;
    map["mobile"] = mobile;

    return map;
  }

  factory User.fromMap(Map<String, dynamic> json) {
    return User(json['userId'], json['token'],
        json['name'], json['email'], json['mobile']);
  }
}
