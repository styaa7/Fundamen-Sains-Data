import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/student_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/lecturer_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/topic/presentation/screens/topic_form_screen.dart';
import '../../features/topic/presentation/screens/topic_detail_screen.dart';
import '../../features/topic/presentation/screens/topic_list_screen.dart';
import '../../features/consultation/presentation/screens/consultation_booking_screen.dart';
import '../../features/consultation/presentation/screens/consultation_list_screen.dart';
import '../../features/progress/presentation/screens/progress_timeline_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // STUDENT ROUTES
    GoRoute(
      path: '/student/dashboard',
      builder: (context, state) => const StudentDashboardScreen(),
    ),
    GoRoute(
      path: '/student/topic',
      builder: (context, state) => const TopicListScreen(),
    ),
    GoRoute(
      path: '/student/topic/new',
      builder: (context, state) => const TopicFormScreen(),
    ),
    GoRoute(
      path: '/student/topic/detail/:id',
      builder: (context, state) => TopicDetailScreen(topicId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/student/consultation',
      builder: (context, state) => const ConsultationListScreen(),
    ),
    GoRoute(
      path: '/student/consultation/book',
      builder: (context, state) => const ConsultationBookingScreen(),
    ),
    GoRoute(
      path: '/student/progress',
      builder: (context, state) => const ProgressTimelineScreen(),
    ),
    GoRoute(
      path: '/student/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/student/notifications',
      builder: (context, state) => const NotificationCenterScreen(),
    ),

    // LECTURER ROUTES
    GoRoute(
      path: '/lecturer/dashboard',
      builder: (context, state) => const LecturerDashboardScreen(),
    ),
    GoRoute(
      path: '/lecturer/submissions',
      builder: (context, state) => const TopicListScreen(),
    ),
    GoRoute(
      path: '/lecturer/consultations',
      builder: (context, state) => const ConsultationListScreen(),
    ),
    GoRoute(
      path: '/lecturer/students',
      builder: (context, state) => const ProgressTimelineScreen(),
    ),
    GoRoute(
      path: '/lecturer/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/lecturer/notifications',
      builder: (context, state) => const NotificationCenterScreen(),
    ),

    // ADMIN ROUTES
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);
