import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const brandPurple = Color(0xFF9560FF);
const brandPurpleLight = Color(0xFFB99AFF);
const bg = Color(0xFF080910);
const panel = Color(0xFF10121D);
const panel2 = Color(0xFF171927);
const borderColor = Color(0xFF29243D);
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool get backendConfigured => supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (backendConfigured) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(const TwoPiApp());
}

class Product {
  const Product({required this.id, required this.name, required this.subtitle, required this.category, required this.price, required this.icon, this.tag});
  final String id, name, subtitle, category;
  final double price;
  final IconData icon;
  final String? tag;
}

const products = <Product>[
  Product(id: 'pubg-uc', name: 'PUBG Mobile', subtitle: 'شحن UC', category: 'games', price: 4.99, icon: Icons.sports_esports_rounded, tag: 'الأكثر طلبًا'),
  Product(id: 'free-fire', name: 'Free Fire', subtitle: 'Diamonds', category: 'games', price: 3.49, icon: Icons.local_fire_department_rounded),
  Product(id: 'mlbb', name: 'Mobile Legends', subtitle: 'Diamonds', category: 'games', price: 2.99, icon: Icons.bolt_rounded),
  Product(id: 'roblox', name: 'Roblox', subtitle: 'Robux', category: 'games', price: 5.99, icon: Icons.toys_rounded),
  Product(id: 'google-play', name: 'Google Play', subtitle: 'بطاقات هدايا', category: 'gift', price: 10.00, icon: Icons.shop_rounded),
  Product(id: 'app-store', name: 'App Store', subtitle: 'بطاقات هدايا', category: 'gift', price: 10.00, icon: Icons.apple_rounded),
  Product(id: 'spotify', name: 'Spotify', subtitle: 'Premium', category: 'apps', price: 5.49, icon: Icons.music_note_rounded),
  Product(id: 'netflix', name: 'Netflix', subtitle: 'اشتراك رقمي', category: 'apps', price: 7.99, icon: Icons.movie_rounded),
  Product(id: 'youtube', name: 'YouTube', subtitle: 'Premium', category: 'apps', price: 6.49, icon: Icons.play_circle_fill_rounded),
  Product(id: 'discord', name: 'Discord Nitro', subtitle: 'اشتراك رقمي', category: 'apps', price: 8.99, icon: Icons.forum_rounded),
];

class TwoPiApp extends StatelessWidget {
  const TwoPiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '2pi STORE', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: brandPurple, brightness: Brightness.dark, surface: panel),
      fontFamily: 'Roboto', appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: Colors.white),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: brandPurple))),
    ), home: const StoreHome());
}

class StoreHome extends StatefulWidget { const StoreHome({super.key}); @override State<StoreHome> createState() => _StoreHomeState(); }
class _StoreHomeState extends State<StoreHome> {
  final Map<String, int> cart = {};
  final searchController = TextEditingController();
  String category = 'all';
  int tab = 0;
  String coupon = '';
  bool busy = false;
  List<Product> get visibleProducts => products.where((p) => (category == 'all' || p.category == category) && ('${p.name} ${p.subtitle}'.toLowerCase().contains(searchController.text.trim().toLowerCase()))).toList();
  int get cartCount => cart.values.fold(0, (a, b) => a + b);
  double get subtotal => cart.entries.fold(0, (sum, e) => sum + (products.firstWhere((p) => p.id == e.key).price * e.value));
  double get discount => coupon.trim().toUpperCase() == '2PI10' ? subtotal * .10 : 0;
  double get total => subtotal - discount;

  @override void dispose() { searchController.dispose(); super.dispose(); }
  void add(Product p) { setState(() => cart[p.id] = (cart[p.id] ?? 0) + 1); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة ${p.name} للسلة'), duration: const Duration(seconds: 1), backgroundColor: panel2)); }
  void quantity(Product p, int delta) { setState(() { final n = (cart[p.id] ?? 0) + delta; if (n <= 0) { cart.remove(p.id); } else { cart[p.id] = n; } }); }
  void goCart() => showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: panel, builder: (_) => StatefulBuilder(builder: (context, refresh) => cartSheet(refresh)));

