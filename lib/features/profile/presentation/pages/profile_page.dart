import 'package:chat_app/core/widgets/app_button.dart';
import 'package:chat_app/core/widgets/app_text_field.dart';
import 'package:chat_app/core/widgets/chat_app_bar.dart';
import 'package:chat_app/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController(text: 'You');
  final _emailController = TextEditingController(text: 'you@email.com');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChatAppBar(title: 'Profile'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Center(child: UserAvatar(name: 'You', radius: 36)),
            const SizedBox(height: 24),
            AppTextField(
              controller: _nameController,
              label: 'Display name',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              enabled: false,
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Save', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
