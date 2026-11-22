import 'package:flutter/material.dart';

// Models, validators and the demo data store live in core/store.dart
export 'core/store.dart';

// ═════════════════════════════════════════════════════════════
// 1. BRANDING  –  name, logo, colours, hero video
// ═════════════════════════════════════════════════════════════
class Brand {
  static const name = 'SRIIF';
  static const fullName = 'Sri Ramachandra Innovation Incubation Foundation';
  static const tagline = 'Where bold ideas become'; // first line of hero headline (admin can edit it in the portal)
  static const subTagline = 'Workspace, mentors, funding access and a community of founders – all on one campus.';
  static const since = 'Since 2018'; // badge on the About image

  // ── LOGO ── asset path ('assets/logo.png') OR web link. '' = text logo.
  static const logo = '';
  static const logoLight = ''; // optional white version for dark backgrounds
  static const logoHeight = 40.0;
  static const showNameWithLogo = true;

  // ── HERO BACKGROUND ── video: 'assets/hero.mp4' or direct .mp4 link. '' = image only.
  static const heroVideo = '';
  static const heroImage = 'https://picsum.photos/seed/sriif-hero/1600/900';

  // ── COLOURS ──
  static const primary = Color(0xFF0B3C6F);
  static const dark = Color(0xFF071F3A);
  static const accent = Color(0xFFF5A623);
  static const surface = Color(0xFFF4F7FB);

  // ── CONTACT ──
  static const email = 'incubation@sriif.in';
  static const phone = '+91 44 0000 0000';
  static const address =
      'SRIIF, Sri Ramachandra Institute of Higher Education and Research, Porur, Chennai – 600116';

  static const gstRate = 0.18;
  static const demoOtp = '123456';
  static const otpExpiryMin = 10, otpMaxResend = 3, otpMaxFail = 5;
}

// ═════════════════════════════════════════════════════════════
// 2. SITE TEXT & BUTTONS  –  every label on the home page
// ═════════════════════════════════════════════════════════════
class Site {
  static const heroEyebrow = 'UNIVERSITY STARTUP INCUBATOR · CHENNAI';
  // words that type out after the headline
  static const heroWords = ['scalable businesses', 'deep-tech ventures', 'social impact', 'global brands'];
  static const btnPrimary = 'Incubate with us';
  static const btnSecondary = 'Incubatee Login';
  static const btnExplore = 'Explore';
  // floating glass cards on the hero: [icon, title, subtitle]  (icon names: see iconOf below)
  static const heroCards = [
    ['rocket', 'Next cohort: Jan 2027', 'Applications close 15 Dec'],
    ['mentor', '100+ mentors', 'Book a 1:1 session'],
    ['money', 'Grants & angel access', 'Pitch at every Demo Day'],
  ];
  // links shown in the top bar on wide screens
  static const navQuick = ['about', 'programs', 'startups', 'events', 'contact'];
  // sections that exist on the page but are hidden from the hamburger menu
  static const hideFromMenu = ['cta', 'gallery'];

  static const ctaTitle = 'Ready to turn your idea into a company?';
  static const ctaSub = 'Applications for the next cohort are open. Tell us about your idea – our team replies within a week.';
  static const ctaButton = 'Start your application';
  static const ctaButton2 = 'Talk to us';

  static const newsletterText = 'Startup news and event invites, once a month.';
  static const contactCta = 'Start your application';
  // [label, link]
  static const socials = [
    ['LinkedIn', 'https://linkedin.com'],
    ['X', 'https://x.com'],
    ['Instagram', 'https://instagram.com'],
    ['YouTube', 'https://youtube.com'],
  ];
}

// ═════════════════════════════════════════════════════════════
// 3. PAGE SECTIONS  –  order = order on the page & in the menu.
//    Delete a name to hide a section. Move a name to re-order.
// ═════════════════════════════════════════════════════════════
const siteSections = [
  'about', 'why', 'impact', 'programs', 'journey', 'facilities', 'partners', 'ecosystem',
  'team', 'mentors', 'startups', 'stories', 'events', 'resources', 'gallery', 'faq', 'cta', 'contact',
];