  Widget cartSheet(StateSetter refresh) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 20), child: SizedBox(height: MediaQuery.of(context).size.height * .76, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [const Expanded(child: Text('سلة المشتريات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
    const Divider(color: borderColor),
    Expanded(child: cart.isEmpty ? const Center(child: Text('السلة فارغة حاليًا', style: TextStyle(color: Colors.white60))) : ListView(children: cart.entries.map((e) { final p = products.firstWhere((x) => x.id == e.key); return ListTile(leading: productIcon(p, 44), title: Text(p.name), subtitle: Text('$${p.price.toStringAsFixed(2)} × ${e.value}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () { quantity(p, -1); refresh(() {}); }, icon: const Icon(Icons.remove_circle_outline)), Text('${e.value}'), IconButton(onPressed: () { quantity(p, 1); refresh(() {}); }, icon: const Icon(Icons.add_circle_outline))])); }).toList())),
    TextField(decoration: const InputDecoration(labelText: 'كود الخصم', hintText: 'جرّب 2PI10', prefixIcon: Icon(Icons.sell_outlined)), onChanged: (v) { coupon = v; refresh(() {}); }),
    const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الإجمالي', style: TextStyle(fontSize: 17)), Text('$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, color: brandPurpleLight, fontWeight: FontWeight.bold))]),
    if (coupon.trim().isNotEmpty && discount == 0) const Padding(padding: EdgeInsets.only(top: 5), child: Text('الكود غير صالح في النسخة التجريبية.', style: TextStyle(color: Colors.orangeAccent, fontSize: 12))),
    const SizedBox(height: 12), FilledButton.icon(onPressed: cart.isEmpty ? null : () { Navigator.pop(context); checkout(); }, icon: const Icon(Icons.lock_outline), label: const Padding(padding: EdgeInsets.all(12), child: Text('متابعة الطلب'))),
    const SizedBox(height: 8), const Text('الدفع والتسليم الحقيقيان غير مفعّلين في النسخة التجريبية.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11)),
  ]))));

  Future<void> checkout() async {
    if (cart.isEmpty) return;
    final name = TextEditingController(), email = TextEditingController(), gameId = TextEditingController(), notes = TextEditingController();
    String paymentMethod = 'local_transfer';
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(backgroundColor: panel, title: const Text('إتمام الطلب'), content: SizedBox(width: 460, child: SingleChildScrollView(child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('أدخل بيانات التواصل بدقة. لا ترسل كلمة مرور حساب اللعبة أو بيانات بطاقتك هنا.', style: TextStyle(color: Colors.white60, fontSize: 12)), const SizedBox(height: 12),
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الكامل'), validator: (v) => v == null || v.trim().length < 2 ? 'أدخل اسمًا صحيحًا' : null), const SizedBox(height: 10),
      TextFormField(controller: email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني'), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || !v.contains('@') || !v.contains('.') ? 'أدخل بريدًا صحيحًا' : null), const SizedBox(height: 10),
      TextFormField(controller: gameId, decoration: const InputDecoration(labelText: 'معرّف اللاعب / تفاصيل التسليم (إن لزم)')), const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: paymentMethod, decoration: const InputDecoration(labelText: 'طريقة الدفع المطلوبة'), items: const [DropdownMenuItem(value: 'local_transfer', child: Text('تحويل محلي / محفظة')), DropdownMenuItem(value: 'card', child: Text('بطاقة مصرفية — عند توفر بوابة الدفع'))], onChanged: (v) => refresh(() => paymentMethod = v ?? 'local_transfer')),
      const SizedBox(height: 10), TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظات إضافية (اختياري)'), maxLines: 2), const SizedBox(height: 10),
      Text('الإجمالي: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: brandPurpleLight)),
    ]))), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(ctx, true); }, child: const Text('إنشاء الطلب'))]));
    if (ok != true || !mounted) { name.dispose(); email.dispose(); gameId.dispose(); notes.dispose(); return; }
    final submittedTotal = total;
    final submittedSubtotal = subtotal;
    final submittedDiscount = discount;
    setState(() => busy = true);
    try {
      final orderItems = cart.entries.map((e) { final p = products.firstWhere((x) => x.id == e.key); return {'product_id': p.id, 'product_name': p.name, 'quantity': e.value, 'unit_price': p.price}; }).toList();
      // Never trust totals or coupon values calculated by a mobile client.
      // A server-side order Edge Function must validate DB prices/coupons before live orders are enabled.
      if (backendConfigured) {
        throw Exception('تم إعداد تسجيل الدخول، لكن إنشاء الطلبات الحقيقي متوقف حتى ربط Edge Function آمنة تتحقق من الأسعار والخصومات على الخادم.');
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
      if (!mounted) return;
      setState(() { cart.clear(); coupon = ''; });
      Navigator.of(context).popUntil((r) => r.isFirst);
      showDialog<void>(context: context, builder: (ctx) => AlertDialog(backgroundColor: panel, icon: const Icon(Icons.check_circle_outline, color: brandPurpleLight, size: 44), title: const Text('تم تسجيل طلب تجريبي'), content: Text(backendConfigured ? 'تم إرسال الطلب إلى النظام بحالة انتظار الدفع. لن يتم التسليم حتى يتحقق المسؤول من الدفع.' : 'هذا تأكيد محلي للتجربة فقط؛ لم يُرسل طلب إلى خادم ولم يتم تحصيل أي مبلغ.\nالمجموع: \$${total.toStringAsFixed(2)}'), actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسنًا'))]));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء الطلب: ${e.toString().replaceFirst('Exception: ', '')}')));
    } finally { name.dispose(); email.dispose(); gameId.dispose(); notes.dispose(); if (mounted) setState(() => busy = false); }
  }

  Future<void> signIn() async {
    final email = TextEditingController(), password = TextEditingController();
    bool create = false;
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(backgroundColor: panel, title: Text(create ? 'إنشاء حساب 2pi' : 'تسجيل الدخول'), content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')), const SizedBox(height: 10), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور'))])), actions: [TextButton(onPressed: () => refresh(() => create = !create), child: Text(create ? 'لدي حساب بالفعل' : 'إنشاء حساب')), FilledButton(onPressed: () async { try { if (!backendConfigured) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تسجيل الدخول الحقيقي يتطلب إعداد Supabase.'))); return; } if (create) { await Supabase.instance.client.auth.signUp(email: email.text.trim(), password: password.text); } else { await Supabase.instance.client.auth.signInWithPassword(email: email.text.trim(), password: password.text); } if (ctx.mounted) Navigator.pop(ctx); if (mounted) setState(() {}); } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('تعذر تسجيل الدخول: $e'))); } }, child: Text(create ? 'إنشاء الحساب' : 'دخول')])));
    email.dispose(); password.dispose();
  }

  @override Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final currentUser = backendConfigured ? Supabase.instance.client.auth.currentUser : null;
    return Scaffold(
      appBar: AppBar(toolbarHeight: 72, titleSpacing: 18, title: GestureDetector(onTap: () => setState(() => tab = 0), child: const BrandMark()), actions: [if (wide) TextButton(onPressed: () => setState(() { tab = 0; category = 'all'; }), child: const Text('الرئيسية')), if (wide) TextButton(onPressed: () => setState(() { tab = 0; category = 'games'; }), child: const Text('الألعاب')), if (wide) TextButton(onPressed: () => setState(() { tab = 0; category = 'apps'; }), child: const Text('التطبيقات')), IconButton(tooltip: 'تسجيل الدخول', onPressed: signIn, icon: Icon(currentUser == null ? Icons.person_outline : Icons.verified_user_outlined, color: brandPurpleLight)), Padding(padding: const EdgeInsets.only(right: 12), child: Stack(alignment: Alignment.topRight, children: [IconButton(tooltip: 'السلة', onPressed: goCart, icon: const Icon(Icons.shopping_bag_outlined)), if (cartCount > 0) Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: brandPurple, shape: BoxShape.circle), child: Text('$cartCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))) ]))]),
      body: busy ? const Center(child: CircularProgressIndicator(color: brandPurple)) : tab == 1 ? ordersInfo() : tab == 2 ? supportPage() : storeBody(wide),
      bottomNavigationBar: NavigationBar(backgroundColor: panel, indicatorColor: brandPurple.withOpacity(.22), selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'المتجر'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'طلباتي'), NavigationDestination(icon: Icon(Icons.support_agent_outlined), label: 'الدعم')]),
    );
  }

  Widget storeBody(bool wide) => ListView(padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 8, wide ? 28 : 16, 28), children: [
    Container(padding: EdgeInsets.all(wide ? 30 : 22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF21133D), Color(0xFF10111C), Color(0xFF0B0C14)])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('YOUR DIGITAL WORLD', style: TextStyle(letterSpacing: 2, color: brandPurpleLight, fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const BrandMark(large: true), const SizedBox(height: 10), Text('متجرك الرقمي المفضّل', style: TextStyle(fontSize: wide ? 30 : 24, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text('الألعاب، التطبيقات، الاشتراكات وبطاقات الهدايا في مكان واحد.', style: TextStyle(color: Colors.white70, height: 1.6)), const SizedBox(height: 18), FilledButton.icon(onPressed: () => setState(() => category = 'all'), icon: const Icon(Icons.arrow_back_rounded), label: const Text('تسوّق الآن')), const SizedBox(height: 18), const Wrap(spacing: 14, runSpacing: 8, children: [TrustPill(icon: Icons.bolt, text: 'تسليم بعد التحقق'), TrustPill(icon: Icons.shield_outlined, text: 'إجراءات آمنة'), TrustPill(icon: Icons.support_agent, text: 'دعم العملاء')])]),
    const SizedBox(height: 24), const Text('تصفّح الأقسام', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
    Wrap(spacing: 9, runSpacing: 9, children: [categoryChip('all', 'الكل', Icons.grid_view_rounded), categoryChip('games', 'الألعاب', Icons.sports_esports_rounded), categoryChip('apps', 'التطبيقات', Icons.apps_rounded), categoryChip('gift', 'بطاقات الهدايا', Icons.card_giftcard_rounded)]),
    const SizedBox(height: 22), TextField(controller: searchController, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن لعبة أو تطبيق أو بطاقة...', suffixIcon: Icon(Icons.tune_rounded))),
    const SizedBox(height: 22), Row(children: [const Expanded(child: Text('منتجات مختارة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))), Text('${visibleProducts.length} منتجات', style: const TextStyle(color: Colors.white54, fontSize: 12))]), const SizedBox(height: 12),
    if (visibleProducts.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد نتائج مطابقة.'))),
    LayoutBuilder(builder: (context, constraints) { final width = constraints.maxWidth; final count = width >= 1100 ? 4 : width >= 700 ? 3 : width >= 440 ? 2 : 1; return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: visibleProducts.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: count == 1 ? 2.3 : 0.82), itemBuilder: (_, i) => productCard(visibleProducts[i])); }),
    const SizedBox(height: 22), Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: borderColor)), child: const Row(children: [Icon(Icons.workspace_premium_outlined, color: brandPurpleLight, size: 32), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('برنامج صُنّاع المحتوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(height: 4), Text('أكواد خصم وعمولات الشركاء ستُفعّل بعد إعداد النظام الخلفي.', style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5))]))])),
    const SizedBox(height: 24), const Center(child: Text('© 2026 2pi STORE · جميع الحقوق محفوظة', style: TextStyle(color: Colors.white38, fontSize: 11))),
  ]);

  Widget categoryChip(String id, String label, IconData icon) => ChoiceChip(selected: category == id, onSelected: (_) => setState(() => category = id), avatar: Icon(icon, size: 18, color: category == id ? Colors.white : brandPurpleLight), label: Text(label), selectedColor: brandPurple.withOpacity(.35), backgroundColor: panel, side: BorderSide(color: category == id ? brandPurple : borderColor), labelStyle: const TextStyle(fontWeight: FontWeight.w600));
  Widget productCard(Product p) => Container(decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: borderColor)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: Stack(children: [Container(width: double.infinity, decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(17)), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [brandPurple.withOpacity(.23), const Color(0xFF141522)])), child: Center(child: productIcon(p, 62))), if (p.tag != null) Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: brandPurple, borderRadius: BorderRadius.circular(8)), child: Text(p.tag!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))))])), Padding(padding: const EdgeInsets.fromLTRB(12, 11, 12, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 4), Text(p.subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)), const SizedBox(height: 10), Row(children: [Expanded(child: Text('\$${p.price.toStringAsFixed(2)}', style: const TextStyle(color: brandPurpleLight, fontSize: 16, fontWeight: FontWeight.w800))), IconButton.filled(onPressed: () => add(p), style: IconButton.styleFrom(backgroundColor: brandPurple, foregroundColor: Colors.white, minimumSize: const Size(38, 38)), icon: const Icon(Icons.add, size: 20), tooltip: 'أضف للسلة')])]))]));

  Widget ordersInfo() => ListView(padding: const EdgeInsets.all(22), children: [const Icon(Icons.receipt_long_outlined, size: 58, color: brandPurpleLight), const SizedBox(height: 14), const Text('طلباتي', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(backendConfigured && Supabase.instance.client.auth.currentUser != null ? 'سيتم ربط سجل الطلبات في خطوة إعداد قاعدة البيانات وسياسات الوصول.' : 'سجّل الدخول وتأكد من إعداد الخادم لعرض الطلبات المحفوظة. الطلبات في الوضع التجريبي لا تُحفظ على خادم.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, height: 1.7)), const SizedBox(height: 18), Center(child: FilledButton(onPressed: signIn, child: const Text('تسجيل الدخول')))]);
  Widget supportPage() => ListView(padding: const EdgeInsets.all(22), children: [const Icon(Icons.support_agent_rounded, size: 58, color: brandPurpleLight), const SizedBox(height: 14), const Text('مركز المساعدة', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Text('قبل الدفع، تأكد من اختيار المنطقة والمنتج الصحيحين. لا تشارك كلمات مرورك أو بيانات بطاقتك مع الدعم.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, height: 1.7)), const SizedBox(height: 18), OutlinedButton.icon(onPressed: () async { final uri = Uri(scheme: 'mailto', path: 'support@your-domain.com', queryParameters: {'subject': '2pi STORE support'}); if (!await launchUrl(uri) && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف بريد الدعم الحقيقي في إعدادات المشروع أولًا.'))); }, icon: const Icon(Icons.email_outlined), label: const Text('مراسلة الدعم')), const SizedBox(height: 14), const Text('يجب استبدال بريد الدعم التجريبي ببريدك الرسمي قبل النشر.', textAlign: TextAlign.center, style: TextStyle(color: Colors.orangeAccent, fontSize: 12))]);
}

Widget productIcon(Product p, double size) => Container(width: size, height: size, decoration: BoxDecoration(color: const Color(0xFF0A0B12), borderRadius: BorderRadius.circular(size * .24), border: Border.all(color: borderColor)), child: Icon(p.icon, size: size * .53, color: brandPurpleLight));
class BrandMark extends StatelessWidget { const BrandMark({super.key, this.large = false}); final bool large; @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Text('2', style: TextStyle(fontSize: large ? 54 : 30, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -4, color: Colors.white)), Text('pi', style: TextStyle(fontSize: large ? 54 : 30, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -3, color: brandPurple))]); }
class TrustPill extends StatelessWidget { const TrustPill({super.key, required this.icon, required this.text}); final IconData icon; final String text; @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: brandPurpleLight), const SizedBox(width: 5), Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70))]); }