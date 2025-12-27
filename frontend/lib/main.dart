import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Requires google-services.json)
  try {
    await Firebase.initializeApp();
    await NotificationService.init();
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization failed (missing google-services.json?): $e');
    }
  }

  final isLoggedIn = await ApiService.init();
  
  if (isLoggedIn) {
    // Register token if already logged in
    NotificationService.registerDeviceToken();
  }
  
  runApp(
    ProviderScope(
      child: PulseApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class PulseApp extends StatelessWidget {
  final bool isLoggedIn;
  const PulseApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.createRouter(isLoggedIn),
    );
  }
}
