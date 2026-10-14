import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SosButton extends StatefulWidget {
  final bool isAlertActive;
  final VoidCallback onPressed;
  final VoidCallback? onCancel;

  const SosButton({
    super.key,
    required this.isAlertActive,
    required this.onPressed,
    this.onCancel,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 190.0;
    const double outerSize = 270.0;

    final baseColor = widget.isAlertActive ? AppTheme.warningAmber : AppTheme.emergencyRed;
    final glowColor = widget.isAlertActive ? AppTheme.warningAmberGlow : AppTheme.emergencyRedGlow;

    return Center(
      child: SizedBox(
        width: outerSize,
        height: outerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Concentric Pulse Rings
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (index) {
                    final progress = (_pulseController.value + (index * 0.33)) % 1.0;
                    final size = buttonSize + (progress * (outerSize - buttonSize));
                    final opacity = (1.0 - progress).clamp(0.0, 1.0) * (widget.isAlertActive ? 0.6 : 0.4);

                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: baseColor.withValues(alpha: opacity),
                          width: 2.0 * (1.0 - progress) + 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: opacity * 0.5),
                            blurRadius: 18 * progress,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),

            // Tactile SOS Core Button
            GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                if (widget.isAlertActive) {
                  widget.onCancel?.call();
                } else {
                  widget.onPressed();
                }
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: AnimatedScale(
                scale: _isPressed ? 0.92 : (widget.isAlertActive ? 1.02 : 1.0),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.25, -0.35),
                      radius: 0.85,
                      colors: widget.isAlertActive
                          ? [
                              const Color(0xFFFBBF24),
                              const Color(0xFFD97706),
                              const Color(0xFF78350F),
                            ]
                          : [
                              const Color(0xFFFF6B6B),
                              const Color(0xFFDC2626),
                              const Color(0xFF7F1D1D),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.55),
                        blurRadius: 30,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 3.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isAlertActive
                                ? Icons.warning_amber_rounded
                                : Icons.touch_app_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isAlertActive ? "ALERT SENT" : "SOS",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.isAlertActive ? "TAP TO CANCEL" : "HOLD / TAP",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
