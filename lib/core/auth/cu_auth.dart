// cu_auth.dart — CombatUniverse: вход, регистрация, восстановление пароля,
// профиль (редактирование) и настройки. Зависимости: только flutter.

import 'dart:async';
import 'package:flutter/material.dart';

// ───────────────────────── Цвета ─────────────────────────
const _red = Color(0xFFE5202E);
const _bg = Color(0xFF0E0E10);
const _card = Color(0xFF1A1A1E);
const _muted = Color(0xFF9A9AA3);

// ───────────────────────── Модель ─────────────────────────
class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.handle,
    this.bio = '',
    this.following = 0,
    this.followers = 0,
    this.likes = 0,
    this.views = 0,
  });
  final String id;
  String email;
  String name;
  String handle;
  String bio;
  int following, followers, likes, views;
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

// ───────────────────────── Сервис (заменяемый) ─────────────────────────
abstract class AuthService {
  Future<AppUser> signIn(String email, String password);
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String handle,
  });
  Future<void> sendResetEmail(String email);
  Future<AppUser> updateProfile(String name, String handle, String bio);
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<void> deleteAccount();
  Future<void> signOut();
}

class _Rec {
  _Rec(this.password, this.user);
  String password;
  AppUser user;
}

/// Локальная заглушка для разработки (данные живут до перезапуска).
class MockAuthService implements AuthService {
  final Map<String, _Rec> _db = {};
  _Rec? _cur;

  Future<void> _lag() => Future.delayed(const Duration(milliseconds: 600));

  @override
  Future<AppUser> signIn(String email, String password) async {
    await _lag();
    final r = _db[email.trim().toLowerCase()];
    if (r == null || r.password != password) {
      throw AuthException('Неверная почта или пароль');
    }
    _cur = r;
    return r.user;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String handle,
  }) async {
    await _lag();
    final key = email.trim().toLowerCase();
    if (_db.containsKey(key)) {
      throw AuthException('Эта почта уже зарегистрирована');
    }
    if (_db.values.any((r) => r.user.handle == handle)) {
      throw AuthException('Этот @ник уже занят');
    }
    final u = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      email: key,
      name: name.trim(),
      handle: handle,
    );
    _cur = _Rec(password, u);
    _db[key] = _cur!;
    return u;
  }

  @override
  Future<void> sendResetEmail(String email) async {
    await _lag(); // не раскрываем, есть ли такая почта
  }

  @override
  Future<AppUser> updateProfile(String name, String handle, String bio) async {
    await _lag();
    final me = _cur!;
    if (_db.values.any((r) => r != me && r.user.handle == handle)) {
      throw AuthException('Этот @ник уже занят');
    }
    me.user
      ..name = name.trim()
      ..handle = handle
      ..bio = bio.trim();
    return me.user;
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _lag();
    if (_cur!.password != oldPassword) {
      throw AuthException('Текущий пароль указан неверно');
    }
    _cur!.password = newPassword;
  }

  @override
  Future<void> deleteAccount() async {
    await _lag();
    _db.removeWhere((_, r) => r == _cur);
    _cur = null;
  }

  @override
  Future<void> signOut() async {
    _cur = null;
  }
}

// ───────────────────────── Контроллеры ─────────────────────────
class AuthController extends ChangeNotifier {
  AuthController(this._service);
  final AuthService _service;

  AppUser? user;
  bool guest = false;
  bool busy = false;

  bool get signedIn => user != null;

  /// Возвращает null при успехе или текст ошибки.
  Future<String?> _run(Future<void> Function() job) async {
    busy = true;
    notifyListeners();
    try {
      await job();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Что-то пошло не так. Попробуйте ещё раз';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) => _run(() async {
        user = await _service.signIn(email, password);
        guest = false;
      });

  Future<String?> signUp(
          String email, String password, String name, String handle) =>
      _run(() async {
        user = await _service.signUp(
            email: email, password: password, name: name, handle: handle);
        guest = false;
      });

  Future<String?> sendReset(String email) =>
      _run(() => _service.sendResetEmail(email));

  Future<String?> updateProfile(String name, String handle, String bio) =>
      _run(() async => user = await _service.updateProfile(name, handle, bio));

  Future<String?> changePassword(String oldP, String newP) =>
      _run(() => _service.changePassword(oldP, newP));

  Future<String?> deleteAccount() => _run(() async {
        await _service.deleteAccount();
        user = null;
      });

  Future<void> signOut() async {
    await _service.signOut();
    user = null;
    guest = false;
    notifyListeners();
  }

