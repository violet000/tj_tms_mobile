import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:tj_tms_mobile/models/area_model.dart';
import 'package:tj_tms_mobile/core/constants/constant.dart';

class AreaDataSource extends DataGridSource {
  final List<AreaModel> _areas;
  final Function(AreaModel)? onEdit;
  final Function(AreaModel)? onDelete;
  final List<String> selectedIds;
  final void Function(String id, bool selected)? onSelect;

  AreaDataSource({
    required List<AreaModel> areas,
    this.onEdit,
    this.onDelete,
    this.selectedIds = const [],
    this.onSelect,
  }) : _areas = areas {
    _areasRows = areas
        .map<DataGridRow>((area) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'id', value: area.id),
              DataGridCell<String>(
                  columnName: 'name', value: area.name),
              DataGridCell<String>(columnName: 'clrCenterNo', value: area.clrCenterNo),
              DataGridCell<int>(columnName: 'status', value: area.status),
              DataGridCell<String>(columnName: 'actions', value: ''),
            ]))
        .toList();
  }

  List<DataGridRow> _areasRows = [];

  @override
  List<DataGridRow> get rows => _areasRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: [
        ...row.getCells().map<Widget>((cell) {
          if (cell.columnName == 'id') {
            // id 列直接显示 id
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                cell.value.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            );
          } else if (cell.columnName == 'name') {
            // name 列直接显示 name
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                cell.value.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            );
          } else if (cell.columnName == 'status') {
            // status 列显示状态名
            final int statusInt = cell.value as int;
            final AreaStatus status = AreaStatus.fromCode(statusInt);
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                status.displayName,
                style: const TextStyle(fontSize: 12),
              ),
            );
          } else if (cell.columnName == 'actions') {
            final idIndex =
                row.getCells().indexWhere((c) => c.columnName == 'id');
            if (idIndex != -1) {
              final id = row.getCells()[idIndex].value.toString();
              AreaModel? area;
              try {
                area = _areas.firstWhere((a) => a.id == id);
              } catch (e) {
                area = null;
              }
              if (area == null) return const SizedBox.shrink();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => onEdit?.call(area!),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('修改',
                        style: TextStyle(fontSize: 12, color: Colors.blue)),
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
                    onPressed: () => onDelete?.call(area!),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('删除',
                        style: TextStyle(fontSize: 12, color: Colors.red)),
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
      ],
    );
  }
}