// ═════════════════════════════════════════════════════════════
// 4. ICONS  –  use these names in  icon: '...'
// ═════════════════════════════════════════════════════════════
final _icons = <String, IconData>{
  'rocket': Icons.rocket_launch_outlined, 'groups': Icons.groups_outlined, 'mentor': Icons.psychology_outlined,
  'money': Icons.account_balance_wallet_outlined, 'space': Icons.apartment_outlined, 'legal': Icons.gavel_outlined,
  'market': Icons.storefront_outlined, 'talent': Icons.badge_outlined, 'lab': Icons.science_outlined,
  'network': Icons.hub_outlined, 'idea': Icons.lightbulb_outline, 'edit': Icons.edit_note, 'check': Icons.verified_outlined,
  'mic': Icons.mic_none, 'book': Icons.menu_book_outlined, 'video': Icons.play_circle_outline,
  'doc': Icons.description_outlined, 'job': Icons.work_outline, 'trophy': Icons.emoji_events_outlined,
  'globe': Icons.public, 'gov': Icons.account_balance_outlined, 'school': Icons.school_outlined,
  'invest': Icons.trending_up, 'corporate': Icons.business_outlined, 'star': Icons.star_outline,
  'event': Icons.event_outlined, 'people': Icons.people_outline, 'chart': Icons.bar_chart, 'gift': Icons.card_giftcard,
};
IconData iconOf(String n) => _icons[n] ?? Icons.star_outline;

// ═════════════════════════════════════════════════════════════
// 5. WEBSITE CONTENT
//    ADD a line = copy one and edit it.   DELETE a line = remove it.
//    item('Title', 'Tag', 'Description', img: ..., icon: ..., bullets: 'a|b|c', ...)
//    img: 'assets/photos/x.jpg' or 'https://...'   sample('seed') = placeholder photo
// ═════════════════════════════════════════════════════════════
String sample(String seed, [int w = 800, int h = 520]) => 'https://picsum.photos/seed/$seed/$w/$h';

Map<String, String> item(String title, String tag, String desc,
        {String img = '', String stat = '', String year = '', String icon = '', String bullets = '', String name = '',
        String role = '', String link = '', String place = '', String stage = '', String cta = ''}) =>
    {
      'title': title, 'tag': tag, 'desc': desc, 'img': img, 'stat': stat, 'year': year, 'icon': icon,
      'bullets': bullets, 'name': name, 'role': role, 'link': link, 'place': place, 'stage': stage, 'cta': cta,
    };

class Stat {
  final String prefix, suffix, label, icon, note;
  final double value;
  const Stat(this.prefix, this.value, this.suffix, this.label, {this.icon = 'star', this.note = ''});
}

class Content {
  // ── Section headings: [small label, big title, sub-text] ──
  static const titles = <String, List<String>>{
    'about': ['About us', 'Building the next generation of founders', 'A university incubator that turns research and ideas into real businesses.'],
    'why': ['Why SRIIF', 'Everything a founder needs, in one place', 'Six things every startup asks for – we bring them together.'],
    'impact': ['Our impact', 'Numbers that speak for our founders', 'A snapshot of what our startups have achieved with SRIIF.'],
    'programs': ['Programs', 'Find the right program for your stage', 'Pick a track on the left to see what you get and how to apply.'],
    'journey': ['The journey', 'From first idea to graduation', 'How incubation works, step by step.'],
    'facilities': ['Facilities', 'Spaces built for making things', 'Co-working, labs, meeting rooms and shared equipment.'],
    'partners': ['Partners', 'Backed by industry, government and academia', 'Organisations that open doors for our startups.'],
    'ecosystem': ['Ecosystem', 'One network, many ways to join', 'Whether you build, fund, buy or teach – there is a place for you.'],
    'team': ['Our team', 'The people behind SRIIF', 'Hover a card to read more.'],
    'mentors': ['Mentors', 'Learn from people who have done it', 'Choose a mentor to see their expertise and request a session.'],
    'startups': ['Our startups', 'Startups incubated at SRIIF', 'Search or filter by sector to explore the portfolio.'],
    'stories': ['Success stories', 'Founders who made it happen', 'Real outcomes from our incubated startups.'],
    'events': ['Events & news', 'What is happening at SRIIF', 'Workshops, demo days and the latest announcements.'],
    'resources': ['Resources', 'Learn at your own pace', 'Playbooks, podcasts and case studies from our community.'],
    'gallery': ['Life at SRIIF', 'A look inside the incubator', ''],
    'faq': ['FAQs', 'Quick answers', 'Everything founders ask before applying.'],
    'cta': ['Apply', '', ''],
    'contact': ['Contact', "Let's build something together", 'Visit us, write to us or start your application.'],
  };

