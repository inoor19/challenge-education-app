import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:riverpod/riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Replace with your actual Google Form URL
  static const String deleteAccountFormUrl =
      'https://forms.gle/YOUR_GOOGLE_FORM_ID';

  Future<void> _openDeleteAccountForm() async {
    try {
      if (await canLaunchUrl(Uri.parse(deleteAccountFormUrl))) {
        await launchUrl(
          Uri.parse(deleteAccountFormUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن فتح النموذج')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        content: const Text(
          'سيتم حذف حسابك وجميع بيانات المستخدم الخاصة بك بشكل دائم.\n\n'
          'يرجى ملء النموذج أدناه لطلب حذف حسابك. سيتم معالجة طلبك خلال 30 يومًا.',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openDeleteAccountForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'طلب الحذف',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final authProvider = ref.read(authStateProvider.notifier);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontFamily: 'Tajawal')),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Account Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'الحساب',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text(
              'سياسة الخصوصية',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchUrl(
              'https://yourwebsite.com/privacy-policy',
            ),
          ),

          // Terms of Service
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text(
              'شروط الخدمة',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchUrl(
              'https://yourwebsite.com/terms-of-service',
            ),
          ),

          const Divider(),

          // Delete Account Request
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'طلب حذف الحساب',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'حذف حسابك وجميع بيانات المستخدم الخاصة بك',
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
            ),
            onTap: _showDeleteAccountDialog,
          ),

          const Divider(),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}
