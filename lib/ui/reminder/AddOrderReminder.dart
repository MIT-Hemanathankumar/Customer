import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:user/database/moor_order_database.dart';
import 'package:user/util/NotificationManager.dart';

class AddOrderReminder extends StatefulWidget {
  final double height;
  final AppDatabase _database;
  final String medicineName;
  final NotificationManager manager;
  final int maxDuration;

  AddOrderReminder(this.height, this._database, this.manager, this.medicineName,
      this.maxDuration);

  @override
  _AddOrderReminderState createState() => _AddOrderReminderState();
}

class _AddOrderReminderState extends State<AddOrderReminder> {
  static final _formKey = new GlobalKey<FormState>();
  String _name;
  String _dose;
  BuildContext contx;
  int _itemCount = 0;

  int _selectedIndex = 0;
  List<String> _icons = [
    'drug.png',
    'inhaler.png',
    'pill_rounded.png',
    'pill.png',
  ];

  @override
  Widget build(BuildContext context) {
    contx = context;
    _name = widget.medicineName;
    return Container(
        padding: EdgeInsets.fromLTRB(25, 20, 25, 0),
        height: widget.height * 1,
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Add New Reminder',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // back to main screen
                    Navigator.pop(context, null);
                  },
                  child: Icon(
                    Icons.close,
                    size: 30,
                    color: Theme.of(context).primaryColor.withOpacity(.65),
                  ),
                )
              ],
            ),
            _buildForm(),
            SizedBox(
              height: 25,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'How many days before you want to get remained for repeat order before getting empty?',
                style: TextStyle(fontWeight: FontWeight.w300, fontSize: 15),
              ),
            ),
            SizedBox(
              height: 35,
            ),
            Center(
              child: new Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: new Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (_itemCount > 0) {
                          _itemCount--;
                        }
                      });
                    },
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  new Text(
                    _itemCount.toString(),
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  new IconButton(
                      icon: new Icon(Icons.add),
                      onPressed: () {
                        if (widget.maxDuration > (_itemCount + 1)) {
                          setState(() {
                            _itemCount++;
                          });
                        } else {
                          _showSnackBar("Can't select max of medicine days");
                        }
                      })
                ],
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Container(
              width: double.infinity,
              child: RaisedButton(
                padding: EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(30.0),
                ),
                onPressed: () {
                  _submit(widget.manager);
                },
                color: Theme.of(context).accentColor,
                textColor: Colors.white,
                highlightColor: Theme.of(context).primaryColor,
                child: Text(
                  'Save'.toUpperCase(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ));
  }

  void _showSnackBar(String text) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  Widget _buildShapesList() {
    return Container(
      width: double.infinity,
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _icons
            .asMap()
            .entries
            .map((MapEntry map) => _buildIcons(map.key))
            .toList(),
      ),
    );
  }

  Form _buildForm() {
    TextStyle labelsStyle =
        TextStyle(fontWeight: FontWeight.w400, fontSize: 25);
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          widget.medicineName == ""
              ? TextFormField(
                  style: TextStyle(fontSize: 25),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: labelsStyle,
                  ),
                  validator: (input) =>
                      (input.length < 3) ? 'Name is short.min 3' : null,
                  onSaved: (input) => _name = input,
                )
              : SizedBox(),
          /*   TextFormField(
            style: TextStyle(fontSize: 25),
            decoration: InputDecoration(
              labelText: 'Dose',
              labelStyle: labelsStyle,
            ),
            validator: (input) => (input.length > 50) ? 'Dose is long' : null,
            onSaved: (input) => _dose = input,
          )*/
        ],
      ),
    );
  }

  void _submit(NotificationManager manager) async {
    if (_formKey.currentState.validate()) {
      // form is validated
      _formKey.currentState.save();
      print(_name);
      //print(_dose);
      //show the time picker dialog
      var endDate = DateTime.now().add(new Duration(days: widget.maxDuration));
      var now = endDate.subtract(new Duration(days: _itemCount));
      String formattedDate = DateFormat('dd-MM-yyyy').format(now);
      //_showSnackBar(formattedDate);
      // insert into database
      try {
         var medicineId = await widget._database.insertMedicine(
             OrderMedicinesTableData(
                  name: widget.medicineName,
                  dose: formattedDate,
                  image: 'assets/images/' + _icons[_selectedIndex]));
          // sehdule the notification
          manager.showNotificationShedule(medicineId, widget.medicineName,
              'Order reminder for ' +  widget.medicineName, 8, 0, now);
          // The medicine Id and Notitfaciton Id are the same
          //print('New Med id' + medicineId.toString());
          // go back
          Navigator.pop(contx, medicineId);
      } catch (e) {
        print(e);
      }
    }
  }

  Widget _buildIcons(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.all(10),
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          color: (index == _selectedIndex)
              ? Theme.of(context).accentColor.withOpacity(.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Image.asset('assets/images/' + _icons[index]),
      ),
    );
  }
}
