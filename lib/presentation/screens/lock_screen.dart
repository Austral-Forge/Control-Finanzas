import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/context_theme_x.dart';
import '../../data/services/app_lock_service.dart';
import 'home_screen.dart';

/// Pantalla de desbloqueo con PIN al abrir la app. Tras 3 intentos fallidos
/// aplica una espera de 30 segundos para frenar intentos por fuerza bruta.
class LockScreen extends StatefulWidget {
  final AppLockService lockService;

  const LockScreen({super.key, required this.lockService});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  static const int _maxAttempts = 3;
  static const int _cooldownSeconds = 30;

  String _entered = '';
  int _failedAttempts = 0;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;
  bool _error = false;

  bool get _isLockedOut => _cooldownRemaining > 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _onDigit(String digit) async {
    if (_isLockedOut || _entered.length >= AppLockService.pinLength) return;
    setState(() {
      _error = false;
      _entered += digit;
    });
    if (_entered.length == AppLockService.pinLength) {
      final ok = await widget.lockService.verifyPin(_entered);
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _failedAttempts++;
        setState(() {
          _entered = '';
          _error = true;
        });
        if (_failedAttempts >= _maxAttempts) {
          _startCooldown();
        }
      }
    }
  }

  void _startCooldown() {
    setState(() => _cooldownRemaining = _cooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _cooldownRemaining--;
        if (_cooldownRemaining <= 0) {
          _failedAttempts = 0;
          timer.cancel();
        }
      });
    });
  }

  void _onBackspace() {
    if (_entered.isEmpty || _isLockedOut) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: AppTheme.primary, size: 48),
            ),
            const SizedBox(height: 20),
            Text('Ingresa tu PIN', style: context.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              _isLockedOut
                  ? 'Demasiados intentos. Espera $_cooldownRemaining s'
                  : _error
                      ? 'PIN incorrecto, intenta de nuevo'
                      : 'Tus finanzas estan protegidas',
              style: TextStyle(
                fontSize: 13,
                color: _isLockedOut || _error
                    ? AppTheme.cost
                    : context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildPinDots(),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(AppLockService.pinLength, (i) {
        final filled = i < _entered.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppTheme.primary : Colors.transparent,
            border: Border.all(
              color: _error ? AppTheme.cost : AppTheme.primary,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '<'],
    ];
    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 88, height: 72);
            }
            final isBackspace = key == '<';
            return SizedBox(
              width: 88,
              height: 72,
              child: TextButton(
                onPressed: _isLockedOut
                    ? null
                    : isBackspace
                        ? _onBackspace
                        : () => _onDigit(key),
                child: isBackspace
                    ? Icon(Icons.backspace_outlined,
                        size: 24, color: context.secondaryTextColor)
                    : Text(key,
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: context.primaryTextColor)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
