import 'package:flutter/material.dart';
// 👇 هذا الاستيراد مهم جداً للغة العربية
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

// 🎨 Brand Colors
const Color primaryBrown = Color(0xFF3E2723);
const Color accentGold = Color(0xFFD4AF37);
const Color surfaceBeige = Color(0xFFF5E6D3);

void main() async {
  // 👈 التعديل الأول: ضفنا كلمة async هنا

  // 👇 التعديل الثاني: هذا السطر السحري اللي يحل مشكلة الـ AssetManifest
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نظام كاشير الكفتريا',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBrown),
        useMaterial3: true,
        textTheme: GoogleFonts.cairoTextTheme(),
      ),

      // 👇 هذي الأسطر هي اللي راح تقلب التطبيق بالكامل من اليمين لليسار 👇
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'), // تعريف اللغة العربية
      ],
      locale: const Locale('ar', 'AE'), // إجبار التطبيق يشتغل بالعربي مباشرة
      // 👆 انتهت إعدادات اللغة 👆

      home: const HomeScreen(),
    );
  }
}
