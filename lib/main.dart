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
import 'presentation/state/providers/line_info_provider.dart';
import 'presentation/state/providers/teller_verify_provider.dart';
import 'presentation/state/providers/box_handover_provider.dart';
import 'package:tj_tms_mobile/core/config/env.dart';
import 'package:tj_tms_mobile/core/utils/global_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 添加全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  
  // 设置虚拟按键为透明，在启动屏显示之前
  if (!kIsWeb) {
    // 设置系统UI样式为透明
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    
    // 设置系统UI模式为透明，隐藏底部虚拟按键
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    
    // 延迟再次设置，确保生效
    Future.delayed(const Duration(milliseconds: 100), () {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
    });
    
    // 多次设置，确保生效
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: 200 * (i + 1)), () {
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ));
      });
    }
    
    // 监听系统UI变化，保持透明
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
    });
  }
  
  // 初始化环境配置
  Env.init();
  
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
    // 在应用构建时再次确保虚拟按键为透明
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ));
      });
    }
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FaceLoginProvider()),
        ChangeNotifierProvider(create: (_) => VerifyTokenProvider(access_token: '')),
        ChangeNotifierProvider(create: (_) => LineInfoProvider()),
        ChangeNotifierProvider(create: (_) => TellerVerifyProvider()),
        ChangeNotifierProvider(create: (_) => BoxHandoverProvider()),
      ],
      child: MaterialApp(
        title: Env.config.appName,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        navigatorKey: GlobalNavigator.navigatorKey,
        scaffoldMessengerKey: GlobalNavigator.scaffoldMessengerKey,
        initialRoute: '/',
        routes: AppRoutes.getRoutes(),
        onGenerateRoute: RouteGenerator.generateRoute,
        builder: (context, child) {
          Widget result = child!;
          
          if (kIsWeb) {
            result = MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    // Web端额外禁用点击反馈
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                  ),
                  child: child!,
                ),
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
