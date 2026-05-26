import 'dart:async';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const Duration kSplashDuration = Duration(seconds: 2);
const String kDeveloperPhoneNumber = '256765026870';
const String kDeveloperEmail = 'agabaeldon@gmail.com';

enum ChatPlatform { whatsapp, telegram }

void main() {
  runApp(const MyApp());
}

String normalizePhoneNumber(String value, {String countryCode = '256'}) {
  var phoneNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
  final cleanCountryCode = countryCode.replaceAll(RegExp(r'[^0-9]'), '');
  final hasInternationalPrefix =
      value.trimLeft().startsWith('+') || phoneNumber.startsWith('00');

  if (phoneNumber.startsWith('00')) {
    phoneNumber = phoneNumber.replaceFirst(RegExp(r'^00+'), '');
  }

  if (hasInternationalPrefix ||
      (cleanCountryCode.isNotEmpty &&
          phoneNumber.startsWith(cleanCountryCode))) {
    return phoneNumber;
  }

  if (phoneNumber.startsWith('0')) {
    phoneNumber = phoneNumber.replaceFirst(RegExp(r'^0+'), '');
  }

  if (cleanCountryCode.isEmpty) {
    return phoneNumber;
  }

  return '$cleanCountryCode$phoneNumber';
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.18),
      child: Image.asset(
        'icons/mipmap-hdpi/ic_launcher_round.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat Direct',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF25D366)),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(kSplashDuration, _goToHomePage);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToHomePage() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DirectChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const AppLogo(size: 86),
              ),
              const SizedBox(height: 24),
              Text(
                'Chat Direct',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Open WhatsApp and Telegram chats faster',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DirectChatPage extends StatefulWidget {
  const DirectChatPage({super.key});

  @override
  State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+256';
  bool _isLaunching = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsAppChat() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phoneNumber = normalizePhoneNumber(
      _phoneController.text,
      countryCode: _selectedCountryCode,
    );
    final selectedPlatform = await _confirmNumber(phoneNumber);

    if (selectedPlatform == null || !mounted) {
      return;
    }

    switch (selectedPlatform) {
      case ChatPlatform.whatsapp:
        await _launchWhatsAppChat(phoneNumber);
      case ChatPlatform.telegram:
        await _launchTelegramChat(phoneNumber);
    }
  }

  Future<ChatPlatform?> _confirmNumber(String phoneNumber) async {
    return showDialog<ChatPlatform>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Check number'),
          content: Text('Open chat with +$phoneNumber?'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(ChatPlatform.whatsapp),
                  icon: const Icon(Icons.chat),
                  label: const Text('Open WhatsApp'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(ChatPlatform.telegram),
                  icon: const Icon(Icons.send),
                  label: const Text('Open Telegram'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchWhatsAppChat(String phoneNumber) async {
    final appUri = Uri.parse('whatsapp://send?phone=$phoneNumber');
    final webUri = Uri.parse('https://wa.me/$phoneNumber');

    setState(() {
      _isLaunching = true;
    });

    try {
      final openedApp = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );

      if (!openedApp) {
        final openedWeb = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );

        if (!openedWeb && mounted) {
          _showMessage('Could not open WhatsApp for this number.');
        }
      }
    } catch (_) {
      if (mounted) {
        _showMessage('WhatsApp could not be opened. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  Future<void> _launchTelegramChat(String phoneNumber) async {
    final telegramUri = Uri.parse('tg://resolve?phone=$phoneNumber');

    setState(() {
      _isLaunching = true;
    });

    try {
      final openedTelegram = await launchUrl(
        telegramUri,
        mode: LaunchMode.externalApplication,
      );

      if (!openedTelegram && mounted) {
        _showMessage('Could not open Telegram for this number.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Telegram could not be opened. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: const Text('Chat Direct'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 112),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(child: AppLogo(size: 76)),
                const SizedBox(height: 24),
                Text(
                  'Start WhatsApp or Telegram chats without saving the number.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Country code',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: CountryCodePicker(
                    onChanged: (country) {
                      setState(() {
                        _selectedCountryCode = country.dialCode ?? '+256';
                      });
                    },
                    initialSelection: 'UG',
                    favorite: const ['+256', 'UG'],
                    showCountryOnly: false,
                    showOnlyCountryWhenClosed: false,
                    showFlag: false,
                    alignLeft: true,
                    padding: EdgeInsets.zero,
                    textStyle: Theme.of(context).textTheme.titleMedium,
                    dialogTextStyle: Theme.of(context).textTheme.bodyLarge,
                    searchDecoration: const InputDecoration(
                      labelText: 'Search country',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Enter your phone number',
                    hintText: '0701234567',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                  ),
                  validator: (value) {
                    final rawPhoneNumber = (value ?? '').replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    final phoneNumber = normalizePhoneNumber(
                      value ?? '',
                      countryCode: _selectedCountryCode,
                    );

                    if (rawPhoneNumber.isEmpty) {
                      return 'Please enter a phone number.';
                    }

                    if (phoneNumber.length < 8 || phoneNumber.length > 15) {
                      return 'Enter a valid phone number.';
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) => _openWhatsAppChat(),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _isLaunching ? null : _openWhatsAppChat,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  icon: _isLaunching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isLaunching ? 'Opening...' : 'Check Number'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ContactDeveloperPage()),
          );
        },
        icon: const Icon(Icons.support_agent),
        label: const Text('Contact Developer'),
      ),
    );
  }
}

class ContactDeveloperPage extends StatelessWidget {
  const ContactDeveloperPage({super.key});

  Future<void> _openDeveloperWhatsApp(BuildContext context) async {
    const message = 'Hello developer, I need help with Chat Direct.';
    final appUri = Uri.parse(
      'whatsapp://send?phone=$kDeveloperPhoneNumber&text=${Uri.encodeComponent(message)}',
    );
    final webUri = Uri.https('wa.me', kDeveloperPhoneNumber, {'text': message});

    try {
      final openedApp = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );

      if (!openedApp) {
        final openedWeb = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );

        if (!openedWeb && context.mounted) {
          _showMessage(context, 'Could not open WhatsApp.');
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Could not open WhatsApp.');
      }
    }
  }

  Future<void> _openDeveloperEmail(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: kDeveloperEmail,
      queryParameters: const {
        'subject': 'Chat Direct Support',
        'body': 'Hello developer, I need help with Chat Direct.',
      },
    );

    try {
      final openedEmail = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!openedEmail && context.mounted) {
        _showMessage(context, 'Could not open email app.');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Could not open email app.');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: const Text('Contact Developer'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.support_agent,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Have direct chats with the developer.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Contact the developer for support, feedback, or questions about this app.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 36),
              FilledButton.icon(
                onPressed: () => _openDeveloperWhatsApp(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp Developer'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _openDeveloperEmail(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.email),
                label: const Text('Email Developer'),
              ),
              const SizedBox(height: 24),
              Text(
                '+$kDeveloperPhoneNumber\n$kDeveloperEmail',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
