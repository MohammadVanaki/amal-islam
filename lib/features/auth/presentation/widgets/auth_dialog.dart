import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/theme_provider.dart';

enum AuthMode { signIn, signUp, forgotPassword }

class AuthDialog extends ConsumerStatefulWidget {
  const AuthDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AuthDialog(),
    );
  }

  @override
  ConsumerState<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends ConsumerState<AuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  AuthMode _mode = AuthMode.signIn;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لم يتم العثور على حساب بهذا البريد الإلكتروني.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'كلمة المرور أو البريد الإلكتروني غير صحيح.';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مسجل مسبقاً.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صالحة.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً. يجب أن تتكون من 6 أحرف على الأقل.';
      case 'network-request-failed':
        return 'تعذر الاتصال بالشبكة. يرجى التحقق من اتصالك بالإنترنت.';
      default:
        return e.message ?? 'حدث خطأ أثناء المصادقة. يرجى المحاولة لاحقاً.';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);

    try {
      if (_mode == AuthMode.signIn) {
        await authService.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تسجيل الدخول بنجاح! مرحباً بك.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (_mode == AuthMode.signUp) {
        await authService.signUpWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء الحساب بنجاح!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (_mode == AuthMode.forgotPassword) {
        await authService.sendPasswordResetEmail(_emailController.text);
        if (mounted) {
          setState(() {
            _mode = AuthMode.signIn;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getAuthErrorMessage(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPalette = ref.watch(appPaletteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = _mode == AuthMode.signIn
        ? 'تسجيل الدخول'
        : (_mode == AuthMode.signUp ? 'إنشاء حساب جديد' : 'استعادة كلمة المرور');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Theme.of(context).cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: currentPalette.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _mode == AuthMode.signIn
                          ? Icons.lock_open_rounded
                          : (_mode == AuthMode.signUp ? Icons.person_add_rounded : Icons.lock_reset_rounded),
                      size: 32,
                      color: currentPalette.color,
                    ),
                  ),
                ),
                const Gap(12),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Gap(6),
                Text(
                  _mode == AuthMode.forgotPassword
                      ? 'أدخل بريدك الإلكتروني لإرسال رابط إعادة التعيين'
                      : 'سجل دخولك لحفظ ومزامنة قراءاتك وملاحظاتك سحابياً',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const Gap(20),

                // Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.ibmPlexSansArabic(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(14),
                ],

                // Display Name field (only on sign up)
                if (_mode == AuthMode.signUp) ...[
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'الاسم (اختياري)',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const Gap(12),
                ],

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: _mode == AuthMode.forgotPassword ? TextInputAction.done : TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                    if (!v.contains('@') || !v.contains('.')) return 'يرجى إدخال بريد إلكتروني صالح';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const Gap(12),

                // Password field (not on forgot password)
                if (_mode != AuthMode.forgotPassword) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                      if (v.length < 6) return 'كلمة المرور يجب أن لا تقل عن 6 أحرف';
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const Gap(8),

                  // Forgot Password Link
                  if (_mode == AuthMode.signIn)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _mode = AuthMode.forgotPassword;
                          _errorMessage = null;
                        }),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'نسيت كلمة المرور؟',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12,
                            color: currentPalette.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],

                const Gap(16),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentPalette.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          title,
                          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
                const Gap(12),

                // Switch Mode Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _mode == AuthMode.signIn
                          ? 'ليس لديك حساب؟'
                          : (_mode == AuthMode.signUp ? 'لديك حساب بالفعل؟' : 'تذكرت كلمة المرور؟'),
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_mode == AuthMode.signIn) {
                            _mode = AuthMode.signUp;
                          } else {
                            _mode = AuthMode.signIn;
                          }
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _mode == AuthMode.signIn
                            ? 'إنشاء حساب'
                            : 'تسجيل الدخول',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: currentPalette.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

