import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'services/location_service.dart';
import 'presentation/state/providers/face_login_provider.dart';
import 'presentation/state/providers/verify_token_provider.dart';
import 'package:tj_tms_mobile/core/config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化环境配置
  Env.init();
  
  // 初始化位置服务
  if (!kIsWeb) {
    final locationService = LocationService();
    await locationService.initialize();
    // 禁用掉底部的虚拟按键
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FaceLoginProvider()),
        ChangeNotifierProvider(create: (_) => VerifyTokenProvider(access_token: '')),
      ],
      child: MaterialApp(
        title: Env.config.appName,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: AppRoutes.getRoutes(),
        onGenerateRoute: RouteGenerator.generateRoute,
        builder: (context, child) {
          Widget result = child!;
          
          if (kIsWeb) {
            result = MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child!,
            );
          }
          
          // 初始化 EasyLoading
          result = EasyLoading.init()(context, result);
          
          return result;
        },
      ),
    );
  }
}
