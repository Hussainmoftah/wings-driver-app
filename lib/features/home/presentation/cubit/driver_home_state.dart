import 'package:equatable/equatable.dart';
import '../../../profile/data/driver_profile_model.dart';
import '../../../orders/data/driver_order_model.dart';

enum DriverHomeStatus { initial, loading, loaded, error, unauthenticated }

class DriverHomeState extends Equatable {
  final DriverHomeStatus status;
  final DriverProfileModel? profile;
  final DriverOrderModel? activeOrder;
  final double todayEarnings;
  final int completedOrdersCount;
  final double shiftHours;
  final double acceptanceRate;
  final double codCustody;
  final double depositAmount;
  final double remainingDepositCapacity;
  final int unreadNotificationsCount;

  /// المطلوب توريده (العهدة - الأجر) أو المستحق صرفه للسائق إن زاد أجره، وبرنامج المكافآت اليوم
  final double requiredRemittance;
  final double payoutDue;
  final bool rewardEnabled;
  final int rewardEvery;
  final int rewardRemaining;
  final int rewardTodayDeliveries;
  final String rewardValueLabel;
  final String? errorMessage;
  final bool isUpdatingStatus;

  /// الموقع اللحظي للمندوب من بثّ GPS؛ يبقى null قبل وصول أول قراءة.
  final double? driverLat;
  final double? driverLng;
  final double? driverHeading;

  const DriverHomeState({
    this.status = DriverHomeStatus.initial,
    this.profile,
    this.activeOrder,
    this.todayEarnings = 0.0,
    this.completedOrdersCount = 0,
    this.shiftHours = 0.0,
    this.acceptanceRate = 100.0,
    this.codCustody = 0.0,
    this.depositAmount = 0.0,
    this.remainingDepositCapacity = 0.0,
    this.unreadNotificationsCount = 0,
    this.requiredRemittance = 0.0,
    this.payoutDue = 0.0,
    this.rewardEnabled = false,
    this.rewardEvery = 0,
    this.rewardRemaining = 0,
    this.rewardTodayDeliveries = 0,
    this.rewardValueLabel = '',
    this.errorMessage,
    this.isUpdatingStatus = false,
    this.driverLat,
    this.driverLng,
    this.driverHeading,
  });

  bool get isOnline => profile?.isOnline ?? false;

  DriverHomeState copyWith({
    DriverHomeStatus? status,
    DriverProfileModel? profile,
    DriverOrderModel? activeOrder,
    bool clearActiveOrder = false,
    double? todayEarnings,
    int? completedOrdersCount,
    double? shiftHours,
    double? acceptanceRate,
    double? codCustody,
    double? depositAmount,
    double? remainingDepositCapacity,
    int? unreadNotificationsCount,
    double? requiredRemittance,
    double? payoutDue,
    bool? rewardEnabled,
    int? rewardEvery,
    int? rewardRemaining,
    int? rewardTodayDeliveries,
    String? rewardValueLabel,
    String? errorMessage,
    bool? isUpdatingStatus,
    double? driverLat,
    double? driverLng,
    double? driverHeading,
  }) {
    return DriverHomeState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      todayEarnings: todayEarnings ?? this.todayEarnings,
      completedOrdersCount: completedOrdersCount ?? this.completedOrdersCount,
      shiftHours: shiftHours ?? this.shiftHours,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      codCustody: codCustody ?? this.codCustody,
      depositAmount: depositAmount ?? this.depositAmount,
      remainingDepositCapacity:
          remainingDepositCapacity ?? this.remainingDepositCapacity,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
      requiredRemittance: requiredRemittance ?? this.requiredRemittance,
      payoutDue: payoutDue ?? this.payoutDue,
      rewardEnabled: rewardEnabled ?? this.rewardEnabled,
      rewardEvery: rewardEvery ?? this.rewardEvery,
      rewardRemaining: rewardRemaining ?? this.rewardRemaining,
      rewardTodayDeliveries: rewardTodayDeliveries ?? this.rewardTodayDeliveries,
      rewardValueLabel: rewardValueLabel ?? this.rewardValueLabel,
      errorMessage: errorMessage,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      driverHeading: driverHeading ?? this.driverHeading,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    activeOrder,
    todayEarnings,
    completedOrdersCount,
    shiftHours,
    acceptanceRate,
    codCustody,
    depositAmount,
    remainingDepositCapacity,
    unreadNotificationsCount,
    requiredRemittance,
    payoutDue,
    rewardEnabled,
    rewardEvery,
    rewardRemaining,
    rewardTodayDeliveries,
    rewardValueLabel,
    errorMessage,
    isUpdatingStatus,
    driverLat,
    driverLng,
    driverHeading,
  ];
}
