// import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
// import 'package:tj_tms_mobile/data/datasources/remote/api_endpoints.dart';

// class OrderService {
//   final DioService _dioService;

//   OrderService(this._dioService);

//   Future<Map<String, dynamic>> getOrderList({required int page, required int pageSize}) async {
//     return _dioService.get(
//       ApiEndpoints.orderList,
//       queryParameters: ApiParams.pagination(
//         page: page,
//         pageSize: pageSize,
//       ),
//     );
//   }

//   Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
//     return _dioService.get(
//       ApiEndpoints.orderDetail.replaceAll('{id}', orderId),
//     );
//   }

//   Future<Map<String, dynamic>> createOrder({
//     required String customerName,
//     required String address,
//     required List<Map<String, dynamic>> items,
//   }) async {
//     return _dioService.post(
//       ApiEndpoints.createOrder,
//       body: ApiParams.createOrder(
//         customerName: customerName,
//         address: address,
//         items: items,
//       ),
//     );
//   }

//   Future<Map<String, dynamic>> updateOrder(String orderId, Map<String, dynamic> data) async {
//     return _dioService.post(
//       ApiEndpoints.updateOrder.replaceAll('{id}', orderId),
//       body: data,
//     );
//   }
// } 