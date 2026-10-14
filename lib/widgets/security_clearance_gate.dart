import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SecurityClearanceGate extends StatefulWidget {
  final String roleTitle;
  final String requiredScope;
  final String defaultPin;
  final String roleBadge;
  final Function(String pin) onAuthenticate;

  const SecurityClearanceGate({
    super.key,
    required this.roleTitle,
    required this.requiredScope,
    required this.defaultPin,
    required this.roleBadge,
    required this.onAuthenticate,
  });

  @override
  State<SecurityClearanceGate> createState() => _SecurityClearanceGateState();
}

class _SecurityClearanceGateState extends State<SecurityClearanceGate> {
  final TextEditingController _pinController = TextEditingController();
  bool _hasError = false;

  void _submit(String pin) {
    final success = widget.onAuthenticate(pin);
    if (!success) {
      setState(() {
        _hasError = true;
      });
      _pinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.emergencyRedDark,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Access Denied: Invalid Security Clearance PIN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _hasError ? AppTheme.emergencyRed : AppTheme.borderLight,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_hasError ? AppTheme.emergencyRed : AppTheme.infoCyan)
                      .withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Shield Lock Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _hasError
                            ? [const Color(0xFFFF334B), const Color(0xFF991B1B)]
                            : [
                                const Color(0xFF0284C7),
                                const Color(0xFF1E3A8A),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_hasError
                                      ? AppTheme.emergencyRed
                                      : AppTheme.infoCyan)
                                  .withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Gate Title & Scope
                Text(
                  widget.roleTitle.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      'Serverpod Scope: ${widget.requiredScope}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: AppTheme.infoCyanLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Access to this operational terminal is restricted to authorized campus safety and command personnel. All authentication attempts are encrypted and audited.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // PIN Input Field
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 12,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••',
                    hintStyle: const TextStyle(
                      color: AppTheme.textMuted,
                      letterSpacing: 8,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0B1120),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.infoCyan,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (val) => _submit(val),
                ),
                const SizedBox(height: 16),

                // Unlock Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.infoCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _submit(_pinController.text),
                  icon: const Icon(Icons.key_rounded, size: 18),
                  label: const Text(
                    'Authenticate Terminal Session',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 16),

                const Divider(color: AppTheme.border),
                const SizedBox(height: 12),

                // Quick Demo 1-Tap Judge Bypass
                InkWell(
                  onTap: () {
                    _pinController.text = widget.defaultPin;
                    _submit(widget.defaultPin);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.warningAmber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: AppTheme.warningAmberLight,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '⚡ 1-Tap Demo Clearance (PIN: ${widget.defaultPin})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.warningAmberLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
