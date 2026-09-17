# وثيقة الحالة التشغيلية وتتبع الإحداثيات الجغرافية (Phase 5)
## Wings Driver Operational State, GPS Telemetry & Dispatch Eligibility Contract

---

## 1. المبدأ الأساسي للمعمارية (Phase 5 Core Principles)

```text
Driver Operational State  ──>  Dispatch Eligibility  ──>  Assignment Quality  ──>  Reassignment / Handoff
```

* **الخادم هو مصدر الحقيقة الدائم (Backend is Source of Truth):** تطبيق السائق هو عميل مصرح له يرسل التيليمتري اللحظي وينفذ الحالات المعتمدة، ولا يتخذ أي قرار توزيع أو صلاحيات نيابة عن الخادم.
* **فشل الـ GPS $\neq$ إلغاء الطلب (GPS Failure != Order Cancellation):** في حال انقطاع أو تعثر إشارة الـ GPS، لا يتم إلغاء الطلب قسرياً، بل يستمر مسار الطلب مع توثيق حادثة تشغيلية (Operational Incident) لمتابعة المشرف.
* **تقادم الـ GPS $\neq$ إعادة إسناد تلقائي (GPS Stale != Auto Reassignment):** المندوب الذي يتقادم موقعه يُستبعد فقط من استقبال طلبات جديدة، بينما تبقى طلباته الحالية مسندة له ما لم تتدخل إدارة العمليات يدوياً.
* **وضع عدم الاتصال $\neq$ سلطة محلية (Offline != Local Business Authority):** لا يمكن للتطبيق في وضع عدم الاتصال اتخاذ قرارات مالية أو تغيير حالات حاسمة بدون مزامنة الخادم.

---

## 2. مصفوفة الحالات التشغيلية وإمكانية الاستقبال (Driver Operational State Matrix)

| الحالة التشغيلية (`DriverOperationalStatus`) | الاتصال الشبكي (`is_online`) | أهلية التوزيع الفوري (`Dispatch Eligibility`) | استقبال طلبات جديدة | بث التيليمتري الجغرافي (`GPS Telemetry`) |
| :--- | :---: | :---: | :---: | :---: |
| **`online`** (متصل ومتاح) | `true` | **مؤهل** (بشرط حداثة الموقع وعدم تجاوز السعة القصوى) | نعم (حتى طلبين نشطين كحد أقصى) | **مفعل** |
| **`on_break`** (استراحة مؤقتة) | `true` | **مستبعد** | لا | متوقف لحفظ البطارية والخصوصية |
| **`busy`** (مشغول بطلب أو ممتلئ السعة) | `true` | **مستبعد** (إذا بلغ 2 طلبات أو خارج شروط التجميع) | لا | **مفعل** (لتتبع مسار التوصيل الحي) |
| **`offline`** (غير متصل / خارج الوردية) | `false` | **مستبعد كلياً** | لا | **متوقف تماماً** (إيقاف المؤقتات والتتبع) |

---

## 3. عقد التيليمتري الجغرافي وحداثة الموقع (GPS Contract & Freshness Policy)

### أ. عقد استدعاء تحديث الإحداثيات (`POST /api/driver/location`)

```json
{
  "latitude": 32.8872091,
  "longitude": 13.1913382,
  "heading": 180.0,
  "accuracy": 4.5
}
```

* **التحقق الهندسي من الحدود (Coordinate Boundary Validation):**
  - $-90.0 \le \text{Latitude} \le 90.0$
  - $-180.0 \le \text{Longitude} \le 180.0$
  - رفض أي قيم نصية أو إحداثيات وهمية (Fake Coords) عبر كلاس `DriverAvailabilityService::updateLocation()`.

### ب. سياسة حداثة الموقع الزمني (Location Freshness Policy)

```text
[0s ──────────────── 300s (5 Min)] ──────────────── 900s (15 Min) ────────────────> [> 900s Stale]
        ▲                                    ▲                                     ▲
  موقع طازج جداً                      عتبة التوزيع الذكي                     موقع متقادم كلياً
  (مرشح مثالي للتجميع)               (Dispatch Eligibility)                  (مستبعد من أي إسناد جديد)
```

1. **عتبة التوزيع الفوري (Dispatch Freshness Cutoff):** $900$ ثانية (15 دقيقة) — أي سائق لم يرسل تحديثاً خلال 15 دقيقة يُستبعد تلقائياً من استعلام `getEligibleDriversQuery()`.
2. **عتبة التجميع الذكي (Smart Batching Cutoff):** $300$ ثانية (5 دقائق) — مشترطة لمقارنة المسافات الدقيقة واختيار أقرب سائق للمطعم.

---

## 4. استراتيجية التيليمتري وإدارة البطارية (Battery & Performance Optimization)

### أ. المؤقتات التكيفية (Adaptive Polling & Telemetry Gating)

في السابق، كان التطبيق يستهلك مؤقتاً دورياً أعمى (`Timer.periodic` كل 3 ثوانٍ) حتى أثناء وضع عدم الاتصال (`offline`) أو انتهاء الجلسة، مما يؤدي لاستنزاف البطارية واستهلاك الشبكة دون جدوى.

**التنفيذ الحالي في `DriverHomeCubit`:**
* **وضع `offline`:** يتم إلغاء المؤقت تماماً (`_pollTimer?.cancel()`) وتجميد استعلامات الشبكة ونبضات الـ GPS.
* **وضع `online`:** تفعيل مؤقت تكيفي ذكي ومتباعد (كل 5 ثوانٍ) يتوقف فورياً بمجرد تحول الحالة إلى `offline` أو حدوث خطأ جلسة `401 Unauthorized`.
* **بث التيليمتري الجغرافي (`updateLocation`):** مشروط بكون السائق متصلاً `state.profile?.isOnline == true`. في حال كان غير متصل، يتم تجاهل محاولة الإرسال فورياً في طبقة العرض والـ Domain دون إجراء طلب HTTP.

