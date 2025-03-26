// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bd_terminal/main.dart';
import 'package:bd_terminal/services/local_storage_service.dart';
import 'package:bd_terminal/services/audio_service.dart';
import 'package:bd_terminal/models/message.dart';

// Mock implementations for testing
class MockLocalStorageService extends LocalStorageService {
  @override
  Future<void> init() async {
    // No-op for testing
  }
  
  @override
  Future<void> saveMessage(Message message) async {
    // No-op for testing
  }
  
  @override
  List<Message> getMessages() {
    return <Message>[];
  }
}

class MockAudioService extends AudioService {
  @override
  void playKeySound() {
    // No-op for testing
  }
  
  @override
  void playMessageSound() {
    // No-op for testing
  }
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      DemoTerminalApp(
        audioService: MockAudioService(),
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
