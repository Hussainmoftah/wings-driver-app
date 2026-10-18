import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../orders/data/driver_order_model.dart';
import 'package:sadeem_ui/sadeem_ui.dart';

enum MapFocusTarget { driver, restaurant, customer }

/// وسط طرابلس — يُستخدم عندما لا تتوفر إحداثيات فعلية بعد.
const LatLng kTripoliCenter = LatLng(32.8872, 13.1913);

/// خريطة حيّة للمندوب مبنية على OpenStreetMap عبر حزمة flutter_map.
///
/// الإحداثيات تأتي من الطلب النشط (المطعم والزبون) ومن الموقع اللحظي
/// للمندوب، ولا تُرسم أي عناصر وهمية.
class DriverLiveMapWidget extends StatefulWidget {
  final DriverOrderModel? activeOrder;
  final bool isOnline;
  final MapFocusTarget initialFocus;
  final ValueChanged<MapFocusTarget>? onFocusChanged;

  /// الموقع اللحظي للمندوب؛ يسقط إلى وسط طرابلس عند غيابه.
  final double? driverLat;
  final double? driverLng;

  const DriverLiveMapWidget({
    super.key,
    this.activeOrder,
    this.isOnline = true,
    this.initialFocus = MapFocusTarget.restaurant,
    this.onFocusChanged,
    this.driverLat,
    this.driverLng,
  });

  @override
  State<DriverLiveMapWidget> createState() => _DriverLiveMapWidgetState();
}

