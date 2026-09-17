import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../orders/data/driver_order_model.dart';

enum MapFocusTarget { driver, restaurant, customer }

class DriverLiveMapWidget extends StatefulWidget {
  final DriverOrderModel? activeOrder;
  final bool isOnline;
  final MapFocusTarget initialFocus;
  final ValueChanged<MapFocusTarget>? onFocusChanged;

  const DriverLiveMapWidget({
    super.key,
    this.activeOrder,
    this.isOnline = true,
    this.initialFocus = MapFocusTarget.restaurant,
    this.onFocusChanged,
  });

  @override
  State<DriverLiveMapWidget> createState() => _DriverLiveMapWidgetState();
}

class _DriverLiveMapWidgetState extends State<DriverLiveMapWidget> with TickerProviderStateMixin {
  late MapFocusTarget _currentFocus;
  late AnimationController _pulseController;
  late AnimationController _chevronController;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _currentFocus = widget.activeOrder != null
        ? (widget.activeOrder!.status == 'on_the_way' ? MapFocusTarget.customer : widget.initialFocus)
        : MapFocusTarget.driver;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _chevronController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant DriverLiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFocus != oldWidget.initialFocus) {
      setState(() {
        _currentFocus = widget.initialFocus;
      });
    }
    if (widget.activeOrder != oldWidget.activeOrder) {
      if (widget.activeOrder != null) {
        setState(() {
          _currentFocus = widget.activeOrder!.status == 'on_the_way'
              ? MapFocusTarget.customer
              : widget.initialFocus;
        });
      } else {
        setState(() {
          _currentFocus = MapFocusTarget.driver;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _chevronController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOrder = widget.activeOrder != null;
    final size = MediaQuery.of(context).size;

    return SizedBox.expand(
      child: Stack(
        children: [
          // 1. AUTHENTIC GOOGLE MAPS VECTOR CANVAS (Roads, Water, Landmarks & Polylines)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _chevronController]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _GoogleMapsVectorPainter(
                    focus: _currentFocus,
                    hasOrder: hasOrder,
                    zoom: _zoomLevel,
                    pulseValue: _pulseController.value,
                    chevronProgress: _chevronController.value,
                  ),
                );
              },
            ),
          ),

          // 2. GOOGLE MAPS PINS & MARKERS
          if (!hasOrder) ...[
            // Idle Driver Beacon in Tripoli
            Positioned(
              top: size.height * 0.40,
              left: 0,
              right: 0,
              child: Center(
                child: _buildDriverNavigationDot(
                  label: 'موقعك (المندوب)',
                  isNavigating: false,
                ),
              ),
            ),
          ] else ...[
            // 2.A Driver's Live Navigation Cursor (Origin Point)
            Positioned(
              top: size.height * 0.42,
              left: size.width * 0.18,
              child: _buildDriverNavigationDot(
                label: 'موقعك (المندوب)',
                isNavigating: true,
              ),
            ),

            // 2.B Authentic Google Maps Destination Pin (Red/Green Pin)
            Positioned(
              top: _currentFocus == MapFocusTarget.restaurant ? size.height * 0.32 : size.height * 0.38,
              right: size.width * 0.16,
              child: _buildGoogleDestinationPin(),
            ),
          ],

          // 3. MINIMALIST GOOGLE MAPS CONTROLS (Floating Right Edge)
          Positioned(
            top: size.height * 0.30,
            left: 14,
            child: Column(
              children: [
                _buildMapControlBtn(
                  icon: Icons.explore_rounded,
                  tooltip: 'البوصلة',
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.add_rounded,
                  tooltip: 'تكبير',
                  onTap: () => setState(() => _zoomLevel = (_zoomLevel + 0.2).clamp(0.8, 2.0)),
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.remove_rounded,
                  tooltip: 'تصغير',
                  onTap: () => setState(() => _zoomLevel = (_zoomLevel - 0.2).clamp(0.8, 2.0)),
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.my_location_rounded,
                  tooltip: 'إعادة التمركز',
                  onTap: () => setState(() => _zoomLevel = 1.0),
                ),
              ],
            ),
          ),

          // 4. GOOGLE MAPS WATERMARK / LEGAL BADGE (Google Brand Look)
          Positioned(
            bottom: size.height * 0.25,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Google',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'sans-serif',
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverNavigationDot({
    required String label,
    required bool isNavigating,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Directional Heading Cone (Google Maps style)
                CustomPaint(
                  size: const Size(60, 60),
                  painter: _HeadingConePainter(pulse: _pulseController.value),
                ),

                // Blue Google GPS Dot with white border
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A73E8).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.navigation_rounded, color: Colors.white, size: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoogleDestinationPin() {
    final bool isRestaurant = _currentFocus == MapFocusTarget.restaurant;
    final String name = isRestaurant
        ? (widget.activeOrder?.restaurantName ?? 'مطعم أجنحة ليبيا')
        : (widget.activeOrder?.customerName ?? 'طارق الزنتاني');
    final Color pinColor = isRestaurant ? const Color(0xFFEA4335) : const Color(0xFF34A853);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name Chip above Pin
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: pinColor.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRestaurant ? Icons.storefront_rounded : Icons.person_pin_circle_rounded,
                color: pinColor,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                name,
                style: TextStyle(
                  color: pinColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),

        // Teardrop Google Pin
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: pinColor.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isRestaurant ? Icons.restaurant_rounded : Icons.location_on_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF475569), size: 19),
      ),
    );
  }
}

