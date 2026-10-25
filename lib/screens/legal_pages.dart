import 'package:flutter/material.dart';
import '../widgets/scorex_ads.dart';
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
        'Live cricket data is supplied by third-party services. Availability and accuracy depend on those providers.',
        'Firebase Authentication handles email/password, Google and anonymous guest sign-in. Account information can include your UID, email, display name and Google profile photo. Theme and favorites remain on your device.',
        'Advertising uses Google AdMob. It may process device identifiers, IP address, diagnostics and ad interactions to deliver and measure ads and prevent fraud. Consent is checked through Google User Messaging Platform. Required privacy choices are accessible in Settings. Google privacy: https://policies.google.com/privacy',
        'To clear locally stored preferences, clear the app data in your Android device settings or uninstall the app.',
        'Contact us for privacy questions or requests concerning personal data.',
      ],
      ScoreXLegalTopic.support => const [
        'For bug reports, questions, accessibility issues or feedback, contact ScoreX Support.',
        'Include your app version and a description of the problem. Do not send passwords or sensitive information.',
      ],
      ScoreXLegalTopic.advertising => const [
        'ScoreX integrates Google AdMob banner and native advertisements. Builds use Google test advertisements until publisher placements are configured; test ads do not earn revenue.',
        'Advertisements are labelled and displayed in dedicated spaces outside scores and navigation. Ad content is supplied by the advertising provider; an advertisement is not an endorsement by ScoreX.',
        'Google Mobile Ads may process device or advertising identifiers, IP address, diagnostics and ad interactions for ad delivery, measurement and fraud prevention. Google User Messaging Platform checks consent before ads are requested. Where required, review your choices using Ad privacy choices in Settings or this page. See https://policies.google.com/privacy and https://policies.google.com/technologies/ads.',
        'Advertising-related questions can be sent to the contact address below.',
      ],
      ScoreXLegalTopic.deletion => const [
        'Guest browsing may use an anonymous Firebase UID. Google and email sign-in use a Firebase account.',
        'To delete locally stored preferences and favorites, use Android Settings > Apps > ScoreX > Storage > Clear data. This also resets app settings.',
        'For signed-in accounts, open My profile & account to access account deletion. Authentication may require a recent sign-in. Contact support for data deletion questions.',
        'For data access or deletion questions, contact us using the email below. State what data you are asking about; never include a password.',
      ],
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Updated: 26 October 2026'),
        const SizedBox(height: 20),
        ...paragraphs.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(p, style: const TextStyle(height: 1.5)),
        )),
        const AdsPrivacyTile(),
        const Divider(),
        const Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const SelectableText(scoreXContactEmail),
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
