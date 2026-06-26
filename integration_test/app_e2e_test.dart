import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vibeco_app/main.dart';
import 'package:vibeco_app/core/services/service_locator.dart';
import 'package:vibeco_app/screens/login_screen.dart';
import 'package:vibeco_app/screens/student/student_dashboard.dart';
import 'package:vibeco_app/screens/teacher/teacher_dashboard.dart';
import 'mock_services.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockLocationService mockLocation;
  late MockHttpService mockHttp;

  setUp(() {
    mockLocation = MockLocationService();
    mockHttp = MockHttpService();
    locator.registerLocationService(mockLocation);
    locator.registerHttpService(mockHttp);
  });

  group('Tier 1: Feature Coverage Tests', () {
    testWidgets('T1_AUTH_01 & T1_AUTH_04: Student login and logout flow', (tester) async {
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role_student')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('username_field')), '12345');
      await tester.enterText(find.byKey(const ValueKey('password_field')), 'password');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      expect(find.byType(StudentDashboard), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('logout_button')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('T1_AUTH_02: Teacher (Homeroom) login flow', (tester) async {
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role_teacher')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('username_field')), '11111');
      await tester.enterText(find.byKey(const ValueKey('password_field')), 'password');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      expect(find.byType(TeacherDashboard), findsOneWidget);
      expect(find.text('Teacher - Homeroom Guru (homeroom)'), findsOneWidget);
    });

    testWidgets('T1_GEO & T1_TIME: Student geofence and time validation checks', (tester) async {
      mockLocation.setCoordinates(-6.300000, 106.816666);
      
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role_student')));
      await tester.enterText(find.byKey(const ValueKey('username_field')), '12345');
      await tester.enterText(find.byKey(const ValueKey('password_field')), 'password');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('distance_text')), findsOneWidget);
      expect(find.textContaining('Too far from school'), findsOneWidget);
      
      final submitFinder = find.byKey(const ValueKey('submit_button'));
      ElevatedButton submitBtn = tester.widget<ElevatedButton>(submitFinder);
      expect(submitBtn.onPressed, isNull);
    });

    testWidgets('T1_UPLOAD & T1_AI: Student photo upload and AI score feedback', (tester) async {
      mockLocation.setCoordinates(-6.200000, 106.816666);
      
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role_student')));
      await tester.enterText(find.byKey(const ValueKey('username_field')), '12345');
      await tester.enterText(find.byKey(const ValueKey('password_field')), 'password');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('You are at school'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('select_photos_button')));
      await tester.pumpAndSettle();
      expect(find.text('Simulated Photos Selected: 3'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('submit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('ai_score_text')), findsOneWidget);
      expect(find.text('AI Score: 85'), findsOneWidget);
      expect(find.byKey(const ValueKey('findings_list')), findsOneWidget);
    });

    testWidgets('T1_RANK: CleanRank Leaderboard navigation and own class highlight', (tester) async {
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role_student')));
      await tester.enterText(find.byKey(const ValueKey('username_field')), '12345');
      await tester.enterText(find.byKey(const ValueKey('password_field')), 'password');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.leaderboard));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('rank_tab_weekly')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rank_tab_monthly')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rank_tab_daily')));
      await tester.pumpAndSettle();

      expect(find.text('10-A'), findsOneWidget);
    });
  });

  group('Tier 2: Boundary & Corner Cases Tests', () {
    testWidgets('T2_AUTH_02: Login with incorrect credentials fails gracefully', (tester) async {
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role_student')));
      await tester.enterText(find.byKey(const ValueKey('username_field')), '12345');
      await tester.enterText(find.byKey(const ValueKey('password_field')), 'wrongpassword');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('error_message')), findsOneWidget);
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('T2_UPLOAD_01 & T2_UPLOAD_02: Photo count bounds validation checks', (tester) async {
      mockLocation.setCoordinates(-6.200000, 106.816666);
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role_student')));
      await tester.enterText(find.byKey(const ValueKey('username_field')), '12345');
      await tester.enterText(find.byKey(const ValueKey('password_field')), 'password');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('submit_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('upload_error')), findsOneWidget);
      expect(find.text('minimum 3 photos required'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('select_photos_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('select_photos_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('select_photos_button')));
      await tester.pumpAndSettle();
      expect(find.text('Simulated Photos Selected: 6'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('submit_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('upload_error')), findsOneWidget);
      expect(find.text('maximum 5 photos allowed'), findsOneWidget);
    });
  });

  group('Tier 3: Cross-Feature Combinations Tests', () {
    testWidgets('T3_COMB_03: Complete E2E score lifecycle (upload -> verify -> update rankings)', (tester) async {
      mockLocation.setCoordinates(-6.200000, 106.816666);
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role_student')));
      await tester.enterText(find.byKey(const ValueKey('username_field')), '12345');
      await tester.enterText(find.byKey(const ValueKey('password_field')), 'password');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('select_photos_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('submit_button')));
      await tester.pumpAndSettle();

      expect(mockHttp.submissions.length, 1);
      expect(mockHttp.submissions[0]['status'], 'pending');

      await tester.tap(find.byKey(const ValueKey('logout_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role_teacher')));
      await tester.enterText(find.byKey(const ValueKey('username_field')), '33333');
      await tester.enterText(find.byKey(const ValueKey('password_field')), 'password');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Teacher - PLH Guru (plh)'), findsOneWidget);
      expect(find.textContaining('Class: 10-A'), findsOneWidget);
      
      await tester.tap(find.textContaining('Class: 10-A'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('adjust_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('adjust_score_field')), '90');
      await tester.enterText(find.byKey(const ValueKey('notes_field')), 'Adjusted score to 90');
      
      await tester.tap(find.byKey(const ValueKey('submit_verification_button')));
      await tester.pumpAndSettle();

      expect(find.text('Verified successfully'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.textContaining('Class: 10-A'), findsNothing);

      await tester.tap(find.byIcon(Icons.leaderboard));
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Score: 90.0'), findsOneWidget);
    });
  });

  group('Tier 4: Real-World Application Scenarios', () {
    testWidgets('T4_SCEN_04: Out-of-bounds Geofence & Recovery flow journey', (tester) async {
      mockLocation.setCoordinates(-6.210000, 106.816666);
      
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role_student')));
      await tester.enterText(find.byKey(const ValueKey('username_field')), '12345');
      await tester.enterText(find.byKey(const ValueKey('password_field')), 'password');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Too far from school'), findsOneWidget);
      
      ElevatedButton submitBtn = tester.widget<ElevatedButton>(find.byKey(const ValueKey('submit_button')));
      expect(submitBtn.onPressed, isNull);

      mockLocation.setCoordinates(-6.200000, 106.816666);
      
      await tester.tap(find.text('Refresh Location/Settings'));
      await tester.pumpAndSettle();

      expect(find.text('You are at school'), findsOneWidget);
      
      await tester.tap(find.byKey(const ValueKey('select_photos_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('AI Score: 85'), findsOneWidget);
    });

    testWidgets('T4_SCEN_05: Holiday Blocking flow journey', (tester) async {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      mockHttp.holidays.add(todayStr);

      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role_student')));
      await tester.enterText(find.byKey(const ValueKey('username_field')), '12345');
      await tester.enterText(find.byKey(const ValueKey('password_field')), 'password');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Holiday - Upload Disabled'), findsOneWidget);

      ElevatedButton submitBtn = tester.widget<ElevatedButton>(find.byKey(const ValueKey('submit_button')));
      expect(submitBtn.onPressed, isNull);

      mockHttp.holidays.remove(todayStr);
      
      await tester.tap(find.text('Refresh Location/Settings'));
      await tester.pumpAndSettle();

      expect(find.text('You are at school'), findsOneWidget);
    });
  });
}