  void continueAsGuest() {
    guest = true;
    notifyListeners();
  }
}

class AppSettings extends ChangeNotifier {
  String language = 'ru';
  bool notifications = true;

  static const languages = <String, String>{
    'ru': 'Русский',
    'en': 'English',
    'az': 'Azərbaycanca',
    'tr': 'Türkçe',
    'es': 'Español',
    'de': 'Deutsch',
  };

  void setLanguage(String code) {
    language = code;
    notifyListeners();
  }

  void setNotifications(bool v) {
    notifications = v;
    notifyListeners();
  }
}

final auth = AuthController(MockAuthService());
final appSettings = AppSettings();

// ───────────────────────── Валидаторы ─────────────────────────
class V {
  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Введите почту';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
      return 'Некорректная почта';
    }
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Введите пароль';
    if (s.length < 8) return 'Минимум 8 символов';
    if (!RegExp(r'[A-Za-zА-Яа-я]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'Нужны буквы и цифры';
    }
    return null;
  }

  static String? name(String? v) {
    final s = (v ?? '').trim();
    if (s.length < 2) return 'Минимум 2 символа';
    return null;
  }

  static String? handle(String? v) {
    final s = v ?? '';
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(s)) {
      return '3–20 символов: латиница, цифры, _';
    }
    return null;
  }
}

// ───────────────────────── Общие виджеты ─────────────────────────
void _toast(BuildContext c, String msg) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<bool> _confirm(BuildContext c, String title, String text,
    {String action = 'Да', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (_) => AlertDialog(
      backgroundColor: _card,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(text, style: const TextStyle(color: _muted)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Отмена')),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(action, style: TextStyle(color: danger ? _red : null)),
        ),
      ],
    ),
  );
  return r ?? false;
}

class _Field extends StatefulWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.icon,
    this.password = false,
    this.validator,
    this.keyboard,
    this.maxLines = 1,
    this.maxLength,
    this.action = TextInputAction.next,
    this.prefixText,
  });
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool password;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final int maxLines;
  final int? maxLength;
  final TextInputAction action;
  final String? prefixText;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.password && _hide,
        keyboardType: widget.keyboard,
        textInputAction: widget.action,
        maxLines: widget.password ? 1 : widget.maxLines,
        maxLength: widget.maxLength,
        validator: widget.validator,
        style: const TextStyle(color: Colors.white),
        cursorColor: _red,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixText: widget.prefixText,
          prefixStyle: const TextStyle(color: _muted),
          labelStyle: const TextStyle(color: _muted),
          prefixIcon:
              widget.icon == null ? null : Icon(widget.icon, color: _muted),
          suffixIcon: widget.password
              ? IconButton(
                  icon: Icon(_hide ? Icons.visibility_off : Icons.visibility,
                      color: _muted),
                  onPressed: () => setState(() => _hide = !_hide),
                )
              : null,
          filled: true,
          fillColor: _card,
          counterText: '',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _red, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _red)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _red, width: 1.5)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.label, required this.onPressed, this.busy = false});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _red,
          disabledBackgroundColor: _red.withOpacity(0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold(
      {required this.title,
      required this.subtitle,
      required this.child,
      this.showBack = false});
  final String title, subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: showBack
          ? AppBar(backgroundColor: _bg, elevation: 0, foregroundColor: Colors.white)
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text.rich(TextSpan(children: [
                    TextSpan(
                        text: 'COMBAT ',
                        style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'UNIVERSE', style: TextStyle(color: _red)),
                  ]),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1)),
                  const SizedBox(height: 28),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: const TextStyle(color: _muted, fontSize: 15)),
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _backToRoot(BuildContext c) =>
    Navigator.of(c).popUntil((r) => r.isFirst);

// ───────────────────────── AuthGate ─────────────────────────
/// Показывает экран входа, пока пользователь не вошёл (или не выбрал «гость»).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (_, __) =>
          (auth.signedIn || auth.guest) ? child : const LoginScreen(),
    );
  }
}

