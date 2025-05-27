import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/auth_provider.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化位置服务
  if (!kIsWeb) {
    final locationService = LocationService();
    await locationService.initialize();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: '天津银行外勤手持机',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: AppRoutes.getRoutes(),
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}