  // ── Hero numbers strip (animated) ──
  static const stats = [
    Stat('', 50, '+', 'Startups incubated'),
    Stat('₹', 25, ' Cr', 'Funding raised'),
    Stat('', 100, '+', 'Mentors & experts'),
    Stat('', 25000, '', 'Sq. ft. facilities'),
  ];

  // ── About ──
  static final aboutImage = sample('sriif-about', 1000, 800);
  static final aboutImage2 = sample('sriif-about2', 600, 500);
  static const aboutIntro =
      'SRIIF is the startup incubation centre of the university. We help students, faculty, alumni and outside founders turn ideas into sustainable ventures through space, mentoring, funding access and a strong peer community.';
  static const vision = 'To be a leading university incubator that turns research and ideas into impactful ventures.';
  static const mission = 'Provide space, mentoring, funding access and networks so founders can build sustainable startups.';
  static const governance =
      'An advisory board of academicians, industry leaders and investors guides us; the program team runs day-to-day operations.';
  static const aboutPoints = [
    'Industry-grade co-working spaces and labs',
    'Structured mentoring from 100+ experts',
    'Access to grants, angel networks and VCs',
    'Compliance, legal and IP support',
  ];

  // ── Why SRIIF (icons: see iconOf) ──
  static final why = [
    item('Mentors', '', 'A panel of founders, investors and domain experts matched to your stage.', icon: 'mentor'),
    item('Money', '', 'Seed grants, angel introductions and investor demo days.', icon: 'money'),
    item('Market', '', 'Pilots and introductions to corporate and government buyers.', icon: 'market'),
    item('Space', '', 'Desks, cabins, labs and meeting rooms with 24x7 access.', icon: 'space'),
    item('Talent', '', 'Interns, student teams and faculty experts from the campus.', icon: 'talent'),
    item('Compliance', '', 'Help with incorporation, GST, DPIIT recognition, legal and IP.', icon: 'legal'),
  ];

  // ── Impact numbers (dark band) ──
  static const impact = [
    Stat('', 50, '+', 'Startups incubated', icon: 'rocket', note: 'Since 2018'),
    Stat('₹', 25, ' Cr', 'Funding raised', icon: 'money', note: 'By our portfolio'),
    Stat('', 350, '+', 'Jobs created', icon: 'job', note: 'Across Tamil Nadu'),
    Stat('', 100, '+', 'Mentors on panel', icon: 'mentor', note: 'Across 12 domains'),
    Stat('', 12, '', 'Patents filed', icon: 'doc', note: 'By incubated teams'),
    Stat('', 25000, '', 'Sq. ft. of facilities', icon: 'space', note: 'Labs, co-working, halls'),
  ];

