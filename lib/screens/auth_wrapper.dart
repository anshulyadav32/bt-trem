import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showLogin = true;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(CheckAuthEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            ),
          );
        } else if (state is Authenticated) {
          return widget.child;
        } else {
          // Show login or signup screen
          return _showLogin
              ? LoginScreen(
                  onSignUpPressed: () {
                    setState(() {
                      _showLogin = false;
                    });
                  },
                )
              : SignUpScreen(
                  onLoginPressed: () {
                    setState(() {
                      _showLogin = true;
                    });
                  },
                );
        }
      },
    );
  }
}
