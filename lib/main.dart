import 'package:flutter/material.dart';
// 👇 هذا الاستيراد مهم جداً للغة العربية
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

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
    // 🎨 Brand Colors
    const Color primaryBrown = Color(0xFF3E2723);
    const Color accentGold = Color(0xFFD4AF37);
    const Color accentGoldAlt = Color(0xFFFFCA28);
    const Color surfaceBeige = Color(0xFFF5E6D3);
    const Color textDark = Color(0xFF2C2C2C);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لمة كافيه - نظام الكاشير',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBrown,
          brightness: Brightness.light,
          primary: primaryBrown,
          secondary: accentGold,
          surface: surfaceBeige,
        ),
        // Typography with Arabic fonts
        textTheme: GoogleFonts.cairoTextTheme().copyWith(
          displayLarge: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: primaryBrown,
          ),
          displayMedium: GoogleFonts.cairo(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primaryBrown,
          ),
          headlineSmall: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          bodyLarge: GoogleFonts.cairo(
            fontSize: 16,
            color: textDark,
          ),
          bodyMedium: GoogleFonts.cairo(
            fontSize: 14,
            color: textDark,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGold,
            foregroundColor: primaryBrown,
            elevation: 8,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accentGold,
          foregroundColor: primaryBrown,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDD9D0), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDD9D0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentGold, width: 2),
          ),
          labelStyle: GoogleFonts.cairo(color: textDark),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: primaryBrown.withValues(alpha: 0.15),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surfaceBeige,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryBrown,
          ),
        ),
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
