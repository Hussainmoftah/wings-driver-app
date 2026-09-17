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
  final String? errorMessage;
  final bool isUpdatingStatus;

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
    this.errorMessage,
    this.isUpdatingStatus = false,
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
    String? errorMessage,
    bool? isUpdatingStatus,
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
      remainingDepositCapacity: remainingDepositCapacity ?? this.remainingDepositCapacity,
      errorMessage: errorMessage,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
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
        errorMessage,
        isUpdatingStatus,
      ];
}
