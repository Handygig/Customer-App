import 'package:firebase_core/firebase_core.dart';
import 'package:customer_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:customer_app/config/theme/app_theme.dart';
import 'package:customer_app/config/router/app_router.dart';
import 'package:customer_app/core/di/service_locator.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_bloc.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initServiceLocator();
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(create: (context) => sl<AuthBloc>()),
            BlocProvider<ServiceCategoryCubit>(
              create: (context) => sl<ServiceCategoryCubit>()..loadCategories(),
            ),
          ],
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, mode, child) {
              return MaterialApp.router(
                title: 'Customer App',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: mode,
                routerConfig: AppRouter.router,
              );
            },
          ),
        );
      },
    );
  }
}