class _DriverLiveMapWidgetState extends State<DriverLiveMapWidget>
    with TickerProviderStateMixin {
  static const double _defaultZoom = 14.5;

  final MapController _mapController = MapController();
  late MapFocusTarget _currentFocus;
  late AnimationController _pulseController;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _currentFocus = widget.activeOrder != null
        ? (widget.activeOrder!.status == 'on_the_way'
              ? MapFocusTarget.customer
              : widget.initialFocus)
        : MapFocusTarget.driver;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant DriverLiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // تابع موقع المندوب أثناء التوصيل دون أن تفقد تركيز المستخدم اليدوي.
    if (_mapReady &&
        _currentFocus == MapFocusTarget.driver &&
        (oldWidget.driverLat != widget.driverLat ||
            oldWidget.driverLng != widget.driverLng)) {
      _mapController.move(_driverPoint, _mapController.camera.zoom);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _driverPoint =>
      widget.driverLat != null && widget.driverLng != null
      ? LatLng(widget.driverLat!, widget.driverLng!)
      : kTripoliCenter;

  LatLng? get _restaurantPoint {
    final o = widget.activeOrder;
    if (o?.restaurantLat == null || o?.restaurantLng == null) return null;
    return LatLng(o!.restaurantLat!, o.restaurantLng!);
  }

  LatLng? get _customerPoint {
    final o = widget.activeOrder;
    if (o?.customerLat == null || o?.customerLng == null) return null;
    return LatLng(o!.customerLat!, o.customerLng!);
  }

  LatLng _pointFor(MapFocusTarget target) => switch (target) {
    MapFocusTarget.driver => _driverPoint,
    MapFocusTarget.restaurant => _restaurantPoint ?? _driverPoint,
    MapFocusTarget.customer => _customerPoint ?? _driverPoint,
  };

  void _focusOn(MapFocusTarget target) {
    setState(() => _currentFocus = target);
    _mapController.move(_pointFor(target), _mapController.camera.zoom);
    widget.onFocusChanged?.call(target);
  }

  /// يضبط الإطار ليشمل كل النقاط المتاحة (المندوب والمطعم والزبون).
  void _fitAllPoints() {
    final points = <LatLng>[_driverPoint, ?_restaurantPoint, ?_customerPoint];
    if (points.length < 2) {
      _mapController.move(_driverPoint, _defaultZoom);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(64),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = _restaurantPoint;
    final customer = _customerPoint;

    // أثناء التوصيل يكون المسار من المندوب إلى الزبون، وقبله إلى المطعم.
    final bool headingToCustomer = widget.activeOrder?.status == 'on_the_way';
    final LatLng? routeEnd = headingToCustomer ? customer : restaurant;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _pointFor(_currentFocus),
            initialZoom: _defaultZoom,
            minZoom: 4,
            maxZoom: 18,
            onMapReady: () {
              _mapReady = true;
              if (widget.activeOrder != null) _fitAllPoints();
            },
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ly.wings.driver',
              maxNativeZoom: 19,
            ),
            if (routeEnd != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_driverPoint, routeEnd],
                    strokeWidth: 4,
                    color: SColors.brand.withValues(alpha: 0.75),
                    borderStrokeWidth: 1,
                    borderColor: Colors.white,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (restaurant != null)
                  Marker(
                    point: restaurant,
                    width: 160,
                    height: 76,
                    alignment: Alignment.bottomCenter,
                    child: _DestinationPin(
                      label: widget.activeOrder?.restaurantName ?? 'المطعم',
                      color: SColors.googleRed,
                      icon: Icons.storefront_rounded,
                    ),
                  ),
                if (customer != null)
                  Marker(
                    point: customer,
                    width: 160,
                    height: 76,
                    alignment: Alignment.bottomCenter,
                    child: _DestinationPin(
                      label: widget.activeOrder?.customerName ?? 'الزبون',
                      color: const Color(0xFF34A853),
                      icon: Icons.person_pin_circle_rounded,
                    ),
                  ),
                Marker(
                  point: _driverPoint,
                  width: 120,
                  height: 120,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) => _DriverBeacon(
                      pulse: _pulseController.value,
                      isOnline: widget.isOnline,
                    ),
                  ),
                ),
              ],
            ),
            // الإسناد إلزامي بموجب شروط استخدام خرائط OpenStreetMap.
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 14,
          child: Column(
            children: [
              _MapControlBtn(
                icon: Icons.add_rounded,
                tooltip: 'تكبير',
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  math.min(_mapController.camera.zoom + 1, 18),
                ),
              ),
              const SizedBox(height: 8),
              _MapControlBtn(
                icon: Icons.remove_rounded,
                tooltip: 'تصغير',
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  math.max(_mapController.camera.zoom - 1, 4),
                ),
              ),
              const SizedBox(height: 8),
              _MapControlBtn(
                icon: Icons.my_location_rounded,
                tooltip: 'موقعي',
                onTap: () => _focusOn(MapFocusTarget.driver),
              ),
              if (widget.activeOrder != null) ...[
                const SizedBox(height: 8),
                _MapControlBtn(
                  icon: Icons.storefront_rounded,
                  tooltip: 'المطعم',
                  active: _currentFocus == MapFocusTarget.restaurant,
                  onTap: () => _focusOn(MapFocusTarget.restaurant),
                ),
                const SizedBox(height: 8),
                _MapControlBtn(
                  icon: Icons.person_pin_circle_rounded,
                  tooltip: 'الزبون',
                  active: _currentFocus == MapFocusTarget.customer,
                  onTap: () => _focusOn(MapFocusTarget.customer),
                ),
                const SizedBox(height: 8),
                _MapControlBtn(
                  icon: Icons.fullscreen_rounded,
                  tooltip: 'عرض المسار كاملاً',
                  onTap: _fitAllPoints,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// دبوس وجهة مع اسم المكان أعلاه.
class _DestinationPin extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _DestinationPin({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.sc.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ),
        const SizedBox(height: 2),
        Icon(icon, color: color, size: 34),
      ],
    );
  }
}

/// نقطة المندوب مع نبضة تدل على البث اللحظي.
class _DriverBeacon extends StatelessWidget {
  final double pulse;
  final bool isOnline;

  const _DriverBeacon({required this.pulse, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? SColors.brand : Colors.grey;
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isOnline)
              Container(
                width: 40 + (pulse * 60),
                height: 40 + (pulse * 60),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.18 * (1 - pulse)),
                ),
              ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapControlBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const _MapControlBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? SColors.brand : context.sc.surface,
        borderRadius: BorderRadius.circular(10),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 20,
              color: active ? Colors.white : context.sc.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
