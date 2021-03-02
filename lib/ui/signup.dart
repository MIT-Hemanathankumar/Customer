import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_picker_view/picker_view.dart';
import 'package:flutter_picker_view/picker_view_popup.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rounded_date_picker/rounded_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/customview/bottombar/fancy_bottom_navigation.dart';
import 'package:user/data/rest_ds.dart';
import 'package:user/presenter/country_list_presenter.dart';
import 'package:user/presenter/login_screen_presenter.dart';
import 'package:user/presenter/pharmacy_list_presenter.dart';
import 'package:user/ui/login_screen.dart';
import 'package:user/ui/main_page.dart';
import 'package:user/ui/search_pharma.dart';
import 'package:user/ui/signup_page.dart';
import 'package:user/util/constants.dart';

import '../data/AuthState.dart';
import '../data/DatabaseHelper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';

const CameraAccessDenied = 'PERMISSION_NOT_GRANTED';

/// method channel.
const MethodChannel _channel = const MethodChannel('qr_scan');

/// Scanning Bar Code or QR Code return content
Future<String> scan() async => await _channel.invokeMethod('scan');

/// Scanning Photo Bar Code or QR Code return content
Future<String> scanPhoto() async => await _channel.invokeMethod('scan_photo');

// Scanning the image of the specified path
Future<String> scanPath(String path) async {
  assert(path != null && path.isNotEmpty);
  Fluttertoast.showToast(
      msg: "This is Center Short Toast",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIos: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0);
  return await _channel.invokeMethod('scan_path', {"path": path});
}

// Parse to code string with uint8list
Future<String> scanBytes(Uint8List uint8list) async {
  assert(uint8list != null && uint8list.isNotEmpty);
  return await _channel.invokeMethod('scan_bytes', {"bytes": uint8list});
}

/// Generating Bar Code Uint8List
Future<Uint8List> generateBarCode(String code) async {
  assert(code != null && code.isNotEmpty);
  return await _channel.invokeMethod('generate_barcode', {"code": code});
}

class BasicSignupScreen extends StatefulWidget {
  static String tag = 'login-screen';
  CountryListPresenter _presenter;

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new BasicSignupState();
  }
}

