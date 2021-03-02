import 'package:flutter/material.dart';
import 'package:user/database/moor_database.dart';
import 'package:user/database/moor_order_database.dart';

class OrderMecicineCard extends StatelessWidget {
  final OrderMedicinesTableData medicine;
  final Color color;

  OrderMecicineCard(this.medicine, this.color);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      width: 180,
      height: 180,
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(10),
            width: 50,
            height: 50,
            child: Hero(
              tag: medicine.name,
              child: Image.asset(
                medicine.image,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: Text(
                  medicine.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                medicine.dose.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