class _HeadingConePainter extends CustomPainter {
  final double pulse;
  _HeadingConePainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final conePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1A73E8).withValues(alpha: 0.35 * (1 - (pulse * 0.3))),
          const Color(0xFF1A73E8).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: size.width / 2),
        -math.pi / 2 - 0.4,
        0.8,
        false,
      )
      ..close();

    canvas.drawPath(path, conePaint);
  }

  @override
  bool shouldRepaint(covariant _HeadingConePainter oldDelegate) => oldDelegate.pulse != pulse;
}

class _GoogleMapsVectorPainter extends CustomPainter {
  final MapFocusTarget focus;
  final bool hasOrder;
  final double zoom;
  final double pulseValue;
  final double chevronProgress;

  _GoogleMapsVectorPainter({
    required this.focus,
    required this.hasOrder,
    required this.zoom,
    required this.pulseValue,
    required this.chevronProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Google Maps Base Surface Color
    final bgPaint = Paint()..color = const Color(0xFFF0F3F4);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Mediterranean Sea / Tripoli Coastline (Google Maps Soft Blue)
    final seaPaint = Paint()..color = const Color(0xFFA5DCFE);
    final seaPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.16)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.22, 0, size.height * 0.15)
      ..close();
    canvas.drawPath(seaPath, seaPaint);

