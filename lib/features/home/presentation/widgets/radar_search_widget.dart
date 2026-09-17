import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RadarSearchWidget extends StatefulWidget {
  const RadarSearchWidget({super.key});

  @override
  State<RadarSearchWidget> createState() => _RadarSearchWidgetState();
}

class _RadarSearchWidgetState extends State<RadarSearchWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated Pulse Beacon
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90 + (_controller.value * 30),
                    height: 90 + (_controller.value * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.onlineGreen.withValues(alpha: 0.25 * (1 - _controller.value)),
                    ),
                  ),
                  Container(
                    width: 70 + (_controller.value * 20),
                    height: 70 + (_controller.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.onlineGreen.withValues(alpha: 0.35 * (1 - _controller.value)),
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.onlineGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.onlineGreen.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          const Text(
            'أنت متصل بالشبكة وجاهز للعمل',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'جاري البحث ومطابقة أقرب الطلبات الجاهزة في منطقتك الجغرافية الحالية عبر محرك التوزيع الذكي...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
