import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'modern_button.dart';

class CongratulationsPopup extends StatefulWidget {
  final String? habitName;
  final String? customMessage;
  final IconData? habitIcon;
  final Color? habitColor;
  final VoidCallback? onAwesomePressed;

  const CongratulationsPopup({
    super.key,
    this.habitName,
    this.customMessage,
    this.habitIcon,
    this.habitColor,
    this.onAwesomePressed,
  });

  @override
  State<CongratulationsPopup> createState() => _CongratulationsPopupState();
}

class _CongratulationsPopupState extends State<CongratulationsPopup>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _textFadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.3, 1, curve: Curves.easeIn),
    );

    // Start animations
    _confettiController.play();
    _scaleController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Background overlay
        Container(
          color: Colors.black.withAlpha((0.7 * 255).round()),
          child: Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: theme.colorScheme.outline
                          .withAlpha((0.2 * 255).round()),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Habit icon spotlight with colorful paper show
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            const _ColorfulPaperShow(),
                            _HabitIconBadge(
                              icon: widget.habitIcon,
                              fallbackIcon: Icons.emoji_events,
                              color: widget.habitColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Column(
                          children: [
                            if (widget.habitName != null) ...[
                              Text(
                                '"${widget.habitName!}"',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              widget.customMessage ??
                                  'You completed all your habits for today! 🎉',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withAlpha((0.85 * 255).round()),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Close button
                      ModernButton(
                        text: 'Awesome! 🎉',
                        type: ModernButtonType.primary,
                        size: ModernButtonSize.large,
                        fullWidth: true,
                        onPressed: () {
                          widget.onAwesomePressed?.call();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 1.5708, // radians for downward
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.05,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Color(0xFF9B5DE5),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitIconBadge extends StatelessWidget {
  final IconData? icon;
  final IconData fallbackIcon;
  final Color? color;

  const _HabitIconBadge({
    required this.icon,
    required this.fallbackIcon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Colors.orange;

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withAlpha((0.65 * 255).round()),
            baseColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: baseColor.withAlpha((0.35 * 255).round()),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        icon ?? fallbackIcon,
        color: Colors.white,
        size: 40,
      ),
    );
  }
}

class _ColorfulPaperShow extends StatelessWidget {
  const _ColorfulPaperShow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              _PaperPiece(
                angle: -0.2,
                offset: const Offset(-50, -10),
                colors: const [Color(0xFFFF6CAB), Color(0xFFFFD86F)],
                size: const Size(28, 12),
                center: center,
              ),
              _PaperPiece(
                angle: 0.35,
                offset: const Offset(40, -25),
                colors: const [Color(0xFF6FC8FF), Color(0xFF4A7BFF)],
                size: const Size(26, 14),
                center: center,
              ),
              _PaperPiece(
                angle: -0.6,
                offset: const Offset(-35, 45),
                colors: const [Color(0xFF7BFFB8), Color(0xFF00D2FF)],
                size: const Size(20, 10),
                center: center,
              ),
              _PaperPiece(
                angle: 0.9,
                offset: const Offset(35, 55),
                colors: const [Color(0xFFFFA36F), Color(0xFFFF5F6D)],
                size: const Size(18, 9),
                center: center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaperPiece extends StatelessWidget {
  final double angle;
  final Offset offset;
  final List<Color> colors;
  final Size size;
  final Offset center;

  const _PaperPiece({
    required this.angle,
    required this.offset,
    required this.colors,
    required this.size,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx + offset.dx,
      top: center.dy + offset.dy,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.last.withOpacity(0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
