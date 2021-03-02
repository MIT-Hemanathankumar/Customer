import 'package:flutter/material.dart';
import 'package:user/database/moor_database.dart';
import 'package:user/util/NotificationManager.dart';

class AddMedicine extends StatefulWidget {
  final double height;
  final AppDatabase _database;
  final String medicineName;
  final NotificationManager manager;
  AddMedicine(this.height, this._database, this.manager, this.medicineName);

  @override
  _AddMedicineState createState() => _AddMedicineState();
}

class _AddMedicineState extends State<AddMedicine> {
  static final _formKey = new GlobalKey<FormState>();
  String _name;
  String _dose;
  BuildContext contx;

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
        height: widget.height * .7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
              height: 5,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Shape',
                style: TextStyle(fontWeight: FontWeight.w300, fontSize: 25),
              ),
            ),
            SizedBox(
              height: 15,
            ),
            _buildShapesList(),
            SizedBox(
              height: 15,
            ),
            Container(
              width: double.infinity,
              child: RaisedButton(
                padding: EdgeInsets.all(15),
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
                  'Select time'.toUpperCase(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ));
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
          widget.medicineName == "" ? TextFormField(
            style: TextStyle(fontSize: 25),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: labelsStyle,
            ),
            validator: (input) => (input.length < 3) ? 'Name is short.min 3' : null,
            onSaved: (input) => _name = input,
          ) : SizedBox(),
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
      showTimePicker(
        initialTime: TimeOfDay.now(),
        context: context,
      ).then((selectedTime) async {
        int hour = selectedTime.hour;
        int minute = selectedTime.minute;
        print(selectedTime);
        if(_name.length == 4){
          _name = '$_name ';
        }
        if(_name.length == 3){
          _name = '$_name  ';
        }
        if(_name.length == 2){
          _name = '$_name   ';
        }
        if(_name.length == 1){
          _name = '$_name    ';
        }
        // insert into database
        try {
          var medicineId = await widget._database.insertMedicine(
                      MedicinesTableData(
                          name: _name,
                          dose: '$hour : $minute',
                          image: 'assets/images/' + _icons[_selectedIndex]));
          // sehdule the notification
          manager.showNotificationDaily(medicineId, _name, 'You set reminder to take $_name', hour, minute);
          // The medicine Id and Notitfaciton Id are the same
          //print('New Med id' + medicineId.toString());
          // go back
          Navigator.pop(contx, medicineId);
        } catch (e) {
          print(e);
        }
      });
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
