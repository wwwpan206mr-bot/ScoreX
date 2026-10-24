import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const scoreXContactEmail = 'inf.scorex@gmail.com';

enum ScoreXLegalTopic { privacy, support, advertising, deletion }

class ScoreXLegalPage extends StatelessWidget {
  const ScoreXLegalPage({super.key, required this.topic});
  final ScoreXLegalTopic topic;

  @override
  Widget build(BuildContext context) {
    final title = switch (topic) {
      ScoreXLegalTopic.privacy => 'Privacy Policy',
      ScoreXLegalTopic.support => 'Support',
      ScoreXLegalTopic.advertising => 'Advertising Disclosure',
      ScoreXLegalTopic.deletion => 'Account & Data Deletion',
    };
    final paragraphs = switch (topic) {
      ScoreXLegalTopic.privacy => const [
        'ScoreX provides public cricket information without requiring an account.',
        'This app currently stores theme, favorite match IDs and notification preferences locally on your device using app storage.',
        'Live cricket data may later be provided by third-party services. Availability and accuracy depend on those providers.',
        'Account authentication, advertising and analytics SDKs are not active in this version. This policy must be updated before they are enabled.',
        'To clear locally stored preferences, clear the app data in your Android device settings or uninstall the app.',
        'Contact us for privacy questions or requests concerning personal data.',
      ],
      ScoreXLegalTopic.support => const [
        'For bug reports, questions, accessibility issues or feedback, contact ScoreX Support.',
        'Include your app version and a description of the problem. Do not send passwords or sensitive information.',
      ],
      ScoreXLegalTopic.advertising => const [
        'ScoreX may introduce advertising in a future release. This version does not have an advertising SDK integrated.',
        'Future advertisements must be clearly distinguishable from cricket content, must not cover scores or navigation, and must not encourage accidental taps.',
        'Where required, users will receive appropriate privacy disclosures and consent choices before personalized advertising is enabled.',
        'Advertising-related questions can be sent to the contact address below.',
      ],
      ScoreXLegalTopic.deletion => const [
        'Guest browsing does not create a ScoreX member account.',
        'To delete locally stored preferences and favorites, use Android Settings > Apps > ScoreX > Storage > Clear data. This also resets app settings.',
        'Member account registration is not yet enabled. When it is enabled, an in-app account deletion flow and related server-side deletion process must be implemented.',
        'For data access or deletion questions, contact us using the email below. State what data you are asking about; never include a password.',
      ],
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Updated: 24 October 2026'),
        const SizedBox(height: 20),
        ...paragraphs.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(p, style: const TextStyle(height: 1.5)),
        )),
        const Divider(),
        const Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText(scoreXContactEmail),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(const ClipboardData(text: scoreXContactEmail));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Support email copied')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy email address'),
        ),
      ]),
    );
  }
}
