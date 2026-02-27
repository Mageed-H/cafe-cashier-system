# لمة كافيه POS System - Copilot Instructions

## 🎯 Project Overview

**Lamma Cafe** is a premium Flutter desktop POS (Point of Sale) system for a café and gaming lounge. Built with Material3 and SQLite, featuring:
- Dual-section cafeteria & gaming hall management
- Real-time timers for PS4/PS5/Billiards rentals
- PDF receipt/invoice printing
- Comprehensive expense tracking
- Arabic RTL support with Google Fonts (Cairo)

**Repository**: `https://github.com/Mageed-H/cafe-cashier-system`

---

## 🏗️ Architecture & Key Files

### Core Structure
```
lib/
├── main.dart              # Theme setup (Brand colors, Typography)
├── screens/               # UI Screens (Table Details, Settings, Stats)
├── widgets/              # Reusable UI Components (Table Card, Drawer)
├── services/database_helper.dart  # SQLite operations
└── models/product_model.dart      # Product class
```

### Critical Service
**`database_helper.dart`** - Singleton managing:
- Table orders (cafeteria vs gaming) - separate tracking
- Unimplemented orders (print queue)
- Gaming timers with play/pause states
- Revenue & expense reporting

### Database Schema Key Points
- **Orders**: `table_number, type (cafeteria|gaming), is_paid, receipt_id`
- **Timers**: `device_name, mode (single|multi), is_playing, accumulated_seconds`
- **Expenses**: `amount, description, expense_date`

---

## 🎨 Brand Identity & UI/UX Pattern

### Color Palette (Established)
- **Primary Brown**: `#3E2723` (text, headers, primary actions)
- **Accent Gold**: `#D4AF37` (highlights, badges, borders)
- **Surface Beige**: `#F5E6D3` (backgrounds, cards)
- **Accents**: 
  - Gaming: `#7B1FA2` (Purple)
  - Cafeteria: `#6D4C41` (Brown)
  - Busy/Error: `#D32F2F` (Red)

### Typography (Already Applied)
- **Font Family**: Google Fonts Cairo (Arabic)
- **Headers**: `GoogleFonts.cairo(fontSize: 20-24, fontWeight: w700)`
- **Body**: `GoogleFonts.cairo(fontSize: 14-16, fontWeight: w600)`

### UI Components Pattern
All components use:
- **Border Radius**: `BorderRadius.circular(12-20)` (modern rounded corners)
- **Shadows**: `BoxShadow(color: primaryBrown.withValues(alpha: 0.15), blur: 12)`
- **Animations**: `ScaleTransition` on hover, `AnimatedContainer` for state changes
- **Dialogs**: Custom styled with gradient backgrounds, `Dialog()` not `AlertDialog()`

---

## 🔄 Key Workflows

### Adding New Screens
1. Create file in `lib/screens/` with `StatefulWidget`
2. Use `AppBar` with `backgroundColor: primaryBrown`
3. Wrap content in `Container(decoration: BoxDecoration(gradient: LinearGradient(...)))`
4. Import `google_fonts/google_fonts.dart` for all text
5. Use `DatabaseHelper.instance` for data operations (singleton)

### Database Operations Pattern
```dart
// Always use type parameter for order separation
String type = widget.isGamingTable ? 'gaming' : 'cafeteria';
bool busy = await DatabaseHelper.instance.isTableBusy(tableNumber, type);

// Save unimplemented orders
_autoSaveCart() {
  DatabaseHelper.instance.saveUnpaidCart(tableNumber, _cart, type);
}
```

### Printing (Critical Logic)
- **Chef Receipt**: Excludes gaming products, prints new items only (`printed_quantity` tracking)
- **Customer Receipt**: Includes all items, full invoice with discount support
- **Printer Detection**: Saves printer URL to SharedPreferences, tries direct printing first

### Gaming Timer Logic
- Tracks elapsed time separately from running time (`accumulated_seconds`)
- Supports "single" and "multi" modes (prices differ)
- Resets on checkout, updates database on play/pause
- Special cart items: Items starting with "لعب" (games) auto-delete on checkout

---

## ⚡ Important State Management Rules

✅ **DO**:
- Use `setState(() { _cart = [...] })` for UI updates
- Call `_autoSaveCart()` after cart changes (persists to DB)
- Reset discount to 0 when cart modified: `_discount = 0.0`
- Check `if (mounted)` before setState in async callbacks

❌ **DON'T**:
- Change function signatures (critical for database compatibility)
- Rename variables like `_cart`, `_timers`, `_discount`
- Modify `isTableBusy()` logic without understanding type parameter
- Skip `DatabaseHelper.instance` calls (all data must persist)

---

## 🔐 Secret Developer Access
- **Keyboard Shortcut**: `Ctrl+Shift+Alt` then type "devmh"
- **Access**: Settings screen (PIN required, default: "1234")
- **Location**: `home_screen.dart` → `_handleKeyEvent()`

---

## 📦 Dependencies & Versions
- `flutter_localizations`: RTL support
- `google_fonts: ^7.0.0`: Cairo font
- `sqflite_common_ffi`: SQLite for desktop
- `pdf & printing`: Receipt generation & printer management
- `shared_preferences`: Local settings storage
- `file_picker`: Image/file uploads

---

## 🎯 UI/UX Upgrade Status ✨

### Completed
✅ **main.dart**: Full theme setup with color palette, typography  
✅ **home_screen.dart**: Gradient backgrounds, improved TabBar, premium AppBar  
✅ **table_card.dart**: Modern card design with hover animations, status badges  
✅ **table_details_screen.dart**: Redesigned product grid, invoice panel with color-coded items  
✅ **main_drawer.dart**: Gradient drawer, themed menu items with icon containers  
✅ **expenses_screen.dart**: Custom dialog styling, premium list items  
✅ **SubTimerCard**: Enhanced timer UI with gradient borders, modern controls  

### Remaining (Lower Priority - Same Pattern)
- **categories_screen.dart**: Apply dialog & list styling (follow expenses_screen pattern)
- **products_screen.dart**: Product card redesign (follow table_details_screen pattern)
- **statistics_screen.dart**: Dashboard styling (follow home_screen pattern)
- **settings_screen.dart**: Form styling (follow expenses_screen dialog pattern)
- **gaming_settings_screen.dart**: Config UI (follow settings pattern)
- **printer_settings_screen.dart**: Settings form (follow settings pattern)
- **table_settings_screen.dart**: Table management (follow products pattern)

---

## 🚀 Development Guidelines

### When Implementing UI Changes
1. **Preserve Logic**: Never modify `setState`, callbacks, or database operations
2. **Consistent Styling**: Copy border radius (16), shadow, gradient patterns from completed screens
3. **Accessibility**: Always use semantic colors (gaming=purple, cafeteria=brown, errors=red)
4. **Typography**: All text must use `GoogleFonts.cairo()` with appropriate weights
5. **Responsiveness**: Use `Expanded`, `flex`, and proper padding for desktop layout

### Testing Checklist
- [ ] No console errors when adding products
- [ ] Cart persists across screen navigation
- [ ] Discount calculation works correctly
- [ ] Printing uses correct printer (chef vs cashier)
- [ ] Gaming timers increment properly
- [ ] Orders marked as "busy" correctly
- [ ] Expenses appear in statistics

---

## 📝 Notes
- Always test with both cafeteria and gaming tables (different logic paths)
- Desktop platform (Linux/Windows/Mac) - consider hover states
- RTL layout managed by localization - no manual direction changes needed
- All colors and fonts are centrally defined; avoid hardcoding
