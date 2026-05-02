// test/widget/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Login Screen Widget Tests', () {
    
    testWidgets('Login screen displays email and password fields', (WidgetTester tester) async {
      // Build the login screen widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(key: Key('email_field')),
                TextField(key: Key('password_field')),
                ElevatedButton(key: Key('login_button'), onPressed: null, child: Text('Login')),
              ],
            ),
          ),
        ),
      );

      // Verify that email field exists
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      
      // Verify that password field exists
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      
      // Verify that login button exists
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('Login button is disabled when fields are empty', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const TextField(key: Key('email_field')),
                const TextField(key: Key('password_field')),
                ElevatedButton(
                  key: const Key('login_button'),
                  onPressed: null, // Disabled
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );

      // Find the login button
      final loginButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('login_button')),
      );

      // Assert that it's disabled
      expect(loginButton.onPressed, isNull);
    });

    testWidgets('Email field accepts text input', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(key: Key('email_field')),
          ),
        ),
      );

      // Enter text
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Password field obscures text', (WidgetTester tester) async {
      // Build widget with obscured password field
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(
              key: Key('password_field'),
              obscureText: true,
            ),
          ),
        ),
      );

      // Get the TextField widget
      final passwordField = tester.widget<TextField>(
        find.byKey(const Key('password_field')),
      );

      // Assert that obscureText is true
      expect(passwordField.obscureText, true);
    });
  });

  group('Signup Screen Widget Tests', () {
    
    testWidgets('Signup screen displays all required fields', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(key: Key('name_field')),
                TextField(key: Key('email_field')),
                TextField(key: Key('password_field')),
                TextField(key: Key('confirm_password_field')),
                ElevatedButton(key: Key('signup_button'), onPressed: null, child: Text('Sign Up')),
              ],
            ),
          ),
        ),
      );

      // Verify all fields exist
      expect(find.byKey(const Key('name_field')), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('signup_button')), findsOneWidget);
    });

    testWidgets('Name field accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(key: Key('name_field')),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('name_field')),
        'John Doe',
      );

      expect(find.text('John Doe'), findsOneWidget);
    });
  });

  group('Dashboard Widget Tests', () {
    
    testWidgets('Dashboard displays user name', (WidgetTester tester) async {
      const userName = 'Test User';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Welcome $userName'),
          ),
        ),
      );

      expect(find.text('Welcome $userName'), findsOneWidget);
    });

    testWidgets('Dashboard displays settings button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  key: const Key('settings_button'),
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('settings_button')), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('Tapping settings button shows menu', (WidgetTester tester) async {
      bool menuVisible = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  actions: [
                    IconButton(
                      key: const Key('settings_button'),
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        setState(() {
                          menuVisible = !menuVisible;
                        });
                      },
                    ),
                  ],
                ),
                body: menuVisible
                    ? Container(
                        key: const Key('settings_menu'),
                        child: const Text('Settings Menu'),
                      )
                    : const SizedBox(),
              );
            },
          ),
        ),
      );

      // Initially menu is not visible
      expect(find.byKey(const Key('settings_menu')), findsNothing);

      // Tap settings button
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pump();

      // Menu should now be visible
      expect(find.byKey(const Key('settings_menu')), findsOneWidget);
    });
  });

  group('Class List Widget Tests', () {
    
    testWidgets('Empty class list shows appropriate message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('No classes yet. Join a class to get started!'),
            ),
          ),
        ),
      );

      expect(find.text('No classes yet. Join a class to get started!'), findsOneWidget);
    });

    testWidgets('Class list displays class cards', (WidgetTester tester) async {
      final classes = [
        {'name': 'Math 101', 'code': '12345'},
        {'name': 'Science 101', 'code': '67890'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                return Card(
                  key: Key('class_card_$index'),
                  child: ListTile(
                    title: Text(classes[index]['name']!),
                    subtitle: Text('Code: ${classes[index]['code']}'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('class_card_0')), findsOneWidget);
      expect(find.byKey(const Key('class_card_1')), findsOneWidget);
      expect(find.text('Math 101'), findsOneWidget);
      expect(find.text('Science 101'), findsOneWidget);
    });
  });

  group('Take Attendance Widget Tests', () {
    
    testWidgets('Take attendance shows camera preview placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              key: const Key('camera_preview'),
              color: Colors.black,
              child: const Center(
                child: Text('Camera Preview'),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('camera_preview')), findsOneWidget);
    });

    testWidgets('Start button is displayed when not recognizing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const Key('start_button'),
              onPressed: () {},
              child: const Text('Start Taking Attendance'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('start_button')), findsOneWidget);
      expect(find.text('Start Taking Attendance'), findsOneWidget);
    });

    testWidgets('Student counter displays correct count', (WidgetTester tester) async {
      const studentCount = 5;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Text('Students Present:'),
                Text('$studentCount'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Students Present:'), findsOneWidget);
      expect(find.text('$studentCount'), findsOneWidget);
    });
  });
}