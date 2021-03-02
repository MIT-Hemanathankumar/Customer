import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:user/animations/fade_animation.dart';
import 'package:user/database/moor_database.dart';
import 'package:user/database/moor_order_database.dart';
import 'package:user/model/Medicine.dart';
import 'package:user/model/OrderMedicine.dart';

class OrderDeleteIcon extends StatefulWidget {
  Color color = Colors.grey;
  @override
  _OrderDeleteIconState createState() => _OrderDeleteIconState();
}

class _OrderDeleteIconState extends State<OrderDeleteIcon> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: 20,
        left: 100,
        right: 100,
        child: ScopedModelDescendant<OrderMedicineModel>(
            builder: (context, child, model) {
          return DragTarget<OrderMedicinesTableData>(
            builder: (context, rejectedData, candidtateData) {
              return FadeAnimation(
                .5,
                Container(
                  width: 250,
                  height: 220,
                  color: Colors.transparent,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Icon(
                      Icons.delete,
                      color: widget.color,
                      size: 60,
                    ),
                  ),
                ),
              );
            },
            onWillAccept: (medicine) {
              print('onWillAccept was called');
              setState(() {
                widget.color = Colors.red;
              });
              return true;
            },
            onLeave: (v) {
              setState(() {
                widget.color = Colors.grey;
              });
              print('onLeave');
            },
            onAccept: (medicine) {
              // remove it from the database
              model.getDatabase().deleteMedicine(medicine);
              //remove the medicine notifcation
              model.notificationManager.removeReminder(medicine.id);
              // for debugging
              print("Reminder deleted" + medicine.toString());
              // show delete snakbar
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    'Reminder deleted',
                    style: TextStyle(fontSize: 20),
                  ),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          );
        }));
  }
}
