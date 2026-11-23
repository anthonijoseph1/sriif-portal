import 'package:flutter/material.dart';
import 'config.dart';
import 'core/widgets.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/incubate_page.dart';
import 'pages/portal_profile_page.dart';
import 'pages/portal_billing_page.dart';
import 'pages/portal_progress_page.dart';
import 'pages/portal_support_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_startups_page.dart';
import 'pages/admin_billing_page.dart';
import 'pages/admin_progress_page.dart';
import 'pages/admin_tickets_page.dart';
import 'pages/admin_content_page.dart';
import 'pages/admin_reports_page.dart';

void main() => runApp(const SriifApp());

class SriifApp extends StatelessWidget {
  const SriifApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '${Brand.name} Incubation Portal',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Brand.primary,
        primary: Brand.primary,
        secondary: Brand.accent,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F9FC),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    ),
    initialRoute: '/',
    onGenerateRoute: (s) => PageRouteBuilder(
      settings: s,
      transitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => resolve(s.name ?? '/'),
    ),
  );
}

// ═════════════════════════════════════════════════════════════
// ROUTES  –  ONE LINE PER PAGE.
// To add a page: create pages/my_page.dart, import it above, add a line below.
// ═════════════════════════════════════════════════════════════

/// Public pages (anyone). '/about', '/mentors'... automatically scroll the home page to that section.
final publicRoutes = <String, Widget Function()>{
  '/': () => const HomePage(),
  '/login': () => const AuthPage(),
  '/incubate': () => const IncubatePage(),
};

/// Incubatee portal (login required, role = incubatee).
final portalRoutes = <String, Widget Function()>{
  '/portal/profile': () => const ProfilePage(),
  '/portal/billing': () => const BillingPage(),
  '/portal/progress': () => const ProgressPage(),
  '/portal/support': () => const SupportPage(),
};

/// Admin / staff / mentor panel. Mentors can only open the pages listed in mentorPages (core/widgets.dart).
final adminRoutes = <String, Widget Function()>{
  '/admin/dashboard': () => const AdminDashboard(),
  '/admin/startups': () => const AdminStartups(),
  '/admin/billing': () => const AdminBilling(),
  '/admin/progress': () => const AdminProgress(),
  '/admin/tickets': () => const AdminTickets(),
  '/admin/content': () => const AdminContent(),
  '/admin/reports': () => const AdminReports(),
};

Widget resolve(String path) {
  if (path.startsWith('/portal')) {
    if (store.role != 'incubatee') return const AuthPage();
    return (portalRoutes[path] ?? portalRoutes['/portal/profile']!)();
  }
  if (path.startsWith('/admin')) {
    if (store.role != 'admin' && store.role != 'mentor') {
      return const AuthPage();
    }
    if (store.role == 'mentor' && !mentorPages.contains(path)) {
      return adminRoutes['/admin/dashboard']!();
    }
    return (adminRoutes[path] ?? adminRoutes['/admin/dashboard']!)();
  }
  final page = publicRoutes[path];
  if (page != null) return page();
  final id = path.replaceFirst('/', '');
  if (siteSections.contains(id)) return HomePage(scrollTo: id);
  return const HomePage();
}
