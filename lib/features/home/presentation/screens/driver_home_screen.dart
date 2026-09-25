import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/driver_login_screen.dart';
import '../cubit/driver_home_cubit.dart';
import '../cubit/driver_home_state.dart';
import '../../../notifications/screens/driver_notifications_screen.dart';
import '../widgets/active_delivery_card.dart';
import '../widgets/driver_live_map_widget.dart';
import '../widgets/offline_duty_banner.dart';
import '../widgets/radar_search_widget.dart';
import '../widgets/today_summary_cards.dart';

class DriverHomeScreen extends StatefulWidget {
  final AuthRepository? authRepository;

  const DriverHomeScreen({
    super.key,
    this.authRepository,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late final AuthRepository _authRepository;
  int _currentTabIndex = 0;
  MapFocusTarget _mapFocus = MapFocusTarget.restaurant;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
    context.read<DriverHomeCubit>().loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F4),
      body: BlocConsumer<DriverHomeCubit, DriverHomeState>(
        listener: (context, state) {
          if (state.status == DriverHomeStatus.unauthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => DriverLoginScreen(
                  initialErrorMessage: state.errorMessage ?? 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.',
                ),
              ),
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          if (state.status == DriverHomeStatus.loading && state.profile == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final bool isOnline = state.profile?.isOnline ?? false;

          return IndexedStack(
            index: _currentTabIndex,
            children: [
              // Tab 0: Clean Full-Screen Google Maps Navigation View
              _buildHomeGoogleMapTab(context, state, isOnline),

              // Tab 1: Trips History
              _buildTripsTab(state),

              // Tab 2: Wallet & Financial Settlements
              _buildWalletTab(state),

              // Tab 3: Driver Profile & Vehicle
              _buildProfileTab(state),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) => setState(() => _currentTabIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1A73E8), // Google Blue
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.navigation_rounded),
              label: 'الخريطة والملاحة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'الرحلات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'المحفظة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeGoogleMapTab(BuildContext context, DriverHomeState state, bool isOnline) {
    final bool hasActiveOrder = isOnline && state.activeOrder != null;

    return Stack(
      children: [
        // 1. FULL SCREEN GOOGLE MAPS CANVAS (Takes 100% of the screen)
        Positioned.fill(
          child: DriverLiveMapWidget(
            activeOrder: state.activeOrder,
            isOnline: isOnline,
            initialFocus: _mapFocus,
            onFocusChanged: (target) {
              setState(() => _mapFocus = target);
            },
          ),
        ),

        // 2. TOP MINIMALIST FLOATING GOOGLE NAVIGATION BAR
        Positioned(
          top: 0,
          left: 14,
          right: 14,
          child: SafeArea(
            bottom: false,
            child: hasActiveOrder
                ? _buildActiveNavigationTopBar(state)
                : _buildIdleDutyTopBar(context, state, isOnline),
          ),
        ),

        // 3. BOTTOM COMPACT DRAGGABLE DELIVERY SHEET
        DraggableScrollableSheet(
          initialChildSize: hasActiveOrder ? 0.25 : (isOnline ? 0.24 : 0.22),
          minChildSize: 0.12,
          maxChildSize: 0.85,
          snap: true,
          snapSizes: hasActiveOrder ? const [0.12, 0.25, 0.85] : const [0.12, 0.24, 0.80],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Drag Handle Pill
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 6),
                        width: 40,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    if (hasActiveOrder) ...[
                      // Compact Delivery Card with Item Details & Quick Actions
                      ActiveDeliveryCard(
                        order: state.activeOrder!,
                        isUpdating: state.isUpdatingStatus,
                        onUpdateStatus: (newStatus, orderId) {
                          if (newStatus == 'on_the_way') {
                            setState(() => _mapFocus = MapFocusTarget.customer);
                          }
                          context.read<DriverHomeCubit>().updateOrderStatus(newStatus, orderId);
                        },
                        onFocusRestaurantOnMap: () {
                          setState(() => _mapFocus = MapFocusTarget.restaurant);
                        },
                        onFocusCustomerOnMap: () {
                          setState(() => _mapFocus = MapFocusTarget.customer);
                        },
                      ),
                    ] else if (isOnline) ...[
                      const RadarSearchWidget(),
                    ] else ...[
                      OfflineDutyBanner(
                        onGoOnline: () => context.read<DriverHomeCubit>().toggleDuty(true),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Today's Summary Metrics inside the sheet
                    TodaySummaryCards(
                      todayEarnings: state.todayEarnings,
                      completedOrdersCount: state.completedOrdersCount,
                      shiftHours: state.shiftHours,
                      acceptanceRate: state.acceptanceRate,
                    ),

                    const SizedBox(height: 16),

                    // Operations Support Banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.headset_mic_rounded, color: Color(0xFF4F46E5), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'مشرف العمليات والدعم',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                Text(
                                  'تواصل فوراً لأي مساعدة في التوصيل',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A73E8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(60, 34),
                            ),
                            child: const Text('اتصال', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Google Maps Style Top Floating Navigation Header
  Widget _buildActiveNavigationTopBar(DriverHomeState state) {
    final bool isRestaurant = _mapFocus == MapFocusTarget.restaurant;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Maneuver Icon (Google Maps Turn Arrow)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isRestaurant ? const Color(0xFF1A73E8) : const Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRestaurant ? Icons.turn_right_rounded : Icons.straight_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),

          // Street Instruction & ETA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      isRestaurant ? '5 دقائق (1.8 كم)' : '9 دقائق (3.6 كم)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'أسرع مسار',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  isRestaurant ? 'نحو مطعم أجنحة ليبيا • طريق الشط' : 'نحو الزبون: طارق الزنتاني • حي الأندلس',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Target Switcher Pill (المطعم / الزبون)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactTargetBtn(
                  title: 'المطعم',
                  icon: Icons.storefront_rounded,
                  isSelected: isRestaurant,
                  color: const Color(0xFF1A73E8),
                  onTap: () => setState(() => _mapFocus = MapFocusTarget.restaurant),
                ),
                _buildCompactTargetBtn(
                  title: 'الزبون',
                  icon: Icons.person_pin_circle_rounded,
                  isSelected: !isRestaurant,
                  color: const Color(0xFF10B981),
                  onTap: () => setState(() => _mapFocus = MapFocusTarget.customer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTargetBtn({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF64748B), size: 14),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Idle Floating Top Bar
  Widget _buildIdleDutyTopBar(BuildContext context, DriverHomeState state, bool isOnline) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Driver Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
              border: Border.all(
                color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                width: 2,
              ),
            ),
            child: const Icon(Icons.person, color: Color(0xFF475569), size: 22),
          ),
          const SizedBox(width: 10),

          // Driver Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.profile?.name ?? 'الكابتن',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  isOnline ? '🟢 متصل • جاهز لاستقبال أقرب الطلبات' : '🔴 غير متصل بالشبكة',
                  style: TextStyle(
                    color: isOnline ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),

          // Notifications Bell Button
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverNotificationsScreen()),
              ).then((_) {
                if (context.mounted) {
                  context.read<DriverHomeCubit>().refreshHome();
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 20),
                ),
                if (state.unreadNotificationsCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${state.unreadNotificationsCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Toggle Duty Switch
          Switch.adaptive(
            value: isOnline,
            activeTrackColor: const Color(0xFF10B981),
            onChanged: (val) => context.read<DriverHomeCubit>().toggleDuty(val),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsTab(DriverHomeState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سجل رحلات اليوم',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: state.completedOrdersCount == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.two_wheeler_outlined, size: 40, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد رحلات مسلّمة اليوم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'عند استلام وتوصيل الطلبيات، ستظهر تفاصيل الرحلات هنا',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.completedOrdersCount,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AppColors.onlineGreenLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, color: AppColors.onlineGreen, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'طلب مكتمل #${index + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                    ),
                                    const Text(
                                      'تم التوصيل بنجاح',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Cairo'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletTab(DriverHomeState state) {
    final double todayEarnings = state.todayEarnings;
    final double todayCashCustody = state.codCustody;
    final double monthlyEarnings = state.todayEarnings;
    final int monthlyTrips = state.completedOrdersCount;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المحفظة والتحصيلات المالية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'سبتمبر 2026',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. TOP DUAL HEADER SECTION: Today's Delivery Earnings & Today's Cash Custody Side-by-Side
            Row(
              children: [
                // Right Card: محصلة التوصيل لليوم
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.onlineGreen.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.onlineGreen.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.onlineGreenLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.payments_rounded,
                                color: AppColors.onlineGreen,
                                size: 20,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.onlineGreenLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'أرباحك',
                                style: TextStyle(
                                  color: AppColors.onlineGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'محصلة التوصيل لليوم',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${todayEarnings.toStringAsFixed(2)} د.ل',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.completedOrdersCount} طلبيات مكتملة',
                          style: const TextStyle(
                            color: AppColors.onlineGreen,
                            fontSize: 11,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Left Card: إجمالي العهدة لليوم
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.busyOrange.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.busyOrange.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.busyOrangeLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppColors.busyOrange,
                                size: 20,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.busyOrangeLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'نقد كاش',
                                style: TextStyle(
                                  color: AppColors.busyOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'إجمالي العهدة لليوم',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${todayCashCustody.toStringAsFixed(2)} د.ل',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'مطلوب توريدها للإدارة',
                          style: TextStyle(
                            color: AppColors.busyOrange,
                            fontSize: 11,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 2. MONTHLY SUMMARY SECTION: محصلة التوصيل لمدة شهر
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF0F766E),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'محصلة التوصيل لشهر كامل (30 يوم)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.onlineGreen.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.onlineGreen.withValues(alpha: 0.6)),
                        ),
                        child: const Text(
                          'أداء ممتاز ⭐',
                          style: TextStyle(
                            color: AppColors.onlineGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${monthlyEarnings.toStringAsFixed(2)} د.ل',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Text(
                    'صافي أرباح التوصيل المتراكمة المستحقة للسائق',
                    style: TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 18),

                  // 3-Pill Stat Row inside Monthly Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMonthlyMiniStat(
                          label: 'إجمالي الرحلات',
                          value: '$monthlyTrips رحلة',
                          icon: Icons.two_wheeler_rounded,
                        ),
                        Container(width: 1, height: 28, color: Colors.white12),
                        _buildMonthlyMiniStat(
                          label: 'المتوسط اليومي',
                          value: '${(monthlyEarnings / 30).toStringAsFixed(1)} د.ل',
                          icon: Icons.trending_up_rounded,
                        ),
                        Container(width: 1, height: 28, color: Colors.white12),
                        _buildMonthlyMiniStat(
                          label: 'مكافآت وحوافز',
                          value: '+120.00 د.ل',
                          icon: Icons.stars_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Monthly Target Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'هدف الدخل الشهري (2,000 د.ل)',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Cairo'),
                          ),
                          Text(
                            '72.5%',
                            style: TextStyle(
                              color: AppColors.onlineGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (monthlyEarnings / 2000.0).clamp(0.0, 1.0),
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.onlineGreen),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 3. CUSTODY SETTLEMENT & RECONCILIATION ACTION CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.handshake_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'تسوية العهدة النقدية والأرباح',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: const Text('كود التوريد', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم إرسال طلب تسوية العهدة النقدية بنجاح إلى مشرف العمليات', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: AppColors.onlineGreen,
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt_long_rounded, size: 18),
                          label: const Text(
                            'طلب تسوية عهدة كاش',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.busyOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تحويل أرباحك إلى حساب المحفظة البنكية', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          icon: const Icon(Icons.account_balance_rounded, size: 18),
                          label: const Text(
                            'سحب الأرباح',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. RECENT FINANCIAL TRANSACTIONS LIST
            const Text(
              'سجل التحصيلات والتسويات الأخيرة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'لا توجد حركات تسوية أو تحصيل مسجلة حالياً',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Cairo'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyMiniStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'Cairo'),
        ),
      ],
    );
  }


  Widget _buildProfileTab(DriverHomeState state) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الملف الشخصي للكابتن',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: state.isOnline ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isOnline ? 'متاح للطلبات' : 'غير متصل',
                        style: TextStyle(
                          color: state.isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0052FF), Color(0xFF06B6D4)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0052FF).withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 44),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: state.isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.profile?.name ?? 'الكابتن',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.profile?.phone ?? '--',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                        SizedBox(width: 4),
                        Text(
                          'تقييم الكابتن: 4.9 ★ (128 تقييم)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Vehicle & Operational Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بيانات المركبة والعمليات',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 12),
                  _buildProfileRow(Icons.two_wheeler_outlined, 'نوع المركبة', 'دراجة نارية سريعة'),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  _buildProfileRow(Icons.pin_outlined, 'رقم لوحة المركبة', 'طرابلس 12-58493'),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  _buildProfileRow(Icons.verified_user_outlined, 'حالة الحساب', 'موثق ومعتمد رسمي'),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  _buildProfileRow(Icons.headset_mic_outlined, 'دعم العمليات', '0910000002'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.white),
                label: const Text(
                  'تسجيل الخروج وإنهاء الوردية',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Cairo'),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text(
              'تسجيل الخروج',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من إنهاء وردية العمل وتسجيل الخروج من تطبيق كابتن وينجز؟',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              Navigator.pop(ctx);
              await _authRepository.logout();
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'نعم، خروج',
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
}
