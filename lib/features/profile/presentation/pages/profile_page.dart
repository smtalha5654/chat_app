import 'package:chat_app/core/utils/validators.dart';
import 'package:chat_app/core/widgets/app_button.dart';
import 'package:chat_app/core/widgets/app_snack_bar.dart';
import 'package:chat_app/core/widgets/app_text_field.dart';
import 'package:chat_app/core/widgets/chat_app_bar.dart';
import 'package:chat_app/core/widgets/user_avatar.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:chat_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:chat_app/features/profile/presentation/bloc/profile_event.dart';
import 'package:chat_app/features/profile/presentation/bloc/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late final String _initialName;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _initialName = authState.user.displayName;
      _nameController.text = authState.user.displayName;
      _emailController.text = authState.user.email;
    } else {
      _initialName = '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }
    final name = _nameController.text.trim();
    if (name == _currentName(authState)) {
      showAppSnackBar(context, 'No changes to save');
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<ProfileBloc>().add(
      ProfileSaveRequested(uid: authState.user.id, displayName: name),
    );
  }

  String _currentName(Authenticated authState) {
    return authState.user.displayName;
  }

  void _syncAuthUser(ProfileState state) {
    final user = switch (state) {
      ProfileSuccess(:final user) => user,
      ProfileFailure(:final user) => user,
      _ => null,
    };
    if (user != null) {
      context.read<AuthBloc>().add(AuthProfileUpdated(user));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChatAppBar(title: 'Profile'),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          _syncAuthUser(state);
          if (state is ProfileSuccess) {
            showAppSnackBar(context, 'Profile updated');
          } else if (state is ProfileFailure) {
            showAppSnackBar(context, state.message);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _nameController,
                      builder: (context, value, _) {
                        final name = value.text.trim().isEmpty
                            ? _initialName
                            : value.text;
                        return UserAvatar(name: name, radius: 36);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _nameController,
                    label: 'Display name',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    validator: Validators.displayName,
                    onSubmitted: (_) => _onSave(),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    enabled: false,
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      return AppButton(
                        label: 'Save',
                        isLoading: state is ProfileSaving,
                        onPressed: _onSave,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