  // ── Programs  (stage / bullets split with |  / cta = button label) ──
  static final programs = [
    item('Pre-Incubation', '6 months', 'Validate your idea with mentors and a small seed grant before you build.',
        img: sample('prog1', 1000, 600), icon: 'idea', stage: 'Idea stage',
        bullets: 'Idea validation workshops|Seed grant support|Free co-working hours|Mentor matching', cta: 'Apply for Pre-Incubation'),
    item('Incubation', '24 months', 'A seat, mentoring, compliance help and investor access while you build and launch.',
        img: sample('prog2', 1000, 600), icon: 'rocket', stage: 'Prototype to revenue',
        bullets: 'Dedicated seat or cabin|Lab & instrument access|Legal, IP and GST support|Investor demo days', cta: 'Apply for Incubation'),
    item('Acceleration', '12 months', 'Scale-up support for startups with early revenue and a repeatable product.',
        img: sample('prog3', 1000, 600), icon: 'chart', stage: 'Revenue stage',
        bullets: 'Corporate pilot introductions|Fundraising prep|Hiring support|Go-to-market mentors', cta: 'Apply for Acceleration'),
    item('Women Founders', '12 months', 'A dedicated track with mentors, peer circles and funding access for women-led startups.',
        img: sample('prog4', 1000, 600), icon: 'people', stage: 'Any stage',
        bullets: 'Peer founder circles|Mentors who have been there|Grant & investor access', cta: 'Apply to Women Founders'),
  ];

  // ── Journey steps (tag = timing) ──
  static final journey = [
    item('Apply', 'Week 1', 'Send your idea through the online form.', icon: 'edit'),
    item('Screen', 'Week 2', 'Our team reviews and meets you.', icon: 'check'),
    item('Pitch', 'Week 3', 'Present to the selection panel.', icon: 'mic'),
    item('Onboard', 'Week 4', 'Sign the agreement and register on the portal.', icon: 'doc'),
    item('Build', 'Months 1–24', 'Use seats, labs, mentors and grants.', icon: 'rocket'),
    item('Graduate', 'Month 24', 'Move on as an alumnus of SRIIF.', icon: 'trophy'),
  ];

  // ── Facilities (first one is shown large) ──
  static final facilities = [
    item('Co-working Space', '120 seats', 'Desks, cabins and cubicles with 24x7 access.', img: sample('fac1', 1000, 1000)),
    item('Prototyping Lab', 'Hardware', '3D printers, electronics bench and testing tools.', img: sample('fac2')),
    item('Meeting Rooms', '6 rooms', 'Bookable rooms with video-conferencing.', img: sample('fac3')),
    item('Instrument Facility', 'Pay per use', 'Shared analytical instruments billed by usage.', img: sample('fac4')),
    item('Event Hall', '150 people', 'For demo days, workshops and meetups.', img: sample('fac5')),
  ];

  // ── Partners (add img: 'logo.png' to show a logo instead of an icon) ──
  static final partners = [
    item('Startup TN', 'Government', ''),
    item('DST – NIDHI', 'Government', ''),
    item('Tech Corp India', 'Industry', ''),
    item('IIT Madras Research Park', 'Academic', ''),
    item('Angel Network', 'Investor', ''),
    item('CloudNine Credits', 'Industry', ''),
    item('Legal Aid Foundation', 'Support', ''),
    item('Global Alumni Fund', 'Alumni', ''),
    item('MedTech Council', 'Industry', ''),
    item('AgriTech Forum', 'Industry', ''),
  ];

  // ── Ecosystem: who can join (tabs) ──
  static final audiences = [
    item('Startups', '', 'Build your venture with space, mentors, grants and a peer community around you.', icon: 'rocket',
        img: sample('eco1', 900, 700), bullets: 'Incubation seats and labs|Mentors and workshops|Grant and investor access', cta: 'Apply now'),
    item('Corporates', '', 'Pilot with early-stage startups, run challenges and source new technology.', icon: 'corporate',
        img: sample('eco2', 900, 700), bullets: 'Innovation challenges|Pilot programs|Co-creation with startups', cta: 'Partner with us'),
    item('Investors', '', 'See curated, screened deal flow and meet founders at our Demo Days.', icon: 'invest',
        img: sample('eco3', 900, 700), bullets: 'Quarterly demo days|Screened pipeline|Founder office hours', cta: 'Meet our startups'),
    item('Government', '', 'Work with us to run schemes, policy pilots and skilling for founders.', icon: 'gov',
        img: sample('eco4', 900, 700), bullets: 'Scheme implementation|Policy feedback loop|Regional outreach', cta: 'Collaborate'),
    item('Academia', '', 'Connect research labs, students and faculty to the startup world.', icon: 'school',
        img: sample('eco5', 900, 700), bullets: 'Research commercialisation|Student internships|Faculty entrepreneurship', cta: 'Join the network'),
  ];