// ───────────────────────── Вход ─────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final err = await auth.signIn(_email.text, _pass.text);
    if (!mounted) return;
    if (err != null) {
      _toast(context, err);
    } else {
      _backToRoot(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (_, __) => _AuthScaffold(
        showBack: Navigator.of(context).canPop(),
        title: 'С возвращением',
        subtitle: 'Войдите, чтобы сохранять комбо и сборки',
        child: Form(
          key: _form,
          child: Column(
            children: [
              _Field(
                  controller: _email,
                  label: 'Почта',
                  icon: Icons.mail_outline,
                  keyboard: TextInputType.emailAddress,
                  validator: V.email),
              _Field(
                  controller: _pass,
                  label: 'Пароль',
                  icon: Icons.lock_outline,
                  password: true,
                  action: TextInputAction.done,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Введите пароль' : null),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(
                              initialEmail: _email.text))),
                  child: const Text('Забыли пароль?',
                      style: TextStyle(color: _red)),
                ),
              ),
              const SizedBox(height: 6),
              _PrimaryButton(
                  label: 'Войти', busy: auth.busy, onPressed: _submit),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Нет аккаунта?', style: TextStyle(color: _muted)),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Регистрация',
                        style: TextStyle(color: _red)),
                  ),
                ],
              ),
              if (!Navigator.of(context).canPop())
                TextButton(
                  onPressed: auth.continueAsGuest,
                  child: const Text('Продолжить как гость',
                      style: TextStyle(color: _muted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Регистрация ─────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _agree = false;

  @override
  void dispose() {
    for (final c in [_name, _handle, _email, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      _toast(context, 'Примите условия использования');
      return;
    }
    final err = await auth.signUp(
        _email.text, _pass.text, _name.text, _handle.text.trim());
    if (!mounted) return;
    if (err != null) {
      _toast(context, err);
    } else {
      _backToRoot(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (_, __) => _AuthScaffold(
        showBack: true,
        title: 'Создать аккаунт',
        subtitle: 'Публикуйте комбо и делитесь сборками',
        child: Form(
          key: _form,
          child: Column(
            children: [
              _Field(
                  controller: _name,
                  label: 'Имя',
                  icon: Icons.person_outline,
                  maxLength: 30,
                  validator: V.name),
              _Field(
                  controller: _handle,
                  label: 'Ник',
                  prefixText: '@',
                  icon: Icons.alternate_email,
                  maxLength: 20,
                  validator: V.handle),
              _Field(
                  controller: _email,
                  label: 'Почта',
                  icon: Icons.mail_outline,
                  keyboard: TextInputType.emailAddress,
                  validator: V.email),
              _Field(
                  controller: _pass,
                  label: 'Пароль',
                  icon: Icons.lock_outline,
                  password: true,
                  validator: V.password),
              _Field(
                  controller: _pass2,
                  label: 'Повторите пароль',
                  icon: Icons.lock_outline,
                  password: true,
                  action: TextInputAction.done,
                  validator: (v) =>
                      v != _pass.text ? 'Пароли не совпадают' : null),
              CheckboxListTile(
                value: _agree,
                onChanged: (v) => setState(() => _agree = v ?? false),
                activeColor: _red,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                    'Я принимаю условия использования и политику конфиденциальности',
                    style: TextStyle(color: _muted, fontSize: 13)),
              ),
              const SizedBox(height: 8),
              _PrimaryButton(
                  label: 'Зарегистрироваться',
                  busy: auth.busy,
                  onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Забыли пароль ─────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final err = await auth.sendReset(_email.text);
    if (!mounted) return;
    if (err != null) {
      _toast(context, err);
    } else {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (_, __) => _AuthScaffold(
        showBack: true,
        title: 'Восстановление пароля',
        subtitle: _sent
            ? 'Если аккаунт с такой почтой существует, мы отправили на неё ссылку для сброса пароля'
            : 'Укажите почту — отправим ссылку для сброса пароля',
        child: _sent
            ? Column(children: [
                const Icon(Icons.mark_email_read_outlined,
                    color: _red, size: 64),
                const SizedBox(height: 20),
                _PrimaryButton(
                    label: 'Вернуться ко входу',
                    onPressed: () => Navigator.pop(context)),
                TextButton(
                  onPressed: auth.busy ? null : _submit,
                  child: const Text('Отправить ещё раз',
                      style: TextStyle(color: _red)),
                ),
              ])
            : Form(
                key: _form,
                child: Column(children: [
                  _Field(
                      controller: _email,
                      label: 'Почта',
                      icon: Icons.mail_outline,
                      keyboard: TextInputType.emailAddress,
                      action: TextInputAction.done,
                      validator: V.email),
                  _PrimaryButton(
                      label: 'Отправить ссылку',
                      busy: auth.busy,
                      onPressed: _submit),
                ]),
              ),
      ),
    );
  }
}

// ───────────────────────── Профиль ─────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onMyContent, this.onPremium});
  final VoidCallback? onMyContent;
  final VoidCallback? onPremium;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (_, __) {
        final u = auth.user;
        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: u == null ? _guest(context) : _profile(context, u),
          ),
        );
      },
    );
  }

  Widget _guest(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined,
                  color: _muted, size: 88),
              const SizedBox(height: 16),
              const Text('Вы не вошли в аккаунт',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Войдите, чтобы публиковать комбо и сохранять сборки',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted)),
              const SizedBox(height: 22),
              _PrimaryButton(
                  label: 'Войти',
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()))),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Создать аккаунт',
                    style: TextStyle(color: _red)),
              ),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AuthSettingsScreen())),
                child:
                    const Text('Настройки', style: TextStyle(color: _muted)),
              ),
            ],
          ),
        ),
      );

  Widget _profile(BuildContext context, AppUser u) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: _red,
            child: Text(
              u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(u.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
        ),
        Center(
            child: Text('@${u.handle}',
                style: const TextStyle(color: _muted, fontSize: 15))),
        const SizedBox(height: 10),
        Center(
          child: Text(
            u.bio.isEmpty ? 'Расскажите о себе в настройках профиля' : u.bio,
            textAlign: TextAlign.center,
            style: TextStyle(color: u.bio.isEmpty ? _muted : Colors.white70),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: _muted),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Редактировать профиль'),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Stat('${u.following}', 'Подписки'),
            _Stat('${u.followers}', 'Подписчики'),
            _Stat('${u.likes}', 'Лайки'),
            _Stat('${u.views}', 'Просмотры'),
          ],
        ),
        const SizedBox(height: 22),
        _Section(children: [
          _Tile(
              icon: Icons.layers_outlined,
              title: 'Мои сборки и комбо',
              onTap: onMyContent),
          _Tile(
              icon: Icons.star,
              iconColor: Colors.orange,
              title: 'CombatUniverse Premium',
              onTap: onPremium),
          _Tile(
              icon: Icons.settings_outlined,
              title: 'Настройки',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AuthSettingsScreen()))),
        ]),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
      ]);
}

