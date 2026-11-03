import 'package:flutter_test/flutter_test.dart';
import 'package:wings_driver/features/profile/data/driver_profile_model.dart';

void main() {
  test('a new driver has no rating; a rated one keeps it through copyWith', () {
    final fresh = DriverProfileModel.fromJson({'user_id': 1, 'rating': null, 'ratings_count': 0});
    expect(fresh.rating, isNull);

    final rated = DriverProfileModel.fromJson({'user_id': 2, 'rating': 4.25, 'ratings_count': 12});
    final updated = rated.copyWith(isOnline: true);
    expect(updated.rating, 4.25);
    expect(updated.ratingsCount, 12);
  });
}
