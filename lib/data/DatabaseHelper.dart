import 'dart:async';
import 'dart:ffi';
import 'dart:io' as io;
import 'dart:math';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:user/model/User.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = new DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  static Database _db;

  Future<Database> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  DatabaseHelper.internal();

  initDb() async {
    var theDb = await openDatabase("login.db", version: 1, onCreate: _onCreate);
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    await db.execute(
        "CREATE TABLE User(id INTEGER PRIMARY KEY, userId TEXT, token TEXT, name TEXT, email TEXT, mobile TEXT)");
    print("Created tables");
  }

  Future<void> saveUser(User user) async {
    var dbClient = await db;
   // int res = await dbClient.insert("User", user.toMap());
    await dbClient.insert(
      'User',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteUsers() async {
    var dbClient = await db;
    int res = await dbClient.delete("User");
    return res;
  }

  Future<String> getData() async {
    var dbClient = await db;
    var res = await dbClient.query("User");
    if(res.length> 0) {
      List<Map<String, dynamic>> maps = await dbClient.query('User');
      User u = new User(maps[0]['userId'], maps[0]['token'], maps[0]['name'], maps[0]['email']
          , maps[0]['mobile']);
      return u.toString();
    }else{
      return null;
    }
  }

  Future<dynamic> getAll() async{
    var client = await db;
    var res = await client.query('User');

    if (res.isNotEmpty) {
      var cars = res.map((carMap) => User.fromMap(carMap)).toList();
     // List<User> list = res.cast<User>();
      return res;
    }
    return [];
  }

  Future<bool> isLoggedIn() async {
    var dbClient = await db;
    var res = await dbClient.query("User");
    return res.length > 0 ? true : false;
  }
}