  // ── Team (link = LinkedIn) ──
  static final team = [
    item('Dr. A. Kumar', 'CEO', 'Leads incubation strategy and partnerships.', img: sample('team1', 600, 800), link: 'https://linkedin.com'),
    item('Ms. R. Lakshmi', 'Program Manager', 'Runs cohorts, billing and onboarding.', img: sample('team2', 600, 800), link: 'https://linkedin.com'),
    item('Mr. S. Venkat', 'Head – Mentor Network', 'Connects startups with domain mentors.', img: sample('team3', 600, 800), link: 'https://linkedin.com'),
    item('Ms. P. Nair', 'Community Lead', 'Events, founder meetups and outreach.', img: sample('team4', 600, 800), link: 'https://linkedin.com'),
  ];

  // ── Mentors (tag = main expertise, role = affiliation, bullets = skill tags) ──
  static final mentors = [
    item('Dr. Kumar', 'Product & Strategy', 'Twenty years building products; helps founders find product-market fit and avoid costly pivots.',
        img: sample('men1', 700, 900), role: 'Ex-VP Product', bullets: 'Product|Strategy|Roadmaps'),
    item('Anita Rao', 'Finance & Funding', 'Seed-stage investor who guides fundraising, valuation and investor conversations.',
        img: sample('men2', 700, 900), role: 'Venture Partner', bullets: 'Fundraising|Valuation|Cap tables'),
    item('Imran Sheikh', 'Legal / IP', 'Patent attorney and startup counsel for IP strategy, contracts and compliance.',
        img: sample('men3', 700, 900), role: 'Patent Attorney', bullets: 'Patents|Contracts|Compliance'),
    item('Divya Menon', 'Marketing & Sales', 'Built go-to-market for three scale-ups; helps with first customers and pricing.',
        img: sample('men4', 700, 900), role: 'Growth Advisor', bullets: 'GTM|Pricing|Sales'),
    item('Rahul Verma', 'Deep-tech', 'Former research lead with 15 patents; supports hardware and science-based ventures.',
        img: sample('men5', 700, 900), role: 'Research Scientist', bullets: 'R&D|Prototyping|Patents'),
    item('Sunita Iyer', 'HealthTech', 'Clinician-entrepreneur who advises on trials, regulation and clinical partnerships.',
        img: sample('men6', 700, 900), role: 'Physician & Founder', bullets: 'Clinical|Regulatory|Hospitals'),
  ];

  // ── Incubated startups (tag = sector used by the filter) ──
  static final startups = [
    item('GreenLeaf Agritech', 'AgriTech', 'Soil-health IoT sensors for small farmers.', year: '2025', stage: 'Early revenue', img: sample('st1', 200, 200), link: 'https://example.com'),
    item('MediSense Labs', 'HealthTech', 'Low-cost diagnostic device in clinical trials.', year: '2024', stage: 'Seed funded', img: sample('st2', 200, 200)),
    item('EduNext', 'EdTech', 'Adaptive learning platform for schools.', year: '2024', stage: 'Growth', img: sample('st3', 200, 200)),
    item('AquaPure', 'CleanTech', 'Decentralised water purification units.', year: '2023', stage: 'Pilot', img: sample('st4', 200, 200)),
    item('FinEase', 'FinTech', 'Micro-lending app for small merchants.', year: '2025', stage: 'Seed funded', img: sample('st5', 200, 200)),
    item('RoboCart', 'Robotics', 'Warehouse automation robots.', year: '2023', stage: 'Early revenue', img: sample('st6', 200, 200)),
    item('VoiceBridge', 'AI', 'Regional-language voice assistants.', year: '2026', stage: 'Prototype', img: sample('st7', 200, 200)),
    item('BioHarvest', 'AgriTech', 'Bio-fertiliser from agri waste.', year: '2022', stage: 'Graduated', img: sample('st8', 200, 200)),
    item('CareLoop', 'HealthTech', 'Remote patient monitoring platform.', year: '2026', stage: 'Prototype', img: sample('st9', 200, 200)),
  ];

