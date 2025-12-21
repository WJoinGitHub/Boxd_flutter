import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: BxAppBar(title: 'Help & Support'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Connect',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            _buildItem(
              icon: Icons.list_alt,
              title: 'Compatible Devices list',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildItem(
              icon: Icons.link_off,
              title: 'Device connect failed',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildItem(
              icon: Icons.search,
              title: 'Not scaned my device',
              onTap: () {},
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 30, 20, 12),
              child: Text(
                'After-sales',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            _buildItem(
              icon: Icons.help_outline,
              title: 'QAQ 1',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildItem(
              icon: Icons.help_outline,
              title: 'QAQ 1',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildItem(
              icon: Icons.help_outline,
              title: 'QAQ 1',
              onTap: () {},
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  children: [
                    const TextSpan(text: 'Tips:Quickly contact us via '),
                    TextSpan(
                      text: 'Facebook',
                      style: TextStyle(color: Color(0xFFFF7622)),
                    ),
                    const TextSpan(text: '\nor '),
                    const TextSpan(
                      text: 'Email ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: 'contact@qimi.com',
                      style: TextStyle(color: Color(0xFFFF7622)),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black, size: 24),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: onTap,
      ),
    );
  }
}
