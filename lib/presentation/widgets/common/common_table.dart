import 'package:flutter/material.dart';

/// 通用表格组件
class CommonTable extends StatefulWidget {
  final List<String> headers; // 表头文字
  final Color headerColor; // 表头背景色
  final TextStyle headerTextStyle; // 表头文字样式
  final List<List<String>> data; // 表格数据
  final TextStyle cellTextStyle; // 单元格文字样式
  final List<Widget Function(int rowIndex)> actionBuilders; // 操作按钮生成器（每行）
  final bool paginated; // 是否分页
  final int rowsPerPage; // 每页行数（分页时有效）
  final Map<int, TableColumnWidth>? columnWidths; // 新增：自定义列宽
  final int fixedColumnCount; // 新增：固定前几列
  final bool fixedFirstAndLastColumn; // 新增：固定首尾列

  const CommonTable({
    Key? key,
    required this.headers,
    required this.headerColor,
    required this.headerTextStyle,
    required this.data,
    required this.cellTextStyle,
    required this.actionBuilders,
    this.paginated = false,
    this.rowsPerPage = 10,
    this.columnWidths, // 新增
    this.fixedColumnCount = 0, // 新增
    this.fixedFirstAndLastColumn = false, // 新增
  }) : super(key: key);

  @override
  State<CommonTable> createState() => _CommonTableState();
}

class _CommonTableState extends State<CommonTable> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final int totalRows = widget.data.length;
    final int totalPages = (totalRows / widget.rowsPerPage).ceil();

    List<TableRow> buildRows(List<List<String>> rows) {
      return List.generate(rows.length, (rowIdx) {
        final row = rows[rowIdx];
        return TableRow(
          children: [
            ...row.map((cell) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Text(cell, style: widget.cellTextStyle),
                )),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.actionBuilders.map((builder) => builder(rowIdx)).toList(),
              ),
            ),
          ],
        );
      });
    }

    Widget buildTable(List<List<String>> rows, {bool left = false, bool right = false}) {
      // left: 只渲染固定列，right: 只渲染可滑动列
      int leftCount = widget.fixedColumnCount;
      int rightStart = leftCount;
      int rightCount = widget.headers.length - leftCount;
      return Table(
        columnWidths: widget.columnWidths ?? {
          for (int i = 0; i < widget.headers.length; i++) i: const FlexColumnWidth(),
          widget.headers.length: const IntrinsicColumnWidth(),
        },
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          TableRow(
            decoration: BoxDecoration(color: widget.headerColor),
            children: [
              if (left)
                ...widget.headers.take(leftCount).map((h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text(h, style: widget.headerTextStyle),
                    )),
              if (right)
                ...widget.headers.skip(rightStart).map((h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text(h, style: widget.headerTextStyle),
                    )),
              if (right)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Text('操作'),
                ),
            ],
          ),
          ...List.generate(rows.length, (rowIdx) {
            final row = rows[rowIdx];
            return TableRow(
              children: [
                if (left)
                  ...row.take(leftCount).map((cell) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Text(cell, style: widget.cellTextStyle),
                      )),
                if (right)
                  ...row.skip(rightStart).map((cell) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Text(cell, style: widget.cellTextStyle),
                      )),
                if (right)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.actionBuilders.map((builder) => builder(rowIdx)).toList(),
                    ),
                  ),
              ],
            );
          }),
        ],
      );
    }

    if (widget.fixedFirstAndLastColumn && widget.headers.length >= 3) {
      // 左侧：第0列
      Widget leftTable = Table(
        columnWidths: const {0: FlexColumnWidth()},
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          TableRow(
            decoration: BoxDecoration(color: widget.headerColor),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text(widget.headers[0], style: widget.headerTextStyle),
              ),
            ],
          ),
          ...List.generate(widget.data.length, (rowIdx) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Text(widget.data[rowIdx][0], style: widget.cellTextStyle),
                  ),
                ],
              )),
        ],
      );
      // 中间：1~n-2列
      Widget centerTable = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          columnWidths: {
            for (int i = 1; i < widget.headers.length - 1; i++)
              i - 1: widget.columnWidths != null && widget.columnWidths!.containsKey(i)
                  ? widget.columnWidths![i]!
                  : const FlexColumnWidth(),
          },
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            TableRow(
              decoration: BoxDecoration(color: widget.headerColor),
              children: [
                ...widget.headers
                    .sublist(1, widget.headers.length - 1)
                    .map((h) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Text(h, style: widget.headerTextStyle),
                        )),
              ],
            ),
            ...List.generate(widget.data.length, (rowIdx) => TableRow(
                  children: [
                    ...widget.data[rowIdx]
                        .sublist(1, widget.headers.length - 1)
                        .map((cell) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Text(cell, style: widget.cellTextStyle),
                            )),
                  ],
                )),
          ],
        ),
      );
      // 右侧：最后一列+操作
      Widget rightTable = Table(
        columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          TableRow(
            decoration: BoxDecoration(color: widget.headerColor),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text(widget.headers.last, style: widget.headerTextStyle),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text('操作'),
              ),
            ],
          ),
          ...List.generate(widget.data.length, (rowIdx) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Text(widget.data[rowIdx].last, style: widget.cellTextStyle),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.actionBuilders.map((builder) => builder(rowIdx)).toList(),
                  ),
                ],
              )),
        ],
      );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftTable,
          centerTable,
          rightTable,
        ],
      );
    }

    if (widget.fixedColumnCount > 0) {
      // 固定列+可滑动列
      Widget leftTable = buildTable(widget.data, left: true);
      Widget rightTable = buildTable(widget.data, right: true);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leftTable,
            rightTable,
          ],
        ),
      );
    }

    if (widget.paginated) {
      // 分页模式
      int start = _currentPage * widget.rowsPerPage;
      int end = (_currentPage + 1) * widget.rowsPerPage;
      end = end > totalRows ? totalRows : end;
      final pageRows = widget.data.sublist(start, end);
      return Column(
        children: [
          buildTable(pageRows),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Text('第 ${_currentPage + 1} / $totalPages 页'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      );
    } else {
      // 滚动模式
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: buildTable(widget.data),
        ),
      );
    }
  }
} 