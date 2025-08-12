import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:tj_tms_mobile/models/shelf_model.dart';
import 'package:tj_tms_mobile/core/constants/constant.dart';

class ShelfDataSource extends DataGridSource {
  final List<ShelfModel> _shelves;
  final Function(ShelfModel)? onEdit;
  final Function(ShelfModel)? onDelete;

  ShelfDataSource({
    required List<ShelfModel> shelves,
    this.onEdit,
    this.onDelete,
  }) : _shelves = shelves {
    _shelfRows = shelves
        .map<DataGridRow>((shelf) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'shelfId', value: shelf.shelfId),
              DataGridCell<int>(columnName: 'status', value: shelf.status),
              DataGridCell<String>(columnName: 'locationId', value: shelf.locationId),
              DataGridCell<String>(columnName: 'actions', value: ''),
            ]))
        .toList();
  }

  List<DataGridRow> _shelfRows = [];

  @override
  List<DataGridRow> get rows => _shelfRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        if (cell.columnName == 'status') {
          final statusInt = cell.value as int;
          final status = PalletStatus.fromCode(statusInt);
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              status.displayName,
              style: TextStyle(
                fontSize: 12,
                color: _hexToColor(status.color),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        } else if (cell.columnName == 'actions') {
          final shelfIndex = row.getCells().indexWhere((c) => c.columnName == 'shelfId');
          if (shelfIndex != -1) {
            final shelfId = row.getCells()[shelfIndex].value.toString();
            final shelf = _shelves.firstWhere((s) => s.shelfId == shelfId);
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.center, // 或 MainAxisAlignment.start
              children: [
                TextButton(
                  onPressed: () => onEdit?.call(shelf),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('修改', style: TextStyle(fontSize: 12, color: Colors.blue)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    height: 16,
                    child: VerticalDivider(
                      color: Colors.grey,
                      thickness: 1,
                      width: 1,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onDelete?.call(shelf),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('移除', style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        } else {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              cell.value.toString(),
              style: const TextStyle(fontSize: 12),
            ),
          );
        }
      }).toList(),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
} 