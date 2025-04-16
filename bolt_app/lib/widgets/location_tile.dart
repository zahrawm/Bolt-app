import 'package:flutter/material.dart';

class _LocationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LocationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      onTap: () {},
    );
  }
}