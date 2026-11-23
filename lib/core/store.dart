import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../config.dart';

// ═════════════════════════════════════════════════════════════
// HELPERS
// ═════════════════════════════════════════════════════════════
class V {
  static String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  static String? email(String? v) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email';
  static String? phone(String? v) =>
      RegExp(r'^[6-9]\d{9}$').hasMatch((v ?? '').trim()) ? null : 'Enter 10-digit mobile number';
  static final _pan = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final _gst = RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');
  static String? pan(String? v) =>
      (v == null || v.isEmpty || _pan.hasMatch(v)) ? null : 'Invalid PAN (e.g. ABCDE1234F)';
  static String? gstin(String? v) =>
      (v == null || v.isEmpty || _gst.hasMatch(v)) ? null : 'Invalid GSTIN (e.g. 33ABCDE1234F1Z5)';
  static String? upi(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter UPI ID';
    return RegExp(r'^[\w.-]+@[\w.-]+$').hasMatch(value)
        ? null
        : 'Enter a valid UPI ID';
  }
}

// Existing dropdown values used by the portal forms.
class Opts {
  static const banks = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Indian Bank',
  ];

  static List<String> get reportPeriods => store.quarters;
}

double numOf(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
  return double.tryParse(cleaned) ?? 0;
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
String inr(double v) =>
    '₹${v.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
String homeFor(AppUser u) => u.role == 'incubatee' ? '/portal/profile' : '/admin/dashboard';

// ═════════════════════════════════════════════════════════════
// 5. MODELS
// ═════════════════════════════════════════════════════════════
class AppUser {
  String name, startup, email, phone, role, status; // role: incubatee | mentor | admin
  AppUser(this.name, this.startup, this.email, this.phone, this.role, this.status);
}

class Seat {
  String name;
  int rate;
  Seat(this.name, this.rate);
}

class Invoice {
  final String no, period;
  final DateTime due;
  final List<MapEntry<String, double>> lines;
  String status; // Due | Paid | Waived
  bool pending = false;
  String? receipt;
  DateTime? paidOn;
  Invoice(this.no, this.period, this.due, this.lines, {this.status = 'Due', this.receipt});
  double get sub => lines.fold(0.0, (a, e) => a + e.value);
  double get gst => sub * Brand.gstRate;
  double get total => sub + gst;
  String get shown => status == 'Due'
      ? (pending ? 'Pending' : (due.isBefore(DateTime.now()) ? 'Overdue' : 'Due'))
      : status;
}

class DocFile {
  final String type, name;
  final int size;
  final Uint8List? bytes;

  DocFile(this.type, this.name, this.size, {this.bytes});

  String get ext =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';
}

class Milestone {
  String title, desc, date, status, evidence;
  String doneOn = '';
  final List<DocFile> files = [];

  Milestone(this.title, this.desc, this.date,
      {this.status = 'Not started', this.evidence = ''});

  DateTime get when {
    final parsed = DateTime.tryParse(date);
    if (parsed != null) return parsed;

    final parts = date.trim().split(RegExp(r'\s+'));
    if (parts.length == 3) {
      const months = [
        'jan', 'feb', 'mar', 'apr', 'may', 'jun',
        'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
      ];
      final month = months.indexOf(parts[1].toLowerCase().substring(
            0,
            parts[1].length >= 3 ? 3 : parts[1].length,
          )) + 1;
      final day = int.tryParse(parts[0]);
      final year = int.tryParse(parts[2]);
      if (month > 0 && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime(2100);
  }

  bool get overdue =>
      status != 'Completed' && when.isBefore(DateTime.now());
}

class Report {
  String period, revenue, users, funding, jobs, achv, comment;
  int rating;
  Report(this.period, this.revenue, this.users, this.funding, this.jobs, this.achv,
      {this.comment = '', this.rating = 0});
}

class Ticket {
  final int id;
  final String cat, subject, priority, desc;
  String status, assignee;
  final List<String> thread = [];
  Ticket(this.id, this.cat, this.subject, this.priority, this.desc,
      {this.status = 'Open', this.assignee = 'Unassigned'});
}

class Approval {
  final String type, detail;
  String status = 'Pending';
  final VoidCallback? onApprove;
  Approval(this.type, this.detail, {this.onApprove});
}

// ═════════════════════════════════════════════════════════════
// 6. MOCK DATA STORE  (everything lives in memory – no backend)
// ═════════════════════════════════════════════════════════════
final store = Store();

class Store extends ChangeNotifier {
  AppUser? me;
  Uint8List? logo;
  String get role => me?.role ?? '';
  void login(AppUser u) { me = u; log('Logged in'); }
  void logout() { me = null; notifyListeners(); }
  void refresh() => notifyListeners();

  // CMS-editable website bits
  String tagline = Brand.tagline;
  String banner = 'Applications for the Jan 2027 cohort are open!';
  late final List<Map<String, String>> news = [...Content.news];

  // Demo users. Login with any email/phone below, OTP = Brand.demoOtp
  final users = <AppUser>[
    AppUser('Priya Raman', 'GreenLeaf Agritech', 'demo@startup.in', '9876543210', 'incubatee', 'active'),
    AppUser('Arjun Das', 'MediSense Labs', 'arjun@medisense.in', '9876500001', 'incubatee', 'active'),
    AppUser('Dr. Kumar', '-', 'mentor@sriif.in', '9000000001', 'mentor', 'active'),
    AppUser('Lakshmi (SRIIF Staff)', '-', 'admin@sriif.in', '9000000002', 'admin', 'active'),
  ];

  // Startup profile (logged-in demo startup)
  final profile = <String, String>{
    'name': 'GreenLeaf Agritech', 'legal': 'Private Limited', 'inc': '12 Mar 2025',
    'address': 'Chennai, Tamil Nadu', 'website': 'www.greenleaf.in', 'sector': 'AgriTech', 'stage': 'Early revenue',
    'desc': 'Soil-health IoT sensors for small farmers.',
    'problem': 'Farmers over-use fertiliser due to no soil data.', 'solution': 'Low-cost sensor + mobile advisory.',
    'market': '100M small farms in India', 'model': 'Hardware + subscription', 'traction': '2,000 farmers, ₹18L ARR',
    'funding': '₹2 Cr', 'video': '',
    'pan': 'ABCDE1234F', 'gstin': '', 'cin': '', 'dpiit': '', 'bank': '',
  };
  final team = <Map<String, String>>[
    {'name': 'Priya Raman', 'role': 'Founder & CEO', 'email': 'demo@startup.in', 'phone': '9876543210', 'linkedin': 'linkedin.com/in/priya'},
  ];
  final docs = <Map<String, String>>[
    {'type': 'Incorporation Certificate', 'file': 'coi.pdf', 'status': 'Verified'},
  ];

  // Seats & billing
  final seatTypes = <Seat>[Seat('Desk', 3000), Seat('Cabin', 12000), Seat('Cubicle', 6000)];
  final mySeats = <String, int>{'Desk': 4, 'Cabin': 1};
  double instrumentTariff = 5000; // per quarter
  final adjustments = <MapEntry<String, double>>[];
  final quarters = ['Jan–Mar 2027', 'Apr–Jun 2027', 'Jul–Sep 2027', 'Oct–Dec 2027'];
  int qIndex = 0, invCounter = 3, nextTicket = 1002;
  final int totalSeats = 60, othersSeats = 31;
  late final List<Invoice> invoices = [
    Invoice('SRIIF/26-27/0001', 'Apr–Jun 2026', DateTime(2026, 7, 15), _std(), status: 'Waived'),
    Invoice('SRIIF/26-27/0002', 'Jul–Sep 2026', DateTime(2026, 10, 15), _std(), status: 'Paid', receipt: 'RCT-0002'),
    Invoice('SRIIF/26-27/0003', 'Oct–Dec 2026', DateTime(2026, 12, 5), _std()),
  ];
  List<MapEntry<String, double>> _std() => [
        const MapEntry('Desk × 4 (3 months)', 36000),
        const MapEntry('Cabin × 1 (3 months)', 36000),
        const MapEntry('Instrument usage tariff', 5000),
      ];

  // Progress
  String stage = 'Active'; // Onboarded | Active | Graduated | Exited
  final milestones = <Milestone>[
    Milestone('Incorporate company', 'Complete registration and PAN', '30 Apr 2025', status: 'Completed', evidence: 'COI uploaded'),
    Milestone('Launch pilot with 500 farmers', 'Deploy sensors in 3 districts', '31 Dec 2025', status: 'Completed'),
    Milestone('Reach ₹50L ARR', 'Grow subscriptions', '31 Mar 2027', status: 'In progress'),
    Milestone('Close seed round', 'Raise ₹2 Cr', '30 Jun 2027'),
  ];
  final reports = <Report>[
    Report('Jul–Sep 2026', '₹4,50,000', '2,000', '₹25,00,000', '8', 'Pilot expansion', comment: 'Good traction, improve margins.', rating: 4),
  ];

  // Support
  late final List<Ticket> tickets = [
    Ticket(1001, 'Facilities', 'Projector not working in Room 2', 'Medium', 'Projector shows no signal.',
        status: 'In Progress', assignee: 'Lakshmi (Staff)')
      ..thread.addAll(['GreenLeaf: Please check soon.', 'Lakshmi (Staff): Technician is on the way.']),
  ];

  // Admin
  late final List<Approval> approvals = [
    Approval('Registration', 'EduNext – Rahul S. (rahul@edunext.in)', onApprove: () {
      users.add(AppUser('Rahul S', 'EduNext', 'rahul@edunext.in', '9876500002', 'incubatee', 'active'));
    }),
  ];
  final notices = <String>['Welcome to the SRIIF portal!'];
  final enquiries = <String>[];
  final audit = <String>[];

  void log(String action) {
    final t = DateTime.now();
    audit.insert(0,
        '${fmt(t)} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} | ${me?.name ?? 'System'} | $action | IP 103.21.x.x (demo)');
    notifyListeners();
  }

  double get completion =>
      milestones.isEmpty ? 0 : milestones.where((m) => m.status == 'Completed').length / milestones.length;
}
