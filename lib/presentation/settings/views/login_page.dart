import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/settings/views/sigup_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../app/injection_container.dart';
import '../viewModels/login_view_model.dart';
import 'forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLoading = false;
  bool isButtonEnabled = false;
  bool isPasswordValid = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listeners to check if the fields are non-empty
    _emailController.addListener(_checkFields);
    _passwordController.addListener(_checkFields);
  }

  void _checkFields() {
    setState(() {
      final isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text);
      isButtonEnabled = isEmailValid &&
          _passwordController.text.isNotEmpty &&
          _passwordController.text.length >= 6;
    });
  }

  void _login(LoginViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Call login from viewModel and pass the credentials

      final accessToken = await viewModel.login(
        _emailController.text,
        _passwordController.text,
      );

      if (accessToken != null) {
        // Login successful
        Fluttertoast.showToast(
          msg: "Logged in",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        Navigator.pop(context, "Log in Success");
      } else {
        // Login failed - error handled within viewModel and errorMessage will be populated
        if (viewModel.errorMessage != null) {
          Fluttertoast.showToast(
            msg: viewModel.errorMessage!,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      }
    } catch (e) {
      // General error handling, if something unexpected happens
      Fluttertoast.showToast(
        msg: 'An unexpected error occurred: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _googleSignIn(LoginViewModel viewModel) async {
    await viewModel.signInWithGoogle();
    if (viewModel.user != null) {
      Fluttertoast.showToast(
        msg: "Logged in with Google",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      Navigator.pop(context, "Log in Success");
    } else {
      Fluttertoast.showToast(
        msg: "Google Sign-In failed",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<LoginViewModel>(),
      child: Consumer<LoginViewModel>(builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Login')),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure elements span the full width
                children: [
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFB71C1C)),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFB71C1C)),
                      ),
                      errorStyle: TextStyle(color: Color(0xFFB71C1C)),
                    ),
                    style: TextStyle(color: Colors.black),
                    obscureText: false,
                    onChanged: (value) => email = value.trim(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: viewModel.obscureText,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          viewModel.obscureText ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: viewModel.togglePasswordVisibility,
                      ),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (value) {
                      password = value.trim();
                      setState(() {
                        isPasswordValid = password.length >= 6;
                      });
                    },
                  ),
                  SizedBox(height: 4.0),

                  // Password Validation Message
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 3.0),
                      child: Text(
                        isPasswordValid ? '' : 'Password must be at least 6 characters long',
                        style: TextStyle(
                          color: isPasswordValid ? Colors.transparent : Colors.black54,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.0),

                  // Login Button
                  viewModel.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : MaterialButton(
                    minWidth: double.infinity,
                    height: 45,
                    color: isButtonEnabled
                        ? Color.fromRGBO(51, 66, 78, 1)
                        : Color.fromRGBO(180, 180, 180, 1),
                    disabledColor: Color.fromRGBO(140, 150, 153, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onPressed: isButtonEnabled ? () => _login(viewModel) : null,
                    child: Text(
                      'Login',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 20.0),

                  // Social Login Section
                  Text(
                    "Or log in using:",
                    style: TextStyle(fontSize: 15),
                      textAlign: TextAlign.center
                  ),
                  SizedBox(height: 5.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton('images/google_logo.png', () => _googleSignIn(viewModel)),
                      _buildSocialButton('images/apple_logo.png', () => _googleSignIn(viewModel)),
                    ],
                  ),
                  SizedBox(height: 16.0),

                  // Forgot Password Button
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 45,
                    color: Color.fromRGBO(51, 66, 78, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgetPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 20.0),

                  // Signup Section
                  Text("Not a member yet? Sign up for free",
                      style: TextStyle(fontSize: 15),
                      textAlign: TextAlign.center),
                  SizedBox(height: 5.0),
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 45,
                    color: Color.fromRGBO(51, 66, 78, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onPressed: _signup,
                    child: Text(
                      'Signup',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

// Helper Method for Social Buttons
  Widget _buildSocialButton(String imagePath, VoidCallback onPressed) {
    return Container(
      width: 45,
      height: 45,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IconButton(
        icon: Image.asset(
          imagePath,
          height: 40,
          width: 40,
          fit: BoxFit.contain,
        ),
        onPressed: onPressed,
      ),
    );
  }


  void _signup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignupPage()),
    );

    if (result == "sign up success") {
      Navigator.pop(context, "Log in Success");
    }
  }
}