---

## 5. تكامل الأهلية وإعادة الإسناد (Dispatch & Reassignment Integration)

### أ. قاعدة السعة القصوى ومنع التعيين الزائد (Max 2 Active Orders)
* يتم فحص السعة القصوى داخل معاملة ذرية `DB::transaction()` مع استخدام أقفال تشاؤمية على صف الطلب وصف السائق:
  ```php
  $order = Order::where('id', $orderId)->lockForUpdate()->first();
  $driver = User::where('id', $driverId)->lockForUpdate()->first();
  ```
* إذا بلغ السائق طلبين نشطين، يُمنع إسناد أي طلب ثالث له قطعياً، وتُرمى استثناءات الأهلية الفورية.

### ب. إعادة الإسناد ونقاط الاستلام الفعلية (Handoff Physical Location Origins)
1. **نقطة المطعم (`restaurant`):** إذا كانت الشحنة لا تزال لدى المطعم، تُحسب مسافات السائقين البدلاء من إحداثيات المطعم.
2. **نقطة المندوب المتعثر (`with_driver`):** إذا استلم المندوب الشحنة ثم تعثر، تُحسب مسافات السائقين البدلاء من آخر إحداثيات GPS موثوقة مرسلة من المندوب السابق (`driverProfile->current_latitude`).
3. **استبعاد السائق السابق:** يتم استبعاد السائق المتعثر قطعياً من قائمة المرشحين البدلاء (`excludeDriverIds = [$previousDriverId]`).

---

## 6. مصفوفة التحقق والتدقيق النهائي (Final Verification Matrix)

| البند والمتطلب (Requirement) | الحالة (Status) | الملف (File) | الكلاس / الدالة (Class / Method) | الاختبار الآلي المطابق (Automated Test) | النتيجة |
| :--- | :---: | :--- | :--- | :--- | :---: |
| **Driver operational state** | **PASS** | `app/Services/DriverAvailabilityService.php` | `updateStatus()` | `DriverAvailabilityAndLocationTest::test_driver_status_transitions_and_timestamps` | **PASS** |
| **Server-side availability** | **PASS** | `app/Services/DriverAvailabilityService.php` | `getEligibleDriversQuery()` | `DriverAvailabilityAndLocationTest::test_dispatch_eligibility_query_contract` | **PASS** |
| **GPS contract & telemetry** | **PASS** | `app/Services/DriverAvailabilityService.php` | `updateLocation()` | `DriverAvailabilityAndLocationTest::test_driver_location_update_and_telemetry` | **PASS** |
| **GPS validation boundaries** | **PASS** | `app/Services/DriverAvailabilityService.php` | `updateLocation()` | `DriverAvailabilityAndLocationTest::test_coordinate_validation_boundary_limits` | **PASS** |
| **GPS freshness cutoff** | **PASS** | `app/Services/DriverAvailabilityService.php` | `getEligibleDriversQuery()` | `DriverAvailabilityAndLocationTest::test_location_freshness_policy` | **PASS** |
| **Location update strategy** | **PASS** | `wings-driver-app/lib/features/home/presentation/cubit/driver_home_cubit.dart` | `updateLocation()` | `driver_clean_architecture_test.dart::Phase 5 GPS Telemetry` | **PASS** |
| **Offline adaptive polling** | **PASS** | `wings-driver-app/lib/features/home/presentation/cubit/driver_home_cubit.dart` | `toggleDuty()` / `_startPolling()` | `driver_clean_architecture_test.dart::Adaptive Polling` | **PASS** |
| **Dispatch eligibility** | **PASS** | `app/Services/DriverSelectionService.php` | `selectBestDriver()` | `DispatchEngineTest::test_1_strategy_1_assigns_nearest_idle_driver` | **PASS** |
| **Max 2 active orders** | **PASS** | `app/Services/OrderLifecycleService.php` | `assignDriver()` / `reassignDriver()` | `DispatchEngineTest::test_16_driver_with_2_active_orders_never_eligible_for_third_order` | **PASS** |
| **Reassignment with_driver** | **PASS** | `app/Services/DriverReassignmentService.php` | `resolveOriginCoordinates()` | `DriverReassignmentAndOperationalIncidentsTest::test_6_manual_reassignment_with_driver_handoff_physical_location` | **PASS** |
| **Exclude previous driver** | **PASS** | `app/Services/DriverReassignmentService.php` | `reassign()` | `DriverReassignmentAndOperationalIncidentsTest::test_9_manual_reassignment_excludes_previous_driver` | **PASS** |
| **No auto reassignment** | **PASS** | `app/Services/OperationalIncidentService.php` | `detectIncidentsForActiveOrders()` | `DriverReassignmentAndOperationalIncidentsTest::test_4_system_does_not_auto_reassign_or_cancel_on_incident` | **PASS** |
| **Clean Architecture** | **PASS** | `wings-driver-app/lib/features/*/presentation/` | Static Audit | `flutter analyze` + `Static Audit Grep` (0 Matches) | **PASS** |
| **Flutter Tests** | **PASS** | `wings-driver-app/test/` | Full Suite | `flutter test` (33 / 33 tests passed) | **PASS** |
| **Backend Tests** | **PASS** | `wings-backend-app/tests/Feature/` | Full Suite | `php artisan test` (193 / 193 tests passed) | **PASS** |

---

# FINAL VERDICT
**PHASE 5 — VERIFIED**
