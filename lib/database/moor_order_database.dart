import 'package:moor_flutter/moor_flutter.dart';
part 'moor_order_database.g.dart';

class OrderMedicinesTable extends Table {
  // autoincrement sets this to the primary key
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 5, max: 50)();
  TextColumn get image => text()();
  TextColumn get dose => text()();
}

@UseMoor(tables: [OrderMedicinesTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(FlutterQueryExecutor.inDatabaseFolder(
            path: 'order_db.sqlite', logStatements: true));

  @override
  int get schemaVersion => 1;

  Future<List<OrderMedicinesTableData>> getAllMedicines() =>
      select(medicinesTable).get();
  Future insertMedicine(OrderMedicinesTableData medicine) =>
      into(medicinesTable).insert(medicine);
  Future updateMedicine(OrderMedicinesTableData medicine) =>
      update(medicinesTable).replace(medicine);
  Future deleteMedicine(OrderMedicinesTableData medicine) =>
      delete(medicinesTable).delete(medicine);
}
