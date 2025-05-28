// import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
// import 'package:tj_tms_mobile/data/datasources/remote/api_endpoints.dart';

// class TaskService {
//   final DioService _dioService;

//   TaskService(this._dioService);

//   Future<Map<String, dynamic>> getTaskList({required int page, required int pageSize}) async {
//     return _dioService.get(
//       ApiEndpoints.taskList,
//       queryParameters: ApiParams.pagination(
//         page: page,
//         pageSize: pageSize,
//       ),
//     );
//   }

//   Future<Map<String, dynamic>> getTaskDetail(String taskId) async {
//     return _dioService.get(
//       ApiEndpoints.taskDetail.replaceAll('{id}', taskId),
//     );
//   }

//   Future<Map<String, dynamic>> updateTaskStatus({
//     required String taskId,
//     required String status,
//     String? remark,
//   }) async {
//     return _dioService.post(
//       ApiEndpoints.updateTaskStatus.replaceAll('{id}', taskId),
//       body: ApiParams.updateTaskStatus(
//         status: status,
//         remark: remark,
//       ),
//     );
//   }
// } 