    // Green Parks & Gardens (Google Maps Pale Green)
    final parkPaint = Paint()..color = const Color(0xFFD1F2D9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.06, size.height * 0.28, size.width * 0.26, size.height * 0.08),
        const Radius.circular(12),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.44, size.width * 0.32, size.height * 0.09),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    // 3. Secondary City Streets (White with subtle border)
    final secBorderPaint = Paint()
      ..color = const Color(0xFFD5D9DC)
      ..strokeWidth = 8.0 * zoom
      ..style = PaintingStyle.stroke;

    final secStreetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.5 * zoom
      ..style = PaintingStyle.stroke;

    // Grid local streets
    final street1 = Path()
      ..moveTo(0, size.height * 0.48)
      ..lineTo(size.width, size.height * 0.48);
    canvas.drawPath(street1, secBorderPaint);
    canvas.drawPath(street1, secStreetPaint);

    final street2 = Path()
      ..moveTo(size.width * 0.50, 0)
      ..lineTo(size.width * 0.50, size.height);
    canvas.drawPath(street2, secBorderPaint);
    canvas.drawPath(street2, secStreetPaint);

    // 4. Primary Google Highways (Yellow with Orange/Brown border)
    final highwayBorderPaint = Paint()
      ..color = const Color(0xFFFCD877)
      ..strokeWidth = 14.0 * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highwayPaint = Paint()
      ..color = const Color(0xFFFEEDB3)
      ..strokeWidth = 11.5 * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Coastal Highway (طريق الشط السريع)
    final coastalRoad = Path()
      ..moveTo(0, size.height * 0.24)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.30, size.width, size.height * 0.26);
    canvas.drawPath(coastalRoad, highwayBorderPaint);
    canvas.drawPath(coastalRoad, highwayPaint);

    // Middle Ring Road (الطريق الدائري الثاني)
    final midRoad = Path()
      ..moveTo(0, size.height * 0.38)
      ..lineTo(size.width * 0.45, size.height * 0.36)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.34, size.width, size.height * 0.40);
    canvas.drawPath(midRoad, highwayBorderPaint);
    canvas.drawPath(midRoad, highwayPaint);

    // Airport Highway / Main Artery (طريق المطار)
    final airportRoad = Path()
      ..moveTo(size.width * 0.28, 0)
      ..lineTo(size.width * 0.26, size.height);
    canvas.drawPath(airportRoad, highwayBorderPaint);
    canvas.drawPath(airportRoad, highwayPaint);

    // 5. Authentic Google Maps Arabic Street & Area Labels
    _drawMapText(canvas, 'طريق الشط السريع', Offset(size.width * 0.38, size.height * 0.235), 10, const Color(0xFF78909C));
    _drawMapText(canvas, 'حي الأندلس', Offset(size.width * 0.70, size.height * 0.42), 11, const Color(0xFF546E7A), isBold: true);
    _drawMapText(canvas, 'ميدان الشهداء', Offset(size.width * 0.10, size.height * 0.20), 10, const Color(0xFF78909C));
    _drawMapText(canvas, 'قرقارش', Offset(size.width * 0.12, size.height * 0.52), 10, const Color(0xFF78909C));

    // 6. GOOGLE MAPS NAVIGATION BLUE ROUTE (Shortest path)
    if (hasOrder) {
      final driverX = size.width * 0.26;
      final driverY = size.height * 0.42;

      final Path routePath = Path();
      final Path altPath = Path();

      if (focus == MapFocusTarget.restaurant) {
        final restX = size.width * 0.78;
        final restY = size.height * 0.32;

        // Primary Route
        routePath.moveTo(driverX, driverY);
        routePath.lineTo(size.width * 0.28, size.height * 0.28);
        routePath.lineTo(size.width * 0.52, size.height * 0.28);
        routePath.lineTo(restX, restY);

        // Gray Alternate
        altPath.moveTo(driverX, driverY);
        altPath.lineTo(size.width * 0.28, size.height * 0.38);
        altPath.lineTo(size.width * 0.70, size.height * 0.38);
        altPath.lineTo(restX, restY);
      } else {
        final custX = size.width * 0.78;
        final custY = size.height * 0.38;

        // Primary Route
        routePath.moveTo(driverX, driverY);
        routePath.lineTo(size.width * 0.28, size.height * 0.36);
        routePath.lineTo(size.width * 0.56, size.height * 0.36);
        routePath.lineTo(custX, custY);

        // Gray Alternate
        altPath.moveTo(driverX, driverY);
        altPath.lineTo(size.width * 0.28, size.height * 0.26);
        altPath.lineTo(size.width * 0.70, size.height * 0.26);
        altPath.lineTo(custX, custY);
      }

      // 6.A Draw Alternate Route (Gray)
      final altPaint = Paint()
        ..color = const Color(0xFF94A3B8).withValues(alpha: 0.45)
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(altPath, altPaint);

      // 6.B Draw Google Blue Primary Route (Dark Blue Border + Cyan/Blue Core)
      final routeBorderPaint = Paint()
        ..color = const Color(0xFF1557B0)
        ..strokeWidth = 9.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final routeCorePaint = Paint()
        ..color = const Color(0xFF1A73E8)
        ..strokeWidth = 7.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(routePath, routeBorderPaint);
      canvas.drawPath(routePath, routeCorePaint);
    }
  }

  void _drawMapText(Canvas canvas, String text, Offset offset, double fontSize, Color color, {bool isBold = false}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontFamily: 'Cairo',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.rtl,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _GoogleMapsVectorPainter oldDelegate) {
    return oldDelegate.focus != focus ||
        oldDelegate.hasOrder != hasOrder ||
        oldDelegate.zoom != zoom ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.chevronProgress != chevronProgress;
  }
}
