import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:tj_tms_mobile/models/landmark_model.dart';
import 'package:tj_tms_mobile/core/constants/constant.dart';

class LandmarkDataSource extends DataGridSource {
  final List<LandmarkModel> _landmarks;
  final Function(LandmarkModel)? onEdit;
  final Function(LandmarkModel)? onDelete;
  final List<String> selectedIds;
  final void Function(String id, bool selected)? onSelect;

  LandmarkDataSource({
    required List<LandmarkModel> landmarks,
    this.onEdit,
    this.onDelete,
    this.selectedIds = const [],
    this.onSelect,
  }) : _landmarks = landmarks {
    _landmarkRows = landmarks
        .map<DataGridRow>((landmark) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'id', value: landmark.id),
              DataGridCell<String>(
                  columnName: 'areaName', value: landmark.areaName),
              DataGridCell<int>(
                  columnName: 'locationType', value: landmark.locationType),
              DataGridCell<int>(columnName: 'status', value: landmark.status),
              DataGridCell<String>(columnName: 'actions', value: ''),
            ]))
        .toList();
  }

  List<DataGridRow> _landmarkRows = [];

  @override
  List<DataGridRow> get rows => _landmarkRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final id =
        row.getCells().firstWhere((c) => c.columnName == 'id').value.toString();
    return DataGridRowAdapter(
      cells: [
        SizedBox(
          width: 24,
          height: 24,
          child: Transform.scale(
            scale: 0.75,
            child: Checkbox(
              value: selectedIds.contains(id),
              onChanged: (checked) {
                print('${id} checked: $checked');
                 onSelect?.call(id, checked ?? false);
              },
            ),
          ),
        ),
        ...row.getCells().map<Widget>((cell) {
          if (cell.columnName == 'locationType') {
            final int typeInt = cell.value as int;
            final LocationType type = LocationType.fromCode(typeInt);
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                type.displayName,
                style: const TextStyle(fontSize: 12),
              ),
            );
          } else if (cell.columnName == 'status') {
            final int statusInt = cell.value as int;
            final LandmarkStatus status = LandmarkStatus.fromCode(statusInt);
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
              final landmark = _landmarks.firstWhere((l) => l.id == id);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => onEdit?.call(landmark),
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
                    onPressed: () => onDelete?.call(landmark),
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
