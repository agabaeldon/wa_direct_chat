import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wa_direct_chat/main.dart';

Future<void> pumpDirectChatPage(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pump(kSplashDuration);
  await tester.pumpAndSettle();
}

void main() {
  test('normalizes local phone numbers using the selected country code', () {
    expect(normalizePhoneNumber('0701234567'), '256701234567');
    expect(
      normalizePhoneNumber('701234567', countryCode: '254'),
      '254701234567',
    );
    expect(normalizePhoneNumber('+256 701 234 567'), '256701234567');
    expect(normalizePhoneNumber('00254701234567'), '254701234567');
  });

  testWidgets('shows splash screen before opening direct chat form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Chat Direct'), findsOneWidget);
    expect(
      find.text('Open WhatsApp and Telegram chats faster'),
      findsOneWidget,
    );
  });

  testWidgets('direct chat form renders and validates empty input', (
    WidgetTester tester,
  ) async {
    await pumpDirectChatPage(tester);

    expect(find.text('Chat Direct'), findsOneWidget);
    expect(find.text('Country code'), findsOneWidget);
    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.text('Check Number'), findsOneWidget);
    expect(find.text('Contact Developer'), findsOneWidget);

    await tester.tap(find.text('Check Number'));
    await tester.pump();

    expect(find.text('Please enter a phone number.'), findsOneWidget);
  });

  testWidgets('shows normalized number before choosing chat app', (
    WidgetTester tester,
  ) async {
    await pumpDirectChatPage(tester);

    await tester.enterText(find.byType(EditableText), '0701234567');
    await tester.tap(find.text('Check Number'));
    await tester.pumpAndSettle();

    expect(find.text('Check number'), findsOneWidget);
    expect(find.text('Open chat with +256701234567?'), findsOneWidget);
    expect(find.text('Open WhatsApp'), findsOneWidget);
    expect(find.text('Open Telegram'), findsOneWidget);
  });

  testWidgets('opens the developer contact page', (WidgetTester tester) async {
    await pumpDirectChatPage(tester);

    await tester.tap(find.text('Contact Developer'));
    await tester.pumpAndSettle();

    expect(find.text('Have direct chats with the developer.'), findsOneWidget);
    expect(find.text('WhatsApp Developer'), findsOneWidget);
    expect(find.text('Email Developer'), findsOneWidget);
    expect(find.text('+256765026870\nagabaeldon@gmail.com'), findsOneWidget);
  });
}
