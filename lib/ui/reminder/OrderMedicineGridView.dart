import 'package:flutter/material.dart';
import 'package:user/animations/fade_animation.dart';
import 'package:user/database/moor_database.dart';
import 'package:user/database/moor_order_database.dart';
import 'package:user/model/Medicine.dart';
import 'package:user/model/OrderMedicine.dart';
import 'MedicineCard.dart';
import 'package:scoped_model/scoped_model.dart';

import 'OrderMedicineCard.dart';

class OrderMedicineGridView extends StatelessWidget {
  final List<OrderMedicinesTableData> list;
  OrderMedicineGridView(this.list);

  @override
  Widget build(BuildContext context) {

    return ScopedModelDescendant<OrderMedicineModel>(
        builder: (context, child, model) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        children: list.map((medicine) {
          return InkWell(
            onTap: () {
              // details screen
            },
            child: buildLongPressDraggable(medicine, model),
          );
        }).toList(),
      );
    });
  }

  LongPressDraggable<OrderMedicinesTableData> buildLongPressDraggable(
      medicine, OrderMedicineModel model) {
    return LongPressDraggable<OrderMedicinesTableData>(
      data: medicine,
      onDragStarted: () {
        // show the delete icon
        model.toggleIconState();
      },
      onDragEnd: (v) {
        // hide the delete icon
        model.toggleIconState();
      },
      child: FadeAnimation(
        .05,
        Card(
          margin: EdgeInsets.all(10),
          child: OrderMecicineCard(medicine, Colors.white),
        ),
      ),
      childWhenDragging: Container(
        color: Color(0xff3EB16E).withOpacity(.3),
      ),
      feedback: Card(
        child: OrderMecicineCard(medicine, Colors.transparent),
      ),
    );
  }
}
