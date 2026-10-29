import 'package:flutter/material.dart';
import '../widgets/driver_wallet_cards.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/driver_login_screen.dart';
import '../cubit/driver_home_cubit.dart';
import '../cubit/driver_home_state.dart';
import '../../../notifications/screens/driver_notifications_screen.dart';
import '../widgets/active_delivery_card.dart';
import '../../../../core/theme/driver_palette.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../orders/data/driver_order_model.dart';
import '../widgets/driver_live_map_widget.dart';
import '../widgets/offline_duty_banner.dart';
import '../widgets/radar_search_widget.dart';
import 'package:sadeem_ui/sadeem_ui.dart';

class DriverHomeScreen extends StatefulWidget {
  final AuthRepository? authRepository;

  const DriverHomeScreen({super.key, this.authRepository});

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
      backgroundColor: context.dp.ground,
      body: BlocConsumer<DriverHomeCubit, DriverHomeState>(
        listener: (context, state) {
          if (state.status != DriverHomeStatus.unauthenticated &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: SColors.red600,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state.status == DriverHomeStatus.unauthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => DriverLoginScreen(
                  initialErrorMessage:
                      state.errorMessage ??
                      'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.',
                ),
              ),
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          if (state.status == DriverHomeStatus.loading &&
              state.profile == null) {
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
          color: context.sc.surface,
          border: Border(
            top: BorderSide(color: context.sc.border, width: 1),
          ),
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
          backgroundColor: context.dp.surface,
          selectedItemColor: context.dp.navyInk,
          unselectedItemColor: context.dp.muted,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
          ),
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

  Widget _buildHomeGoogleMapTab(
    BuildContext context,
    DriverHomeState state,
    bool isOnline,
  ) {
    final bool hasActiveOrder = isOnline && state.activeOrder != null;

    return Stack(
      children: [
        // 1. FULL SCREEN GOOGLE MAPS CANVAS (Takes 100% of the screen)
        Positioned.fill(
          child: DriverLiveMapWidget(
            activeOrder: state.activeOrder,
            isOnline: isOnline,
            driverLat: state.driverLat,
            driverLng: state.driverLng,
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
          snapSizes: hasActiveOrder
              ? const [0.12, 0.25, 0.85]
              : const [0.12, 0.24, 0.80],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: context.sc.surface,
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
                          color: SColors.slate300,
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
                          context.read<DriverHomeCubit>().updateOrderStatus(
                            newStatus,
                            orderId,
                          );
                        },
                        onFocusRestaurantOnMap: () {
                          setState(() => _mapFocus = MapFocusTarget.restaurant);
                        },
                        onFocusCustomerOnMap: () {
                          setState(() => _mapFocus = MapFocusTarget.customer);
                        },
                      ),
                      if (state.nextOrder != null) ...[
                        const SizedBox(height: 10),
                        _NextOrderBanner(order: state.nextOrder!),
                      ],
                    ] else if (isOnline) ...[
                      const RadarSearchWidget(),
                    ] else ...[
                      OfflineDutyBanner(
                        onGoOnline: () =>
                            context.read<DriverHomeCubit>().toggleDuty(true),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Today's Summary Metrics inside the sheet
                    // نافذتا العهدة والمستحقات + تقدم المكافأة
                    DriverWalletCards(
                      cashCustody: state.codCustody,
                      requiredRemittance: state.requiredRemittance,
                      earnings: state.todayEarnings,
                      payoutDue: state.payoutDue,
                      rewardEnabled: state.rewardEnabled,
                      rewardEvery: state.rewardEvery,
                      rewardRemaining: state.rewardRemaining,
                      todayDeliveries: state.rewardTodayDeliveries,
                      rewardValueLabel: state.rewardValueLabel,
                    ),


                    const SizedBox(height: 16),

                    // Operations Support Banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.sc.page,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.sc.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: SColors.indigo100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.headset_mic_rounded,
                              color: SColors.indigo600,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'مشرف العمليات والدعم',
                                  style: TextStyle(
                                    color: context.sc.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                Text(
                                  'تواصل فوراً لأي مساعدة في التوصيل',
                                  style: TextStyle(
                                    color: context.sc.textSecondary,
                                    fontSize: 12,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SColors.googleBlue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(60, 34),
                            ),
                            child: const Text(
                              'اتصال',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Tajawal',
                                color: Colors.white,
                              ),
                            ),
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
        color: SColors.slate800,
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
              color: isRestaurant ? SColors.googleBlue : SColors.emerald500,
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
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: SColors.emerald500.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'أسرع مسار',
                        style: TextStyle(
                          color: SColors.emerald400,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  isRestaurant
                      ? 'نحو مطعم أجنحة ليبيا • طريق الشط'
                      : 'نحو الزبون: طارق الزنتاني • حي الأندلس',
                  style: const TextStyle(
                    color: SColors.slate400,
                    fontSize: 12,
                    fontFamily: 'Tajawal',
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
              color: SColors.slate900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactTargetBtn(
                  title: 'المطعم',
                  icon: Icons.storefront_rounded,
                  isSelected: isRestaurant,
                  color: SColors.googleBlue,
                  onTap: () =>
                      setState(() => _mapFocus = MapFocusTarget.restaurant),
                ),
                _buildCompactTargetBtn(
                  title: 'الزبون',
                  icon: Icons.person_pin_circle_rounded,
                  isSelected: !isRestaurant,
                  color: SColors.emerald500,
                  onTap: () =>
                      setState(() => _mapFocus = MapFocusTarget.customer),
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
            Icon(
              icon,
              color: isSelected ? Colors.white : SColors.slate500,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : SColors.slate500,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Idle Floating Top Bar
  Widget _buildIdleDutyTopBar(
    BuildContext context,
    DriverHomeState state,
    bool isOnline,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.sc.surface,
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
              color: context.sc.surfaceSunken,
              shape: BoxShape.circle,
              border: Border.all(
                color: isOnline ? SColors.emerald500 : SColors.red500,
                width: 2,
              ),
            ),
            child: Icon(Icons.person, color: context.sc.textBody, size: 22),
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
                  style: TextStyle(
                    color: context.sc.textHeading,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                Text(
                  isOnline
                      ? '🟢 متصل • جاهز لاستقبال أقرب الطلبات'
                      : '🔴 غير متصل بالشبكة',
                  style: TextStyle(
                    color: isOnline ? SColors.emerald600 : SColors.red600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Tajawal',
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
                MaterialPageRoute(
                  builder: (_) => const DriverNotificationsScreen(),
                ),
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
                    color: context.sc.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: context.sc.textHeading,
                    size: 20,
                  ),
                ),
                if (state.unreadNotificationsCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: SColors.red500,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${state.unreadNotificationsCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
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
            activeTrackColor: SColors.emerald500,
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
            Text(
              'سجل رحلات اليوم',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'Tajawal',
                color: context.dp.ink,
              ),
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
                            decoration: BoxDecoration(
                              color: context.sc.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.two_wheeler_outlined,
                              size: 40,
                              color: context.sc.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد رحلات مسلّمة اليوم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              color: context.sc.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'عند استلام وتوصيل الطلبيات، ستظهر تفاصيل الرحلات هنا',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Tajawal',
                              color: context.sc.textSecondary,
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
                            color: context.sc.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.sc.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AppColors.onlineGreenLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.onlineGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'طلب مكتمل #${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                    Text(
                                      'تم التوصيل بنجاح',
                                      style: TextStyle(
                                        color: context.sc.textSecondary,
                                        fontSize: 12,
                                        fontFamily: 'Tajawal',
                                      ),
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

  /// فلوسي: رقم واحد واضح (المطلوب توريده أو المستحق لي)، كيف انحسب، والمكافأة.
  /// لا أزرار تسوية وهمية: التسوية تتم مع محاسب السائقين وتظهر هنا بعد تسجيلها.
  Widget _buildWalletTab(DriverHomeState state) {
    String money(double v) => '${v.toStringAsFixed(2)} د.ل';
    final owesDriver = state.payoutDue > 0;

    Widget row(String label, String value, {Color? valueColor, bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: strong ? 18 : 17, fontWeight: strong ? FontWeight.w800 : FontWeight.w500, color: strong ? context.dp.ink : context.dp.body)),
              ),
              Text(value, style: TextStyle(fontFamily: 'Tajawal', fontSize: strong ? 18 : 17, fontWeight: FontWeight.w800, color: valueColor ?? context.dp.ink)),
            ],
          ),
        );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => context.read<DriverHomeCubit>().loadHomeData(),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('فلوسي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 22, fontWeight: FontWeight.w800, color: context.dp.ink)),
            ),
            const SizedBox(height: 14),
            DriverWalletCards(
              cashCustody: state.codCustody,
              requiredRemittance: state.requiredRemittance,
              earnings: state.todayEarnings,
              payoutDue: state.payoutDue,
              rewardEnabled: state.rewardEnabled,
              rewardEvery: state.rewardEvery,
              rewardRemaining: state.rewardRemaining,
              todayDeliveries: state.rewardTodayDeliveries,
              rewardValueLabel: state.rewardValueLabel,
            ),
            const SizedBox(height: 14),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: context.dp.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.dp.line, width: 2),
              ),
              child: Column(
                children: [
                  row('الكاش اللي حصّلته', money(state.codCustody)),
                  Divider(height: 1, color: context.dp.line),
                  row('أجري من التوصيل', '− ${money(state.todayEarnings)}', valueColor: context.dp.successText),
                  Divider(height: 1, color: context.dp.line),
                  owesDriver
                      ? row('مستحق لي من الشركة', money(state.payoutDue), strong: true, valueColor: context.dp.successText)
                      : row('المطلوب توريده', money(state.requiredRemittance), strong: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.dp.navySoft, borderRadius: BorderRadius.circular(18)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: context.dp.navyInk),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'التسوية تتم مع محاسب السائقين: تورّد له المبلغ المطلوب أو يصرفلك المستحق، ويتصفر الرصيد هنا بعد تسجيلها.',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, height: 1.6, color: context.dp.navyInk),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: state.isOnline ? SColors.green100 : SColors.slate100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.isOnline
                          ? SColors.green300
                          : context.sc.borderStrong,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isOnline
                              ? SColors.green600
                              : SColors.slate400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isOnline ? 'متاح للطلبات' : 'غير متصل',
                        style: TextStyle(
                          color: state.isOnline
                              ? SColors.green600
                              : context.sc.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
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
                color: context.sc.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: context.sc.border),
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
                            colors: [SColors.brand, SColors.cyan500],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: SColors.brand.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.two_wheeler_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: state.isOnline
                              ? SColors.emerald500
                              : SColors.slate400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.profile?.name ?? 'الكابتن',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.profile?.phone ?? '--',
                    style: TextStyle(
                      color: context.sc.textSecondary,
                      fontSize: 13,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.sc.page,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.sc.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: SColors.amber500,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'تقييم الكابتن: 4.9 ★ (128 تقييم)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.sc.textStrong,
                            fontFamily: 'Tajawal',
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
                color: context.sc.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.sc.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بيانات المركبة والعمليات',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProfileRow(
                    Icons.two_wheeler_outlined,
                    'نوع المركبة',
                    _vehicleLabel(state.profile?.vehicleType),
                  ),
                  Divider(height: 20, color: context.sc.borderSubtle),
                  _buildProfileRow(
                    Icons.badge_outlined,
                    'رقم الرخصة',
                    (state.profile?.licenseNumber?.trim().isNotEmpty ?? false) ? state.profile!.licenseNumber! : 'غير مسجل',
                  ),
                  Divider(height: 20, color: context.sc.borderSubtle),
                  _buildProfileRow(
                    Icons.phone_outlined,
                    'رقم الهاتف',
                    (state.profile?.phone.trim().isNotEmpty ?? false) ? state.profile!.phone : 'غير مسجل',
                  ),
                  Divider(height: 20, color: context.sc.borderSubtle),
                  _buildAppearanceSelector(),
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
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text(
                  'تسجيل الخروج وإنهاء الوردية',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Tajawal',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SColors.red600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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

  String _vehicleLabel(String? type) => switch (type) {
        'motorcycle' => 'دراجة نارية',
        'car' => 'سيارة',
        'bicycle' => 'دراجة هوائية',
        null || '' => 'غير مسجل',
        _ => type,
      };

  /// المظهر: تلقائي حسب الهاتف، نهاري، أو ليلي (يُحفظ على الجهاز)
  Widget _buildAppearanceSelector() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeController.instance,
      builder: (context, mode, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.dark_mode_outlined, size: 20, color: context.dp.muted),
              const SizedBox(width: 10),
              Text('المظهر', style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.w700, color: context.dp.ink)),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('تلقائي', style: TextStyle(fontFamily: 'Tajawal'))),
              ButtonSegment(value: ThemeMode.light, label: Text('نهاري', style: TextStyle(fontFamily: 'Tajawal'))),
              ButtonSegment(value: ThemeMode.dark, label: Text('ليلي', style: TextStyle(fontFamily: 'Tajawal'))),
            ],
            selected: {mode},
            onSelectionChanged: (s) => ThemeModeController.instance.set(s.first),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.sc.textSecondary),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: context.sc.textSecondary,
            fontFamily: 'Tajawal',
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: context.sc.textHeading,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.sc.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: SColors.red600, size: 24),
            SizedBox(width: 8),
            Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من إنهاء وردية العمل وتسجيل الخروج من تطبيق كابتن سديم؟',
          style: TextStyle(
            fontSize: 13,
            color: context.sc.textBody,
            fontFamily: 'Tajawal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: TextStyle(color: context.sc.textSecondary, fontFamily: 'Tajawal'),
            ),
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
              backgroundColor: SColors.red600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'نعم، خروج',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// طلب أُسند للسائق خلف توصيلته الجارية: يستلمه من المطعم بعد تسليمها
class _NextOrderBanner extends StatelessWidget {
  final DriverOrderModel order;

  const _NextOrderBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    return SCard(
      color: context.sc.brandTint,
      padding: const EdgeInsets.all(SSpacing.md),
      child: Row(
        children: [
          Icon(Icons.queue_outlined, color: context.sc.brandText),
          const SizedBox(width: SSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلبك التالي ${order.orderNumber}${order.restaurantName != null ? ' · ${order.restaurantName}' : ''}',
                  style: STextStyles.label.copyWith(fontWeight: FontWeight.w700, color: context.sc.textPrimary),
                ),
                Text(
                  'سلّم طلبك الحالي أولاً، ثم توجه للمطعم لاستلامه.',
                  style: STextStyles.caption.copyWith(color: context.sc.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
