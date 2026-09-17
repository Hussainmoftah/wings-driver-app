import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت.'});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'انتهت صلاحية الجلسة، يرجى إعادة تسجيل الدخول.'});
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.message = 'ليس لديك الصلاحية المطلوبة لتنفيذ هذا الإجراء.'});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'المورد المطلوب غير موجود.'});
}

class ValidationFailure extends Failure {
  final Map<String, dynamic>? errors;
  const ValidationFailure({required super.message, this.errors});

  @override
  List<Object?> get props => [message, errors];
}