class _Section extends StatelessWidget {
  const _Section({required this.children, this.title});
  final List<Widget> children;
  final String? title;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 16, 0, 8),
              child: Text(title!.toUpperCase(),
                  style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ),
          Container(
            decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(16)),
            child: Column(children: children),
          ),
        ],
      );
}

class _Tile extends StatelessWidget {
  const _Tile(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.trailing,
      this.onTap,
      this.iconColor,
      this.danger = false});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool danger;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon, color: danger ? _red : (iconColor ?? Colors.white70)),
        title: Text(title,
            style: TextStyle(color: danger ? _red : Colors.white)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: const TextStyle(color: _muted)),
        trailing: trailing ??
            (onTap == null
                ? null
                : const Icon(Icons.chevron_right, color: _muted)),
      );
}

// ───────────────────────── Редактирование профиля ─────────────────────────
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: auth.user?.name);
  late final _handle = TextEditingController(text: auth.user?.handle);
  late final _bio = TextEditingController(text: auth.user?.bio);

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final err =
        await auth.updateProfile(_name.text, _handle.text.trim(), _bio.text);
    if (!mounted) return;
    if (err != null) {
      _toast(context, err);
    } else {
      _toast(context, 'Профиль обновлён');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (_, __) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
            backgroundColor: _bg,
            foregroundColor: Colors.white,
            title: const Text('Редактировать профиль')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(children: [
                const SizedBox(height: 8),
                _Field(
                    controller: _name,
                    label: 'Имя',
                    icon: Icons.person_outline,
                    maxLength: 30,
                    validator: V.name),
                _Field(
                    controller: _handle,
                    label: 'Ник',
                    prefixText: '@',
                    icon: Icons.alternate_email,
                    maxLength: 20,
                    validator: V.handle),
                _Field(
                    controller: _bio,
                    label: 'О себе',
                    icon: Icons.notes,
                    maxLines: 4,
                    maxLength: 160,
                    keyboard: TextInputType.multiline,
                    action: TextInputAction.newline),
                const SizedBox(height: 6),
                _PrimaryButton(
                    label: 'Сохранить', busy: auth.busy, onPressed: _save),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Смена пароля ─────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _new2 = TextEditingController();

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _new2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final err = await auth.changePassword(_old.text, _new.text);
    if (!mounted) return;
    if (err != null) {
      _toast(context, err);
    } else {
      _toast(context, 'Пароль изменён');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (_, __) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
            backgroundColor: _bg,
            foregroundColor: Colors.white,
            title: const Text('Смена пароля')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(children: [
                _Field(
                    controller: _old,
                    label: 'Текущий пароль',
                    icon: Icons.lock_outline,
                    password: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Введите пароль' : null),
                _Field(
                    controller: _new,
                    label: 'Новый пароль',
                    icon: Icons.lock_reset,
                    password: true,
                    validator: V.password),
                _Field(
                    controller: _new2,
                    label: 'Повторите новый пароль',
                    icon: Icons.lock_reset,
                    password: true,
                    action: TextInputAction.done,
                    validator: (v) =>
                        v != _new.text ? 'Пароли не совпадают' : null),
                const SizedBox(height: 6),
                _PrimaryButton(
                    label: 'Изменить пароль',
                    busy: auth.busy,
                    onPressed: _save),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Настройки ─────────────────────────
class AuthSettingsScreen extends StatelessWidget {
  const AuthSettingsScreen({super.key, this.onChangeDevice});

  /// Открыть экран выбора устройства (PlayStation/Xbox/…)
  final VoidCallback? onChangeDevice;

  Future<void> _pickLanguage(BuildContext context) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _card,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in AppSettings.languages.entries)
              ListTile(
                title: Text(e.value, style: const TextStyle(color: Colors.white)),
                trailing: e.key == appSettings.language
                    ? const Icon(Icons.check, color: _red)
                    : null,
                onTap: () => Navigator.pop(context, e.key),
              ),
          ],
        ),
      ),
    );
    if (code != null) appSettings.setLanguage(code);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([auth, appSettings]),
      builder: (context, _) {
        final signedIn = auth.signedIn;
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
              backgroundColor: _bg,
              foregroundColor: Colors.white,
              title: const Text('Настройки')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (signedIn)
                  _Section(title: 'Аккаунт', children: [
                    _Tile(
                        icon: Icons.person_outline,
                        title: 'Редактировать профиль',
                        subtitle: '@${auth.user!.handle}',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen()))),
                    _Tile(
                        icon: Icons.mail_outline,
                        title: 'Почта',
                        subtitle: auth.user!.email),
                    _Tile(
                        icon: Icons.lock_outline,
                        title: 'Сменить пароль',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen()))),
                  ])
                else
                  _Section(title: 'Аккаунт', children: [
                    _Tile(
                        icon: Icons.login,
                        title: 'Войти или зарегистрироваться',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()))),
                  ]),
                _Section(title: 'Приложение', children: [
                  _Tile(
                      icon: Icons.language,
                      title: 'Язык',
                      subtitle:
                          AppSettings.languages[appSettings.language] ?? '',
                      onTap: () => _pickLanguage(context)),
                  _Tile(
                      icon: Icons.sports_esports_outlined,
                      title: 'Устройство для кнопок',
                      subtitle: 'PlayStation, Xbox, Switch, клавиатура…',
                      onTap: onChangeDevice),
                  SwitchListTile(
                    secondary:
                        const Icon(Icons.notifications_none, color: Colors.white70),
                    title: const Text('Уведомления',
                        style: TextStyle(color: Colors.white)),
                    value: appSettings.notifications,
                    activeColor: _red,
                    onChanged: appSettings.setNotifications,
                  ),
                ]),
                _Section(title: 'О приложении', children: [
                  _Tile(
                      icon: Icons.description_outlined,
                      title: 'Условия использования',
                      onTap: () => _toast(context, 'Скоро')),
                  _Tile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Политика конфиденциальности',
                      onTap: () => _toast(context, 'Скоро')),
                  const _Tile(
                      icon: Icons.info_outline,
                      title: 'Версия',
                      subtitle: '1.0.0'),
                ]),
                if (signedIn)
                  _Section(title: 'Опасная зона', children: [
                    _Tile(
                        icon: Icons.logout,
                        title: 'Выйти',
                        onTap: () async {
                          final ok = await _confirm(context, 'Выйти?',
                              'Вы сможете войти снова в любой момент.',
                              action: 'Выйти');
                          if (!ok) return;
                          await auth.signOut();
                          if (context.mounted) _backToRoot(context);
                        }),
                    _Tile(
                        icon: Icons.delete_outline,
                        title: 'Удалить аккаунт',
                        danger: true,
                        onTap: () async {
                          final ok = await _confirm(
                              context,
                              'Удалить аккаунт?',
                              'Профиль, комбо и сборки будут удалены без возможности восстановления.',
                              action: 'Удалить',
                              danger: true);
                          if (!ok) return;
                          final err = await auth.deleteAccount();
                          if (!context.mounted) return;
                          if (err != null) {
                            _toast(context, err);
                          } else {
                            _backToRoot(context);
                          }
                        }),
                  ]),
              ],
            ),
          ),
        );
      },
    );
  }
}