  // ── Success stories (desc = quote, name/role = founder, stat = highlight) ──
  static final stories = [
    item('GreenLeaf Agritech', 'AgriTech', 'SRIIF gave us a lab, mentors and our first pilot farms. We went from a campus prototype to 2,000 farmers in two years.',
        img: sample('ss1', 900, 800), stat: '₹1.8 Cr ARR', name: 'Priya Raman', role: 'Founder & CEO'),
    item('MediSense Labs', 'HealthTech', 'The clinical mentors and investor demo day shaved a year off our funding journey.',
        img: sample('ss2', 900, 800), stat: '₹4 Cr raised', name: 'Arjun Das', role: 'Co-founder'),
    item('EduNext', 'EdTech', 'Our first ten schools came from SRIIF introductions. Today we serve forty.',
        img: sample('ss3', 900, 800), stat: '40 schools', name: 'Rahul S', role: 'Founder'),
  ];

  // ── Events (tag = date like '15 Jan 2027', place = venue) ──
  static final events = [
    item('Demo Day 2027', '15 Jan 2027', 'Startups pitch to investors and corporates.', place: 'SRIIF Event Hall'),
    item('IP & Legal Clinic', '10 Dec 2026', 'One-to-one sessions with IP attorneys.', place: 'Meeting Room 2'),
    item('Investor Connect', '28 Feb 2027', 'Meet angel networks and seed funds.', place: 'Online'),
    item('Founders Meetup', 'Monthly', 'Peer learning and networking evening.', place: 'Cafeteria & Lounge'),
  ];
  // news added by admin in the portal also appears in Events & News
  static const news = [
    {'title': 'SRIIF startup closes seed round', 'tag': 'Nov 2026', 'desc': 'GreenLeaf Agritech raises seed funding.'},
    {'title': 'New partnership announced', 'tag': 'Oct 2026', 'desc': 'SRIIF joins hands with Startup TN.'},
  ];

  // ── Resources (tag = type, link = URL) ──
  static final resources = [
    item('Founder Talks', 'Podcast', 'Weekly conversations with founders and investors.', icon: 'mic', link: '#'),
    item('Startup Playbooks', 'Guides', 'Step-by-step guides on GST, DPIIT, hiring and fundraising.', icon: 'book', link: '#'),
    item('Case Studies', 'Stories', 'How incubated startups solved real problems.', icon: 'doc', link: '#'),
    item('Perks & Credits', 'Startup kit', 'Cloud, legal and design perks for incubated startups.', icon: 'gift', link: '#'),
  ];

  // ── Gallery photos (any image link or asset) ──
  static final gallery = [for (var i = 1; i <= 8; i++) sample('gal$i', 700, 480)];

  // ── FAQs ──
  static final faqs = [
    item('Who can apply?', '', 'Students, faculty, alumni and outside founders with a scalable idea.'),
    item('How is rent charged?', '', 'Seats are billed quarterly, with GST and the instrument usage tariff added.'),
    item('How long is incubation?', '', 'Typically 24 months, extendable on review.'),
    item('Do you take equity?', '', 'Terms are shared during onboarding; SRIIF management defines them.'),
    item('Can I use the labs without a seat?', '', 'Yes. Instruments are available on a pay-per-use basis.'),
  ];

  // ── Portal dropdown lists ──
  static const docTypes = [
    'Incorporation Certificate', 'PAN Card', 'GST Certificate', 'DPIIT Certificate', 'MoA/AoA', 'Agreement', 'IP Document'
  ];
  static const ticketCategories = ['Mentor Request', 'Facilities', 'Billing', 'Technical/IT', 'Legal/IP', 'Funding', 'Other'];
}
