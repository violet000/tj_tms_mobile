import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:tj_tms_mobile/core/constants/constant.dart';

class HandTask {
  HandTask({
    required this.operateType, // 作业类型
    required this.status, // 状态
    required this.origCell, // 起始库位
    required this.destCell, // 终点库位
    required this.origArea, // 起始库区
    required this.destArea, // 终点库区
    required this.carryContainerType, // 搬运类型
    required this.execStartTime, // 开始时间
    required this.execEndTime, // 结束时间
    required this.jobId, // 任务号
    required this.carryContainerId, // 托盘编号
    this.note, // 备注
  });
  final String operateType;
  final int status;
  final String origCell;
  final String destCell;
  final String origArea;
  final String destArea;
  final String carryContainerType;
  final String execStartTime;
  final String execEndTime;
  final String jobId;
  final String carryContainerId;
  final String? note; // 备注
}

// 搬运任务数据源适配
class HandTaskDataSource extends DataGridSource {
  final List<HandTask> _originHandTasks;
  final Function(HandTask)? onDetailTap; // 添加详情点击回调

  HandTaskDataSource({
    required List<HandTask> handTasks,
    this.onDetailTap,
  }) : _originHandTasks = handTasks {
    _handtasks = handTasks
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(
                columnName: 'taskType',
                value: OperateType.values.firstWhere(
                  (OperateType v) => v.value == e.operateType,
                  orElse: () => OperateType.values.first,
                ).displayName,
              ),
              DataGridCell<int>(
                columnName: 'status',
                value: e.status,
              ),
              DataGridCell<String>(columnName: 'startLocationId', value: e.origCell),
              DataGridCell<String>(columnName: 'endLocationId', value: e.destCell),
              DataGridCell<String>(columnName: 'actions', value: ''), // 添加actions单元格
            ]))
        .toList();
  }

  List<DataGridRow> _handtasks = [];

  @override
  List<DataGridRow> get rows => _handtasks;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        if (cell.columnName == 'actions') {
          // 操作列显示详情按钮
          final rowIndex = _handtasks.indexOf(row);
          final handTask = rowIndex >= 0 && rowIndex < _originHandTasks.length
              ? _originHandTasks[rowIndex]
              : null;
          
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6.0),
                onTap: () {
                  if (onDetailTap != null && handTask != null) {
                    onDetailTap!(handTask);
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 44.0, 
                    minHeight: 32.0,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                  decoration: BoxDecoration( // 透明背景，用于增大触摸目标
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: Colors.transparent, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      '详情',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else if (cell.columnName == 'status') {
          final statusInt = cell.value as int;
          final displayName = JobStatus.values.firstWhere(
            (v) => v.code == statusInt,
            orElse: () => JobStatus.values.first,
          ).displayName;
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4.0),
            child: Text(
              displayName,
              style: const TextStyle(fontSize: 12),
            ),
          );
        } else {
          // 其他列显示文本
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4.0), // 缩小内边距
            child: Text(
              cell.value.toString(),
              style: const TextStyle(fontSize: 12), // 缩小字体
            ),
          );
        }
      }).toList(),
    );
  }

  // 根据行数据获取HandTask对象
  HandTask? _getHandTaskFromRow(DataGridRow row) {
    try {
      final cells = row.getCells();
      if (cells.length >= 5) {
        return HandTask(
          operateType: cells[0].value.toString(),
          status: cells[1].value as int,
          origCell: cells[2].value.toString(),
          destCell: cells[3].value.toString(),
          origArea: '',
          destArea: '',
          carryContainerType: '',
          execStartTime: '',
          execEndTime: '', 
          jobId: '',
          carryContainerId: '',
          note: '', // 添加空的备注
        );
      }
    } catch (e) {
      print('Error creating HandTask from row: $e');
    }
    return null;
  }
}