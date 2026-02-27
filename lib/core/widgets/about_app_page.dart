import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  PackageInfo? _packageInfo;

  static final Uri _contactUsUri = Uri.parse(
    'https://sites.google.com/view/zarmira-contact/home',
  );
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://hurairamuzammal.github.io/cricket_world_github/',
  );

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) {
        return;
      }
      setState(() => _packageInfo = info);
    } catch (_) {
      // Ignore failures; fallback labels will be used.
    }
  }

  Future<void> _launchExternalLink(Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open link.')));
    }
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String label,
    required Uri uri,
  }) {
    final colors = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: () => _launchExternalLink(uri),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: colors.onPrimary,
        backgroundColor: colors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colors.primary.withOpacity(0.14),
              child: Icon(icon, color: colors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface.withOpacity(0.72),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Cricket World',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      backgroundColor: colors.surface,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icons/icon.png',
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Cricket World',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Follow every match with live scores, sharp analysis, and curated stories crafted for passionate fans.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurface.withOpacity(0.72),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildLinkButton(
                        icon: Icons.mail_outline,
                        label: 'Contact Us',
                        uri: _contactUsUri,
                      ),
                      _buildLinkButton(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        uri: _privacyPolicyUri,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildInfoTile(
                icon: Icons.person_outline,
                title: 'Built by',
                subtitle: 'Muhammad Abu Huraira (Zarmira Apps)',
              ),
              _buildInfoTile(
                icon: Icons.sports_cricket_outlined,
                title: 'Mission',
                subtitle:
                    'Bring every cricket fan closer to the action with timely scores, news, and insights.',
              ),
              _buildInfoTile(
                icon: Icons.update,
                title: 'App version',
                subtitle: _packageInfo != null
                    ? '${_packageInfo!.version} (build ${_packageInfo!.buildNumber})'
                    : 'Version details pending',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'What to expect',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '- Live match coverage with intuitive score visualisations.\n- Latest headlines and curated stories around the cricketing world.\n- A clean, dynamic interface that adapts to your theme preferences.\n- Constant improvements crafted with feedback from the community.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.5,
                      color: colors.onSurface.withOpacity(0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: colors.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Need a hand?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reach out anytime via the contact link above for support, partnerships, or media enquiries.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSecondaryContainer.withOpacity(0.86),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