class BasicSignupState extends State<BasicSignupScreen>
    implements LoginScreenContract, AuthStateListener, PharmacyListCotract {
  BuildContext _ctx;
  Future<File> imageFile;
  double opacity = 0.0;
  bool isMobileAlreadyAval = true;
  bool isEmailAlreadyAval = true;
  String isMobileAlreadyAvalMessage = "";
  String isEmailAlreadyAvalMessage = "";

  bool _isLoading = false;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController fnameController = TextEditingController();
  TextEditingController mnameController = TextEditingController();
  TextEditingController lnameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController nhsController = TextEditingController();
  TextEditingController pincodeController = TextEditingController();
  String _fName, _lName, _mName, _contact, _email, _nhs, _pincode;

  LoginScreenPresenter _presenter;
  PharmacyListPresenter _pharmacyListPresenter;
  String genderValue, titleValue;
  String dob = "Select Date of Birth";
  List menuItems = List();
  String _mySelection = 'Select Pharmacy', pharmacyrid, branchId;
  List pharmacyIdList = List();
  List branchIdList = List();
  List pincodeList = List();
  final focusfName = FocusNode();
  final focusmName = FocusNode();
  final focuslName = FocusNode();
  final focusContact = FocusNode();
  final focusEmail = FocusNode();
  final focusNhs = FocusNode();
  final focuspostalcode = FocusNode();
  var notdeliveryColor = const Color(0xFFE66363);
  var deliverColor = const Color(0xFF0071BC);
  var deliveredColor = const Color(0xFF4AC66E);
  var yetToStartColor = const Color(0xFFF8A340);

  String surgeryType, exemptionType;
  String surgeryId, exemptionId;
  List<dynamic> surgeryOptionlist = [];
  List<dynamic> exemptionOptionlist = [];
  bool showInsurance = true;

  ProgressDialog progressDialog;
  int currentPage = 0;
  GlobalKey bottomNavigationKey = GlobalKey();

  LoginScreenState() {
    _presenter = new LoginScreenPresenter(this);

    progressDialog = new ProgressDialog(context);
    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);
    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
  }

  pickImageFromGallery(ImageSource source) {
    setState(() {
      imageFile = ImagePicker.pickImage(source: source);
    });
  }

  Widget showImage() {
    return FutureBuilder<File>(
      future: imageFile,
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return Image.file(
            snapshot.data,
            width: 300,
            height: 300,
          );
        } else if (snapshot.error != null) {
          return const Text(
            'Error Picking Image',
            textAlign: TextAlign.center,
          );
        } else {
          return const Text(
            'No Image Selected',
            textAlign: TextAlign.center,
          );
        }
      },
    );
  }

  void _asyncConfirmDialog(String mes) {
    showDialog<ConfirmAction>(
      context: _ctx,
      barrierDismissible: false, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(mes),
          actions: <Widget>[
            FlatButton(
              child: const Text('Close'),
              onPressed: () async {
                Navigator.pop(_ctx);
              },
            )
          ],
        );
      },
    );
    // progressDialog.show();
  }

  void _submit() {
    final form = formKey.currentState;
    if (_pincode == null) {
      _showSnackBar('Enter Postal Code');
      return;
    }
    if (_email == null) {
      _showSnackBar('Enter Email');
      return;
    }
    if (isEmailAlreadyAval == true) {
      _showSnackBar('Email Already exist');
      return;
    }
    if (_contact == null) {
      _showSnackBar('Enter Contact');
      return;
    }
    if (isMobileAlreadyAval == true) {
      _showSnackBar('Mobile number Already exist');
      return;
    }
    /*if (_nhs == null) {
      _showSnackBar('Enter NHS ID');
      return;
    }*/
    if (dob == 'Select Date of Birth') {
      _showSnackBar('Select Date of Birth');
      return;
    }
    if (genderValue == null) {
      _showSnackBar('Select Gender');
      return;
    }
    if (titleValue == null) {
      _showSnackBar('Select Title');
      return;
    }
    if (_fName == null) {
      _showSnackBar('Enter First Name');
      return;
    }
    if (_mName == null) {
      _mName = "";
      // _showSnackBar('Enter Middle Name');
      // return;
    }
    if (_lName == null) {
      _showSnackBar('Enter Last Name');
      return;
    }
    /* if (pharmacyrid == null) {
      _asyncConfirmDialog(
          'Select Pharmacy.If pharmacy not fund, change Postal code');
      return;
    }*/
    if (form.validate()) {
      // setState(() => _isLoading = true);
      if (_fName.isNotEmpty &&
          _lName.isNotEmpty &&
          _contact.isNotEmpty &&
          _email.isNotEmpty &&
          //  _nhs.isNotEmpty &&
          _pincode.isNotEmpty) {
        form.save();
        if (genderValue != null && genderValue.isNotEmpty) {
          if (dob != 'Select Date of Birth') {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SignupPage(
                      fName: _fName,
                      mName: _mName,
                      lName: _lName,
                      contact: _contact,
                      email: _email,
                      nhs: _nhs,
                      pincode: _pincode,
                      pharmacyrid: pharmacyrid,
                      branchId: branchId,
                      gender: genderValue,
                      dob: dob,
                      titleValue: titleValue)),
            );
          } else {
            _showSnackBar('Select Date of Birth');
          }
        } else {
          _showSnackBar('Select Gender');
        }
      }
    }
  }

  void _showSnackBar(String text) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0);
    // scaffoldKey.currentState
    //   .showSnackBar(new SnackBar(content: new Text(text)));
  }

  String validateEmail(String value) {
    if (value.isNotEmpty) {
      return "Email Already exist";
    }
    return null;
  }

  String validateMobile(String value) {
    if (value.isNotEmpty) {
      return "Mobile Already exist";
    }
    return null;
  }

  @override
  onAuthStateChanged(AuthState state) {
    if (state == AuthState.LOGGED_IN)
      Navigator.of(_ctx).pushReplacementNamed("/home");
  }

  void init() async {
    _pharmacyListPresenter = new PharmacyListPresenter(this);
    var db = new DatabaseHelper();
    var isLoggedIn = await db.isLoggedIn();
    //progressDialog.show();
    // _pharmacyListPresenter.doPharmacyList("");
    // progressDialog.show();
    // _pharmacyListPresenter.doPharmacyList();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    progressDialog = new ProgressDialog(context);

    /*SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.black, statusBarBrightness: Brightness.light));*/
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    var db = new DatabaseHelper();
    //var list = db.getAll();
    // List<User> list = db.getAll() as List<User>;
    // Fluttertoast.showToast(msg: "w", toastLength: Toast.LENGTH_LONG);

    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);

    /*    surgeryOptionlist.clear();
    surgeryOptionlist.add("Borth Pharmacy");
    surgeryOptionlist.add("Vijay Pharmacy Lawspet");

   insuranceOptionlist.clear();
    insuranceOptionlist.add("Borth Surgery");
    insuranceOptionlist.add("Padarn Surgery");
    insuranceOptionlist.add("Church Surgery");
    insuranceOptionlist.add("Ystwyth Medical group");*/

    var loginBtn = Padding(
        padding: EdgeInsets.all(16.0),
        child: new ButtonTheme(
          minWidth: 230,
          height: 45,
          child: new RaisedButton(
            onPressed: _submit,
            child: new Text("SIGN UP"),
            color: yetToStartColor,
            textColor: Colors.white,
          ),
        ));

    var loginForm = new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Form(
          key: formKey,
          child: new Column(children: <Widget>[
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => _fName = val,
                    validator: (val) {
                      return val.trim().isEmpty ? "Enter First Name" : null;
                    },
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: false,
                    controller: fnameController,
                    onChanged: (_ctx) {
                      if (fnameController.text != null &&
                          fnameController.text.length > 0)
                        _fName = fnameController.text;
                    },
                    decoration: new InputDecoration(
                        labelText: "First Name",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusfName);
                    },
                  ),
                )),
            new Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                height: 45,
                child: new TextFormField(
                  onSaved: (val) => _mName = val,
                  keyboardType: TextInputType.visiblePassword,
                  focusNode: focusfName,
                  controller: mnameController,
                  onChanged: (_ctx) {
                    if (mnameController.text != null &&
                        mnameController.text.length > 0)
                      _mName = mnameController.text;
                  },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                  // initialValue: "Pdm@12345",
                  decoration: new InputDecoration(
                      labelText: "Middle Name",
                      border: new OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                              const Radius.circular(5.0)))),
                  onFieldSubmitted: (v) {
                    FocusScope.of(context).requestFocus(focusmName);
                  },
                ),
              ),
            ),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => _lName = val,
                    keyboardType: TextInputType.visiblePassword,
                    focusNode: focusmName,
                    controller: lnameController,
                    onChanged: (_ctx) {
                      if (lnameController.text != null &&
                          lnameController.text.length > 0)
                        _lName = lnameController.text;
                    },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                    // initialValue: "Pdm@12345",
                    decoration: new InputDecoration(
                        labelText: "Last Name",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focuslName);
                    },
                  ),
                )),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => _contact = val,
                    keyboardType: TextInputType.number,
                    focusNode: focuslName,
                    controller: contactController,
                    onChanged: (_ctx) {
                      if (contactController.text != null &&
                          contactController.text.length > 0) {
                        _contact = contactController.text;
                        checkMobile(_contact);
                      }
                    },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                    // initialValue: "Pdm@12345",
                    decoration: new InputDecoration(
                        labelText: "Contact Number",
                        errorText: validateMobile(isMobileAlreadyAvalMessage),
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusContact);
                    },
                  ),
                )),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => _email = val,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: focusContact,
                    controller: emailController,
                    onChanged: (_ctx) {
                      if (emailController.text != null &&
                          emailController.text.length > 0) {
                        _email = emailController.text;
                        checkEmail(_email);
                      }
                    },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                    // initialValue: "Pdm@12345",
                    decoration: new InputDecoration(
                        labelText: "Email ID",
                        errorText: validateEmail(isEmailAlreadyAvalMessage),
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusEmail);
                    },
                  ),
                )),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => _nhs = val,
                    keyboardType: TextInputType.visiblePassword,
                    focusNode: focusEmail,
                    controller: nhsController,
                    onChanged: (_ctx) {
                      if (nhsController.text != null &&
                          nhsController.text.length > 0)
                        _nhs = nhsController.text;
                    },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                    // initialValue: "Pdm@12345",
                    decoration: new InputDecoration(
                        labelText: "NHS ID",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusNhs);
                    },
                  ),
                )),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => () {
                      _pincode = val;
                    },
                    controller: pincodeController,
                    onChanged: (_ctx) {
                      if (pincodeController.text != null &&
                          pincodeController.text.length >= 6) {
                        _pincode = pincodeController.text;
                        setState(() {
                          _isLoading = true;
                        });
                        _pharmacyListPresenter.doPharmacyList(_pincode);
                      }
                    },
                    keyboardType: TextInputType.text,
                    // keyboardType: TextInputType.numberWithOptions(decimal: true),
                    textCapitalization: TextCapitalization.characters,
                    focusNode: focusNhs,
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                    // initialValue: "Pdm@12345",
                    decoration: new InputDecoration(
                        labelText: "Postal Code",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focuspostalcode);
                    },
                  ),
                )),
            new Center(
              child: _isLoading
                  ? new CircularProgressIndicator()
                  : SizedBox(height: 8.0),
            ),
            /*  new Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                        height: 45,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 1.0,
                                style: BorderStyle.solid,
                                color: Colors.grey),
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: menuItems != null && menuItems.length > 0 ? DropdownButton(
                                  underline: SizedBox(),
                                  items: menuItems.map((item) {
                                    return new DropdownMenuItem(
                                      child: new Text(
                                        item.toString(),
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.black),
                                      ),
                                      value: item.toString(),
                                    );
                                  }).toList(),
                                  hint: Text(
                                    "Select Pharmacy",
                                    style: TextStyle(
                                      color: Colors.black45,
                                    ),
                                  ),
                                  onChanged: (newVal) {
                                    setState(() {
                                      _mySelection = newVal;
                                      try {
                                        for (int i = 0;
                                            i < menuItems.length;
                                            i++) {
                                          if (menuItems[i].toString() ==
                                              _mySelection) {
                                            pharmacyrid = pharmacyIdList[i];
                                            branchId = branchIdList[i];
                                            break;
                                          }
                                        }
                                      } catch (e) {
                                        print(e);
                                      }
                                    });
                                  },
                                  value: _mySelection,
                                ):SizedBox(),
                              ),
                              flex: 1,
                            ),
                          ],
                        )),
                  ),
                  flex: 1,
                )
              ],
            ),
            new Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                        height: 45,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 1.0,
                                style: BorderStyle.solid,
                                color: Colors.grey),
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: DropdownButton<String>(
                                  value: genderValue,
                                  icon: Icon(Icons.arrow_drop_down),
                                  iconSize: 24,
                                  elevation: 16,
                                  style: TextStyle(color: Colors.black),
                                  underline: SizedBox(),
                                  onChanged: (String newValue) {
                                    setState(() {
                                      genderValue = newValue;
                                    });
                                  },
                                  items: <String>[
                                    'M',
                                    'F',
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    );
                                  }).toList(),
                                  hint: Text(
                                    "Select Gender",
                                    style: TextStyle(
                                      color: Colors.black45,
                                    ),
                                  ),
                                ),
                              ),
                              flex: 1,
                            ),
                          ],
                        )),
                  ),
                  flex: 1,
                )
              ],
            ),*/
            new Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                        height: 45,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 1.0,
                                style: BorderStyle.solid,
                                color: Colors.grey),
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: DropdownButton<String>(
                                  value: titleValue,
                                  icon: Icon(Icons.arrow_drop_down),
                                  iconSize: 24,
                                  elevation: 16,
                                  style: TextStyle(color: Colors.black),
                                  underline: SizedBox(),
                                  onChanged: (String newValue) {
                                    setState(() {
                                      titleValue = newValue;
                                    });
                                  },
                                  items: <String>[
                                    'Mr',
                                    'Mrs',
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    );
                                  }).toList(),
                                  hint: Text(
                                    "Select Title",
                                    style: TextStyle(
                                      color: Colors.black45,
                                    ),
                                  ),
                                ),
                              ),
                              flex: 1,
                            ),
                          ],
                        )),
                  ),
                  flex: 1,
                )
              ],
            ),
            new Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      height: 45,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              width: 1.0,
                              style: BorderStyle.solid,
                              color: Colors.grey),
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        ),
                      ),
                      child: InkResponse(
                        onTap: () async {
                          var formatter = new DateFormat('yyyy-MM-dd');
                          DateTime newDateTime = await showRoundedDatePicker(
                            context: context,
                            initialDate: DateTime(DateTime.now().year - 20),
                            firstDate: DateTime(DateTime.now().year - 99),
                            lastDate: DateTime.now(),
                            initialDatePickerMode: DatePickerMode.year,
                            theme: ThemeData(primarySwatch: Colors.deepOrange),
                          );
                          if (newDateTime != null) {
                            setState(() => dob = formatter.format(newDateTime));
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            dob,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  flex: 1,
                )
              ],
            ),
            loginBtn,
            /* showImage(),
            RaisedButton(
              child: Text("Select Image from Gallery"),
              onPressed: () {
                pickImageFromGallery(ImageSource.gallery);
              },
            ),*/
          ]),
        ),
        // _isLoading ? new CircularProgressIndicator() : SizedBox(height: 8.0),
      ],
    );
    const PrimaryColor = const Color(0xFFffffff);
    const titleColor = const Color(0xFF151026);
    return WillPopScope(
        child: Scaffold(
            appBar: AppBar(
              elevation: 0.5,
              backgroundColor: Colors.white,
              brightness: Brightness.light,
              iconTheme: IconThemeData(
                color: Colors.black, //c// hange your color here
              ),
              centerTitle: true,
              title:
                  const Text('SIGN UP', style: TextStyle(color: Colors.black)),
              leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    if (currentPage == 3) {
                      final FancyBottomNavigationState fState =
                          bottomNavigationKey.currentState;
                      setState(() {
                        currentPage = 2;
                      });
                      return false;
                    } else if (currentPage == 2) {
                      final FancyBottomNavigationState fState =
                          bottomNavigationKey.currentState;
                      setState(() {
                        currentPage = 1;
                      });
                      return false;
                    } else if (currentPage == 1) {
                      final FancyBottomNavigationState fState =
                          bottomNavigationKey.currentState;
                      setState(() {
                        currentPage = 0;
                      });
                      return false;
                    }
                    Navigator.pop(context, false);
                  }),
              // centerTitle: true,
            ),
            key: scaffoldKey,
            body: new Center(
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Center(
                    child: _getPage(currentPage),
                  ),
                ),
                /*SingleChildScrollView(
              child:
                  //height: double.infinity,
                  //color: Colors.white,
                  // child: new Center(
                  new Align(
                alignment: Alignment.center,
                child: loginForm,
              ),
            ),*/
              ),
            )),
        onWillPop: _onWillPop);
  }

  Future<bool> _onWillPop() async {
    if (currentPage == 3) {
      final FancyBottomNavigationState fState =
          bottomNavigationKey.currentState;
      setState(() {
        currentPage = 2;
      });
      return false;
    } else if (currentPage == 2) {
      final FancyBottomNavigationState fState =
          bottomNavigationKey.currentState;
      setState(() {
        currentPage = 1;
      });
      return false;
    } else if (currentPage == 1) {
      final FancyBottomNavigationState fState =
          bottomNavigationKey.currentState;
      setState(() {
        currentPage = 0;
      });
      return false;
    }
    return true;
  }

  medicenenme(String map) => {
        setState(() {
          _mySelection = map;
        })
      };

  void pharmadialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Pharmacy'),
            actions: [
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'))
            ],
            content: Container(
              //height: double.infinity,
              width: double.infinity,
              child: menuItems != null && menuItems.length > 0
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: menuItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        return InkWell(
                            onTap: () {
                              setState(() {
                                _mySelection = menuItems[index].toString();
                                pharmacyrid = pharmacyIdList[index];
                                branchId = branchIdList[index];
                              });
                              Navigator.pop(context);
                            },
                            child:
                                /* ListTile(
                            title: Text(menuItems[index].toString()),
                          ),*/
                                Container(
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                color: Colors.grey[200],
                                width: 1.0,
                              ))),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 10, right: 10, top: 15, bottom: 15),
                                child: RichText(
                                  text: new TextSpan(
                                    // Note: Styles for TextSpans must be explicitly defined.
                                    // Child text spans will inherit styles from parent
                                    style: new TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.black,
                                    ),
                                    children: <TextSpan>[
                                      new TextSpan(
                                          text: menuItems[index].toString(),
                                          style: new TextStyle()),
                                      pincodeList.length > 0 &&
                                              pincodeList[index] != null
                                          ? new TextSpan(
                                              text: ',  ' +
                                                  pincodeList[index].toString())
                                          : TextSpan(text: ''),
                                    ],
                                  ),
                                ),
                              ),
                            ));
                      },
                    )
                  : Text(
                      'Pharmacy List Empty',
                      style: TextStyle(color: Colors.orange),
                    ),
            ),
          );
        });
  }

  methodInParent(String name, String pid, String bid) => {
        setState(() {
          _mySelection = name;
          pharmacyrid = pid;
          branchId = bid;
        })
      };

  void _showTypePicker({List<String> items, BuildContext context}) {
    PickerController pickerController =
        PickerController(count: 1, selectedItems: [0]);

    PickerViewPopup.showMode(PickerShowMode.BottomSheet,
        controller: pickerController,
        context: context,
        title: Text(
          "Surgery",
          style: kButtonTextStyle,
        ),
        cancel: Text(
          'cancel',
          style: kButtonTextStyle.copyWith(color: Colors.red),
        ),
        onCancel: () {
          Scaffold.of(context).showSnackBar(
              SnackBar(content: Text('AlertDialogPicker.cancel')));
        },
        confirm: Text(
          'confirm',
          style: kButtonTextStyle.copyWith(color: kTealish),
        ),
        onConfirm: (controller) async {
          List<int> selectedItems = [];
          selectedItems.add(controller.selectedRowAt(section: 0));
          String selValue = items[controller.selectedRowAt(section: 0)];
          setState(() {
            surgeryId = surgeryOptionlist[controller.selectedRowAt(section: 0)]
                ['surgeryId'].toString();
            surgeryType = selValue;
          });
          //_showSnackBar(surgeryId.toString());
          Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('AlertDialogPicker.selected:$selectedItems')));
        },
        onSelectRowChanged: (section, row) {
          String selValue = items[row];
        },
        builder: (context, popup) {
          return Container(
            height: 200,
            child: popup,
          );
        },
        itemExtent: 40,
        numberofRowsAtSection: (section) {
          return items.length;
        },
        itemBuilder: (section, row) {
          return Text(
            items[row],
            style: kTextFieldTextStyle,
          );
        });
  }

  void _showInsurancePicker({List<String> items, BuildContext context}) {
    PickerController pickerController =
        PickerController(count: 1, selectedItems: [0]);

    PickerViewPopup.showMode(PickerShowMode.BottomSheet,
        controller: pickerController,
        context: context,
        title: Text(
          "NHS Exemption",
          style: kButtonTextStyle,
        ),
        cancel: Text(
          'cancel',
          style: kButtonTextStyle.copyWith(color: Colors.red),
        ),
        onCancel: () {
          Scaffold.of(context).showSnackBar(
              SnackBar(content: Text('AlertDialogPicker.cancel')));
        },
        confirm: Text(
          'confirm',
          style: kButtonTextStyle.copyWith(color: kTealish),
        ),
        onConfirm: (controller) async {
          List<int> selectedItems = [];
          selectedItems.add(controller.selectedRowAt(section: 0));
          String selValue = items[controller.selectedRowAt(section: 0)];
          setState(() {
            exemptionId =
                exemptionOptionlist[controller.selectedRowAt(section: 0)]
                    ['paymentExemptionId'].toString();
            exemptionType = selValue;
          });
         // _showSnackBar(exemptionId.toString());
          Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('AlertDialogPicker.selected:$selectedItems')));
        },
        onSelectRowChanged: (section, row) {
          String selValue = items[row];
        },
        builder: (context, popup) {
          return Container(
            height: 200,
            child: popup,
          );
        },
        itemExtent: 40,
        numberofRowsAtSection: (section) {
          return items.length;
        },
        itemBuilder: (section, row) {
          return Text(
            items[row],
            style: kTextFieldTextStyle,
          );
        });
  }

  _getPage(int page) {
    switch (page) {
      case 0:
        return Center(
            child: Hero(
          tag: "hero",
          child: Container(
              height: 370,
              child: ListView(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: Text('PICK YOUR PHARMACY',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        )),
                  ),
                  SizedBox(
                    height: 70,
                  ),
                  new Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        height: 45,
                        child: new TextFormField(
                          onSaved: (val) => () {
                            _pincode = val;
                          },
                          controller: pincodeController,
                          onChanged: (_ctx) {
                            if (pincodeController.text != null &&
                                pincodeController.text.length >= 6) {
                              _pincode = pincodeController.text;
                              setState(() {
                                _isLoading = true;
                              });
                              _pharmacyListPresenter.doPharmacyList(_pincode);
                            }
                          },
                          keyboardType: TextInputType.text,
                          // keyboardType: TextInputType.numberWithOptions(decimal: true),
                          textCapitalization: TextCapitalization.characters,
                          focusNode: focusNhs,
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                          // initialValue: "Pdm@12345",
                          decoration: new InputDecoration(
                              labelText: "Postal Code",
                              border: new OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                      const Radius.circular(5.0)))),
                          onFieldSubmitted: (v) {
                            FocusScope.of(context)
                                .requestFocus(focuspostalcode);
                          },
                        ),
                      )),
                  new Center(
                    child: _isLoading
                        ? new CircularProgressIndicator()
                        : SizedBox(height: 8.0),
                  ),
                  new Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Container(
                            height: 45,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    width: 1.0,
                                    style: BorderStyle.solid,
                                    color: Colors.grey),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5.0)),
                              ),
                            ),
                            child: InkResponse(
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SearchPharma(
                                          function: methodInParent)),
                                );
                                //pharmadialog();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: _mySelection != null
                                    ? Text(
                                        _mySelection,
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(''),
                              ),
                            ),
                          ),
                        ),
                        flex: 1,
                      )
                    ],
                  ),
                  Padding(
                      padding: EdgeInsets.all(16.0),
                      child: new ButtonTheme(
                        minWidth: 230,
                        height: 45,
                        child: new RaisedButton(
                          onPressed: () {
                            /* if (_pincode == null) {
                              _showSnackBar('Enter Postal Code');
                              return;
                            }*/
                            setState(() {
                              surgeryOptionlist.clear();
                              exemptionOptionlist.clear();
                              surgeryType = null;
                              exemptionType = null;
                            });
                            if (_mySelection == 'Select Pharmacy') {
                              _showSnackBar('Select Pharmacy');
                              return;
                            }
                            getExemption(pharmacyrid);
                            getSurgeryList(pharmacyrid);
                            /*if (pharmacyrid == "19") {
                              List<String> aa = [];
                              aa.add("Borth Surgery");
                              aa.add("Padarn Surgery");
                              aa.add("Church Surgery");
                              aa.add("Ystwyth Medical group");
                              List<String> bb = [];
                              bb.add("Do not pay-001");
                              bb.add("Do not pay-wales-002");
                              setState(() {
                                surgeryOptionlist.clear();
                                surgeryOptionlist.addAll(aa);
                                insuranceOptionlist.clear();
                                insuranceOptionlist.addAll(bb);
                                showInsurance = true;
                              });
                              _showInsurancePicker(
                                  items: aa, context: context);
                            } else if (pharmacyrid == "16") {
                              List<String> aaa = [];
                              aaa.add("Bharani SM");
                              aaa.add("Wesley");
                              aaa.add("Raghavan");
                              List<String> bb = [];
                              bb.add("250-Health-LIC");
                              setState(() {
                                surgeryOptionlist.clear();
                                surgeryOptionlist.addAll(aaa);
                                insuranceOptionlist.clear();
                                insuranceOptionlist.addAll(bb);
                                showInsurance = true;
                              });
                              _showInsurancePicker(
                                  items: aaa, context: context);
                            }else{
                              setState(() {
                                showInsurance = false;
                              });
                            }*/
                            setState(() {
                              currentPage = 1;
                            });
                            FocusScope.of(context).unfocus();
                          },
                          child: new Text("Next"),
                          color: yetToStartColor,
                          textColor: Colors.white,
                        ),
                      ))
                ],
              )),
        ));
      case 1:
        return Center(
            child: Hero(
          tag: "hero",
          child: Container(
              height: 370,
              child: ListView(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: Text('SURGERY & NHS EXEMPTION',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        )),
                  ),
                  SizedBox(
                    height: 70,
                  ),
                  InkWell(
                    onTap: () {
                      if (surgeryOptionlist.length > 0) {
                        List<String> surgelist = List();
                        for (int i = 0; i < surgeryOptionlist.length; i++) {
                          surgelist.add(surgeryOptionlist[i]['name']);
                        }
                        _showTypePicker(items: surgelist, context: context);
                      } else {
                        _showSnackBar("surgery/nhs exemption is not available");
                      }
                    },
                    child: new Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Colors.black))),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 10),
                                    child: Text(
                                      surgeryType != null
                                          ? surgeryType
                                          : "Select Surgery",
                                    )),
                                flex: 1,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Icon(
                                  Icons.arrow_drop_down,
                                ),
                              ),
                            ],
                          )),
                    ),
                  ),
                  new Center(
                    child: _isLoading
                        ? new CircularProgressIndicator()
                        : SizedBox(height: 8.0),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  InkWell(
                    onTap: () {
                      if (exemptionOptionlist.length > 0) {
                        List<String> surgelist = List();
                        for (int i = 0; i < exemptionOptionlist.length; i++) {
                          surgelist.add(exemptionOptionlist[i]['description']);
                        }
                        _showInsurancePicker(
                            items: surgelist, context: context);
                      } else {
                        _showSnackBar("surgery/nhs exemption is not available");
                      }
                    },
                    child: new Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Colors.black))),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 10),
                                    child: Text(
                                      exemptionType != null
                                          ? exemptionType
                                          : "Select NHS Exemption",
                                    )),
                                flex: 1,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Icon(
                                  Icons.arrow_drop_down,
                                ),
                              ),
                            ],
                          )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Please inform Pharmacy if your surgery/nhs exemption is not available in the list',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.all(16.0),
                      child: new ButtonTheme(
                        minWidth: 230,
                        height: 45,
                        child: new RaisedButton(
                          onPressed: () {
                            /* if (_pincode == null) {
                              _showSnackBar('Enter Postal Code');
                              return;
                            }*/
                            if (surgeryOptionlist.length > 0 &&
                                exemptionOptionlist.length > 0) {
                              if (surgeryType == null) {
                                _showSnackBar('Select Surgery');
                                return;
                              }
                            }
                            setState(() {
                              currentPage = 2;
                            });
                            FocusScope.of(context).unfocus();
                          },
                          child: new Text("Next"),
                          color: yetToStartColor,
                          textColor: Colors.white,
                        ),
                      ))
                ],
              )),
        ));
      case 2:
        return Center(
            child: Hero(
          tag: "hero",
          child: Container(
              height: 370,
              child: ListView(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: Text('LOGIN DETAILS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        )),
                  ),
                  SizedBox(
                    height: 70,
                  ),
                  new Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        height: 45,
                        child: new TextFormField(
                          onSaved: (val) => _email = val,
                          keyboardType: TextInputType.emailAddress,
                          // focusNode: focusContact,
                          textCapitalization: TextCapitalization.none,
                          controller: emailController,
                          onChanged: (_ctx) {
                            if (emailController.text != null &&
                                emailController.text.length > 0) {
                              _email = emailController.text;
                              checkEmail(_email);
                            }
                          },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                          // initialValue: "Pdm@12345",
                          decoration: new InputDecoration(
                              labelText: "Email ID",
                              //errorText: validateEmail(isEmailAlreadyAvalMessage),
                              border: new OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                      const Radius.circular(5.0)))),
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).requestFocus(focusEmail);
                          },
                        ),
                      )),
                  new Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        height: 45,
                        child: new TextFormField(
                          onSaved: (val) => _contact = val,
                          keyboardType: TextInputType.number,
                          focusNode: focusEmail,
                          controller: contactController,
                          onChanged: (_ctx) {
                            if (contactController.text != null &&
                                contactController.text.length > 0) {
                              _contact = contactController.text;
                              checkMobile(_contact);
                            }
                          },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                          // initialValue: "Pdm@12345",
                          decoration: new InputDecoration(
                              labelText: "Contact Number",
                              // errorText: validateMobile(isMobileAlreadyAvalMessage),
                              border: new OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                      const Radius.circular(5.0)))),
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).requestFocus(focusContact);
                          },
                        ),
                      )),
                  Padding(
                      padding: EdgeInsets.all(16.0),
                      child: new ButtonTheme(
                        minWidth: 230,
                        height: 45,
                        child: new RaisedButton(
                          onPressed: () {
                            if (_email == null) {
                              _showSnackBar('Enter Email');
                              return;
                            }
                            if (isEmailAlreadyAval == true) {
                              _showSnackBar('Email Already exist');
                              _emailDialog(emailController.text);
                              return;
                            }
                            if (_contact == null) {
                              _showSnackBar('Enter Contact');
                              return;
                            }
                            if (isMobileAlreadyAval == true) {
                              _showSnackBar('Mobile number Already exist');
                              return;
                            }
                            setState(() {
                              currentPage = 3;
                            });
                          },
                          child: new Text("Next"),
                          color: yetToStartColor,
                          textColor: Colors.white,
                        ),
                      ))
                ],
              )),
        ));
      case 3:
        return Center(
            child: Hero(
          tag: "hero",
          child: Container(
              //height: 370,
              child: ListView(
            children: [
              SizedBox(
                height: 20,
              ),
              Center(
                child: Text('PERSONAL INFORMATION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 16,
                    )),
              ),
              SizedBox(
                height: 40,
              ),
              Row(
                children: [
                  Expanded(
                    child: new Row(
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                                height: 45,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        width: 1.0,
                                        style: BorderStyle.solid,
                                        color: Colors.grey),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5.0)),
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10, right: 10),
                                        child: DropdownButton<String>(
                                          value: titleValue,
                                          icon: Icon(Icons.arrow_drop_down),
                                          iconSize: 24,
                                          elevation: 16,
                                          style: TextStyle(color: Colors.black),
                                          underline: SizedBox(),
                                          onChanged: (String newValue) {
                                            setState(() {
                                              titleValue = newValue;
                                            });
                                          },
                                          items: <String>[
                                            'Mr',
                                            'Mrs',
                                          ].map<DropdownMenuItem<String>>(
                                              (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                            );
                                          }).toList(),
                                          hint: Text(
                                            "Select Title",
                                            style: TextStyle(
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ),
                                      ),
                                      flex: 1,
                                    ),
                                  ],
                                )),
                          ),
                          flex: 1,
                        )
                      ],
                    ),
                    flex: 1,
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: new Row(
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                                height: 45,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        width: 1.0,
                                        style: BorderStyle.solid,
                                        color: Colors.grey),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5.0)),
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10, right: 10),
                                        child: DropdownButton<String>(
                                          value: genderValue,
                                          icon: Icon(Icons.arrow_drop_down),
                                          iconSize: 24,
                                          elevation: 16,
                                          style: TextStyle(color: Colors.black),
                                          underline: SizedBox(),
                                          onChanged: (String newValue) {
                                            setState(() {
                                              genderValue = newValue;
                                            });
                                          },
                                          items: <String>[
                                            'M',
                                            'F',
                                          ].map<DropdownMenuItem<String>>(
                                              (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                            );
                                          }).toList(),
                                          hint: Text(
                                            "Select Gender",
                                            style: TextStyle(
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ),
                                      ),
                                      flex: 1,
                                    ),
                                  ],
                                )),
                          ),
                          flex: 1,
                        )
                      ],
                    ),
                    flex: 1,
                  )
                ],
              ),
              new Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    height: 45,
                    child: new TextFormField(
                      onSaved: (val) => _fName = val,
                      validator: (val) {
                        return val.trim().isEmpty ? "Enter First Name" : null;
                      },
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: false,
                      controller: fnameController,
                      onChanged: (_ctx) {
                        if (fnameController.text != null &&
                            fnameController.text.length > 0)
                          _fName = fnameController.text;
                      },
                      decoration: new InputDecoration(
                          labelText: "First Name",
                          border: new OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                  const Radius.circular(5.0)))),
                      onFieldSubmitted: (v) {
                        FocusScope.of(context).requestFocus(focusfName);
                      },
                    ),
                  )),
              new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => _mName = val,
                    keyboardType: TextInputType.visiblePassword,
                    focusNode: focusfName,
                    controller: mnameController,
                    onChanged: (_ctx) {
                      if (mnameController.text != null &&
                          mnameController.text.length > 0)
                        _mName = mnameController.text;
                    },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                    // initialValue: "Pdm@12345",
                    decoration: new InputDecoration(
                        labelText: "Middle Name",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusmName);
                    },
                  ),
                ),
              ),
              new Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    height: 45,
                    child: new TextFormField(
                      onSaved: (val) => _lName = val,
                      keyboardType: TextInputType.visiblePassword,
                      focusNode: focusmName,
                      controller: lnameController,
                      onChanged: (_ctx) {
                        if (lnameController.text != null &&
                            lnameController.text.length > 0)
                          _lName = lnameController.text;
                      },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                      // initialValue: "Pdm@12345",
                      decoration: new InputDecoration(
                          labelText: "Last Name",
                          border: new OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                  const Radius.circular(5.0)))),
                      onFieldSubmitted: (v) {
                        FocusScope.of(context).requestFocus(focuslName);
                      },
                    ),
                  )),
              new Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    height: 45,
                    child: new TextFormField(
                      onSaved: (val) => _nhs = val,
                      keyboardType: TextInputType.visiblePassword,
                      focusNode: focuslName,
                      controller: nhsController,
                      onChanged: (_ctx) {
                        if (nhsController.text != null &&
                            nhsController.text.length > 0)
                          _nhs = nhsController.text;
                      },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                      // initialValue: "Pdm@12345",
                      decoration: new InputDecoration(
                          labelText: "NHS ID",
                          border: new OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                  const Radius.circular(5.0)))),
                      onFieldSubmitted: (v) {
                        FocusScope.of(context).requestFocus(focusNhs);
                      },
                    ),
                  )),
              new Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        height: 45,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 1.0,
                                style: BorderStyle.solid,
                                color: Colors.grey),
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                          ),
                        ),
                        child: InkResponse(
                          onTap: () async {
                            var formatter = new DateFormat('yyyy-MM-dd');
                            DateTime newDateTime = await showRoundedDatePicker(
                              context: context,
                              initialDate: DateTime(DateTime.now().year - 20),
                              firstDate: DateTime(DateTime.now().year - 99),
                              lastDate: DateTime.now(),
                              initialDatePickerMode: DatePickerMode.year,
                              theme:
                                  ThemeData(primarySwatch: Colors.deepOrange),
                            );
                            if (newDateTime != null) {
                              setState(
                                  () => dob = formatter.format(newDateTime));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              dob,
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    flex: 1,
                  )
                ],
              ),
              Padding(
                  padding: EdgeInsets.all(16.0),
                  child: new ButtonTheme(
                    minWidth: 230,
                    height: 45,
                    child: new RaisedButton(
                      onPressed: () {
                        if (genderValue == null) {
                          _showSnackBar('Select Gender');
                          return;
                        }
                        if (titleValue == null) {
                          _showSnackBar('Select Title');
                          return;
                        }
                        if (_fName == null) {
                          _showSnackBar('Enter First Name');
                          return;
                        }
                        if (_mName == null) {
                          _mName = "";
                          // _showSnackBar('Enter Middle Name');
                          // return;
                        }
                        if (_lName == null) {
                          _showSnackBar('Enter Last Name');
                          return;
                        }
                        if (_nhs == null || _nhs == '') {
                          _nhs = "0";
                          // _showSnackBar('Enter NHS ID');
                          // return;
                        }
                        if (dob == 'Select Date of Birth') {
                          _showSnackBar('Select Date of Birth');
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignupPage(
                                  fName: _fName,
                                  mName: _mName,
                                  lName: _lName,
                                  contact: _contact,
                                  email: _email,
                                  nhs: _nhs,
                                  pincode: _pincode,
                                  pharmacyrid: pharmacyrid,
                                  branchId: branchId,
                                  gender: genderValue,
                                  dob: dob,
                                  surgeryOption: surgeryId,
                                  nhsExemptionOption: exemptionId,
                                  titleValue: titleValue)),
                        );
                      },
                      child: new Text("Next"),
                      color: yetToStartColor,
                      textColor: Colors.white,
                    ),
                  ))
            ],
          )),
        ));
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text("Default"),
          ],
        );
    }
  }

  Future<Map<String, Object>> checkEmail(String email) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-type': 'application/json',
    };

    final response = await http.get(
        RestDatasource.CHECK_EMAIL_VALIDATION_URL + email,
        headers: headers);
    setState(() {
      _isLoading = false;
    });
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          print(data.toString());
          var status = data['status'];
          var uName = data['message'];
          try {
            if (status == true) {
              setState(() {
                isEmailAlreadyAval = false;
                isEmailAlreadyAvalMessage = "";
              });
            } else {
              setState(() {
                isEmailAlreadyAval = true;
                isEmailAlreadyAvalMessage = uName;
              });
              _emailDialog(email);
            }
          } catch (e) {
            _showSnackBar(e.toString());
          }
        }
      } catch (e) {
        _showSnackBar(e.toString());
      }
    } else if (response.statusCode == 401) {
      _showSnackBar('Something went wrong');
    } else {
      _showSnackBar('Something went wrong');
    }
  }

  Future<Map<String, Object>> getExemption(String email) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-type': 'application/json',
    };

    final response =
        await http.get(RestDatasource.EXEMPTION_URL + email, headers: headers);
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
           print(json.encode(data));
          try {
            setState(() {
              exemptionOptionlist = data['list'];
            });
          } catch (e) {
            _showSnackBar(e.toString());
          }
        }
      } catch (e) {
        _showSnackBar(e.toString());
      }
    } else if (response.statusCode == 401) {
      _showSnackBar('Something went wrong');
    } else {
      _showSnackBar('Something went wrong');
    }
  }

  Future<Map<String, Object>> getSurgeryList(String email) async {
    progressDialog.show();
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-type': 'application/json',
    };

    final response = await http.get(RestDatasource.SURGERYLIST_URL + email,
        headers: headers);
    progressDialog.hide();
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          print(json.encode(data));
          var status = data['status'];
          var uName = data['message'];
          try {
            setState(() {
              surgeryOptionlist = data['list'];
            });
          } catch (e) {
            _showSnackBar(e);
          }
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else if (response.statusCode == 401) {
      _showSnackBar('Something went wrong');
    } else {
      _showSnackBar('Something went wrong');
    }
  }

  void _emailDialog(String ema) {
    showDialog<ConfirmAction>(
      context: context,
      barrierDismissible: true, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          //title: Text('Profile Update'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 10,
              ),
              RichText(
                text: new TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    new TextSpan(text: '"Email ID '),
                    new TextSpan(
                        text: ema,
                        style: new TextStyle(fontWeight: FontWeight.bold)),
                    new TextSpan(
                        text:
                            ' is already registered with us. Do you want to send reset password to this email? '),
                  ],
                ),
              ),
              SizedBox(
                width: 20,
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    RaisedButton(
                      color: Colors.orange,
                      textColor: Colors.white,
                      child: Text(
                        'Yes',
                      ),
                      onPressed: () async {
                        progressDialog.hide();
                        forgotApi(ema);
                        //Navigator.pop(context);
                      },
                    ),
                    RaisedButton(
                      color: Colors.orange,
                      textColor: Colors.white,
                      child: Text('Cancel'),
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                    ),
                  ])
            ],
          ),
        );
      },
    );
    // progressDialog.show();
  }

  Future<Map<String, Object>> forgotApi(String email) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-type': 'application/json',
    };

    final response = await http.post(RestDatasource.FORGOT_PASSWORD_URL + email,
        headers: headers);
    progressDialog.hide();
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          print(data.toString());
          var status = data['status'];
          var uName = data['message'];
          if (status == true) {
            //Navigator.pop(context, false);
            _showItemDialog('Verification link sent to  $email');
          } else {
            _showSnackBar(uName);
          }
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else if (response.statusCode == 401) {
      _showSnackBar('Something went wrong');
    } else {
      _showSnackBar('Something went wrong');
    }
  }

  void _showItemDialog(String message) {
    Widget okButton = FlatButton(
      child: Text("Okay"),
      onPressed: () {
        Navigator.pop(context, false);
        Navigator.pop(context, false);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(""),
      content: Container(
        height: 140.0,
        decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0))),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFC5FBC5),
              child: Image.asset(
                'assets/tick.png',
                width: 70,
                height: 70,
              ),
            ),
            SizedBox(height: 8),
            Text(message)
          ],
        ),
      ),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<Map<String, Object>> checkMobile(String mob) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-type': 'application/json',
    };

    final response = await http.get(
        RestDatasource.CHECK_MOBILE_VALIDATION_URL + mob,
        headers: headers);
    setState(() {
      _isLoading = false;
    });
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          print(data.toString());
          var status = data['status'];
          var uName = data['message'];
          try {
            if (status == true) {
              setState(() {
                isMobileAlreadyAval = false;
                isMobileAlreadyAvalMessage = "";
              });
            } else {
              setState(() {
                isMobileAlreadyAval = true;
                isMobileAlreadyAvalMessage = uName;
              });
            }
          } catch (e) {
            _showSnackBar(e);
          }
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else if (response.statusCode == 401) {
      _showSnackBar('Something went wrong');
    } else {
      _showSnackBar('Something went wrong');
    }
  }

  void _datePicker() {
    var formatter = new DateFormat('yyyy-MM-dd');
    /* DatePicker.showDatePicker(context,
        showTitleActions: true,
        minTime: DateTime(1920, 1, 1),
        maxTime: DateTime(2020, 1, 1),
        theme: DatePickerTheme(
            headerColor: Colors.white,
            backgroundColor: Colors.white,
            itemStyle: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            doneStyle: TextStyle(color: Colors.black, fontSize: 16)),
        onChanged: (date) {
      print('change $date in time zone ' +
          date.timeZoneOffset.inHours.toString());
    }, onConfirm: (date) {
      setState(() {
        dob = formatter.format(date);
      });
    }, currentTime: DateTime.now(), locale: LocaleType.en);*/
  }

  @override
  void onLoginError(String errorTxt) {
    _showSnackBar(errorTxt);
    progressDialog.hide();
    //setState(() => _isLoading = false);
  }

  @override
  void onLoginSuccess(Map<String, Object> user) async {
    progressDialog.hide();
    // _showSnackBar(user.toString());
    //setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    var status = user['status'];
    var uName = user['message'];

    try {
      if (status == true) {
        String userId = user['userId'].toString();
        String token = user['token'].toString();
        String name = user['name'].toString();
        String email = user['email'].toString();
        String mobile = user['mobile'].toString();
        //User u = new User(userId, token, name, email, mobile);
        // await db.saveUser(u);
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', token);
        prefs.setString('userId', userId);
        prefs.setString('name', name);
        prefs.setString('email', email);
        prefs.setString('mobile', mobile);
        // Navigator.of(_ctx).pushNamed(HomePage.tag);
        // Navigator.push(_ctx, MaterialPageRoute(builder: (context) => HomePage()));
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => Home(),
            ),
            ModalRoute.withName('/login_screen'));
        /* var authStateProvider = new AuthStateProvider();
                    authStateProvider.notify(AuthState.LOGGED_IN);*/
        // _showSnackBar("Login success");
      } else {
        _showSnackBar(uName);
      }
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  @override
  void onPharmacyListError(String errorTxt) {
    progressDialog.hide();
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }

  @override
  Future<void> onPharmacyListSuccess(Map<String, Object> data) async {
    progressDialog.hide();
    setState(() => _isLoading = false);
    try {
      // if (data.containsKey("data")) {
      if (data == null) {
        // _showSnackBar("No Pharmacy Found");
      } else {
        List<dynamic> homelist = data['list'];
        // Iterable a = json.decode(userType);
        if (homelist.length > 0) {
          if (menuItems != null) menuItems.clear();
          if (pharmacyIdList != null) pharmacyIdList.clear();
          if (branchIdList != null) branchIdList.clear();
          List list1 = List();
          List list2 = List();
          List list3 = List();
          List list4 = List();
          for (int i = 0; i < homelist.length; i++) {
            list1.add(homelist[i]["branchName"].toString());
            list2.add(homelist[i]["pharmacyId"].toString());
            list3.add(homelist[i]["branchId"].toString());
            if (homelist[i]["postalCode"] != null)
              list4.add(homelist[i]["postalCode"].toString());
          }
          try {
            setState(() {
              menuItems = list1;
              pharmacyIdList = list2;
              branchIdList = list3;
              if (list4.length > 0) pincodeList = list4;
            });
          } catch (e) {
            print(e);
          }
        }
        /*else {
          _showSnackBar("Pharmacy not Found");
        }*/
      }
    } catch (e) {
      _showSnackBar(e);
    }
  }
}
