class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ServerException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت.'});

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException({this.message = 'انتهت صلاحية الجلسة، يرجى إعادة تسجيل الدخول.'});

  @override
  String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException implements Exception {
  final String message;

  const ForbiddenException({this.message = 'ليس لديك الصلاحية المطلوبة لتنفيذ هذا الإجراء.'});

  @override
  String toString() => 'ForbiddenException: $message';
}

class NotFoundException implements Exception {
  final String message;

  const NotFoundException({this.message = 'المورد المطلوب غير موجود.'});

  @override
  String toString() => 'NotFoundException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;

  const ValidationException({
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ValidationException: $message';
}
