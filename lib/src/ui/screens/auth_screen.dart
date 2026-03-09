import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {

  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool hoverLogin = false;
  bool hoverSignup = false;
  bool isLoading = false;

  late AnimationController loadingController;

  @override
  void initState() {
    super.initState();

    loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    loadingController.dispose();
    super.dispose();
  }

  void login() async {
    if (_formKey.currentState!.validate()) {

      setState(() {
        isLoading = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),

      body: Stack(
        children: [

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [

                    const SizedBox(height: 30),

                    Image.asset(
                      "assets/images/logo.png",
                      height: 170,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Vaayu",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F4C45),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Smart Air Monitoring",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 40),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: const Color(0xFF9ED9D3),
                                width: 1.5,
                              ),
                            ),
                            child: TextFormField(
                              controller: userController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Enter username or email";
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: "Username or Email",
                                prefixIcon: Icon(Icons.person_outline),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 18),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: const Color(0xFF9ED9D3),
                                width: 1.5,
                              ),
                            ),
                            child: TextFormField(
                              controller: passwordController,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Enter password";
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: "Password",
                                prefixIcon: Icon(Icons.lock_outline),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 18),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Color(0xFF0F4C45),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) => setState(() => hoverLogin = true),
                            onExit: (_) => setState(() => hoverLogin = false),
                            child: GestureDetector(
                              onTap: login,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: hoverLogin ? 1.05 : 1,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    gradient: LinearGradient(
                                      colors: hoverLogin
                                          ? [
                                              const Color(0xFF20C9B2),
                                              const Color(0xFF1C8DB5),
                                            ]
                                          : [
                                              const Color(0xFF1CB5A3),
                                              const Color(0xFF1C8DB5),
                                            ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.teal.withOpacity(0.35),
                                        blurRadius: hoverLogin ? 18 : 10,
                                        offset: const Offset(0, 5),
                                      )
                                    ],
                                  ),
                                  child: const Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Sign In",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(Icons.arrow_forward,
                                            color: Colors.white)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: Colors.grey),
                              ),

                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (_) => setState(() => hoverSignup = true),
                                onExit: (_) => setState(() => hoverSignup = false),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, "/register");
                                  },
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      color: hoverSignup
                                          ? const Color(0xFF1C8DB5)
                                          : const Color(0xFF1CB5A3),
                                      fontWeight: FontWeight.bold,
                                      fontSize: hoverSignup ? 18 : 16,
                                    ),
                                    child: const Text("Sign Up"),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isLoading)
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF6F7F9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      ScaleTransition(
                        scale: Tween(begin: 0.9, end: 1.1).animate(
                          CurvedAnimation(
                            parent: loadingController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Image.asset(
                          "assets/images/logo.png",
                          height: 100,
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Signing you in...",
                        style: TextStyle(
                          color: Color(0xFF0F4C45),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const CircularProgressIndicator(
                        color: Color(0xFF1CB5A3),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }
}