import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../repositories/onboarding_repository.dart';
import '../network/api_exception.dart';
import 'api_providers.dart';
import 'auth_provider.dart';

enum OnboardingStep {
  welcome,
  mobileVerification,
  basicInfo,
  location,
  details,
  timing,
  photos,
  services,
  staff,
  bank,
  kyc,
  subscription,
  tour,
  completed,
}

class OnboardingState {
  final OnboardingStep currentStep;
  final bool isLoading;
  final String? errorMessage;
  final String? tenantId;
  final Map<String, dynamic> planData;
  final List<dynamic> plans;

  const OnboardingState({
    this.currentStep = OnboardingStep.welcome,
    this.isLoading = false,
    this.errorMessage,
    this.tenantId,
    this.planData = const {},
    this.plans = const [],
  });

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    bool? isLoading,
    String? errorMessage,
    String? tenantId,
    Map<String, dynamic>? planData,
    List<dynamic>? plans,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      tenantId: tenantId ?? this.tenantId,
      planData: planData ?? this.planData,
      plans: plans ?? this.plans,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  Future<void> fetchStatus() async {
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final status = await repo.getStatus();
      final stepStr = status['onboardingStep'] as String? ?? 'WELCOME';
      final mapped = _mapStepFromApi(stepStr);
      state = state.copyWith(
        currentStep: mapped,
        tenantId: status['tenantId'] as String?,
      );
    } catch (_) {
      // Ignore
    }
  }

  Future<void> fetchPlans() async {
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final fetchedPlans = await repo.getPlans();
      state = state.copyWith(plans: fetchedPlans);
    } catch (_) {
      // Ignore
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void goToStep(OnboardingStep step) {
    state = state.copyWith(currentStep: step, errorMessage: null);
  }

  void nextStep() {
    final steps = OnboardingStep.values;
    final currentIndex = steps.indexOf(state.currentStep);
    if (currentIndex < steps.length - 1) {
      state = state.copyWith(currentStep: steps[currentIndex + 1], errorMessage: null);
    }
  }

  void previousStep() {
    final steps = OnboardingStep.values;
    final currentIndex = steps.indexOf(state.currentStep);
    if (currentIndex > 0) {
      state = state.copyWith(currentStep: steps[currentIndex - 1], errorMessage: null);
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      // Use the link-phone OTP verify endpoint
      final dio = ref.read(apiClientProvider).dio;
      await dio.post('/auth/otp/link-phone', data: {
        'phone': phone,
        'otp': otp,
      });

      // Update the user's phone in auth state
      await ref.read(authControllerProvider.notifier).restoreAfterOtp();

      // Check onboarding status
      final status = await repo.getStatus();
      final stepStr = status['onboardingStep'] as String? ?? 'WELCOME';
      final mapped = _mapStepFromApi(stepStr);
      state = state.copyWith(currentStep: mapped, isLoading: false, tenantId: status['tenantId'] as String?);
      return true;
    } on DioException catch (e) {
      final apiException = ApiException.fromDioException(e);
      state = state.copyWith(isLoading: false, errorMessage: apiException.message);
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.post('/auth/otp/send', data: {'phone': phone});
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      final apiException = ApiException.fromDioException(e);
      state = state.copyWith(isLoading: false, errorMessage: apiException.message);
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred');
      return false;
    }
  }

  Future<bool> saveBasicInfo({
    required String ownerName,
    required String salonName,
    required String email,
    required String password,
    required String businessCategory,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final data = await repo.basicInfo(
        ownerName: ownerName,
        salonName: salonName,
        email: email,
        password: password,
        businessCategory: businessCategory,
      );
      state = state.copyWith(
        isLoading: false,
        tenantId: data['tenantId'] as String?,
        currentStep: OnboardingStep.location,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred');
      return false;
    }
  }

  Future<bool> saveLocation({
    required String country, required String stateStr,
    required String city, required String area,
    required String fullAddress, double? lat, double? lng,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.saveLocation(
        country: country, state: stateStr, city: city,
        area: area, fullAddress: fullAddress, latitude: lat, longitude: lng,
      );
      state = state.copyWith(isLoading: false, currentStep: OnboardingStep.details);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> saveDetails({
    String? gst, String? pan, String? regNo, String? description,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.saveDetails(
        gstNumber: gst, panNumber: pan,
        businessRegNumber: regNo, description: description,
      );
      state = state.copyWith(isLoading: false, currentStep: OnboardingStep.timing);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> saveTiming(List<Map<String, dynamic>> schedules) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.saveTiming(schedules: schedules);
      state = state.copyWith(isLoading: false, currentStep: OnboardingStep.photos);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<String?> uploadFile(String filePath) async {
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final data = await repo.uploadFile(filePath);
      return data['url'] as String?;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return null;
    }
  }

  Future<bool> savePhotos({String? logoUrl, String? coverUrl, List<Map<String, String>>? gallery}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.savePhotos(logoUrl: logoUrl, coverImageUrl: coverUrl, gallery: gallery);
      state = state.copyWith(isLoading: false, currentStep: OnboardingStep.services);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> skipServices() async {
    state = state.copyWith(currentStep: OnboardingStep.staff);
    return true;
  }

  Future<bool> addServices(List<Map<String, dynamic>> services) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.addServices(services);
      state = state.copyWith(isLoading: false, currentStep: OnboardingStep.staff);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> addStaff(List<Map<String, dynamic>> staffList) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.addStaff(staffList);
      state = state.copyWith(isLoading: false, currentStep: OnboardingStep.bank);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> skipStaff() async {
    state = state.copyWith(currentStep: OnboardingStep.bank);
    return true;
  }

  Future<bool> saveBankDetails({
    required String accountHolder, required String bankName,
    required String accountNumber, required String ifsc, String? upiId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.saveBankDetails(
        accountHolder: accountHolder, bankName: bankName,
        accountNumber: accountNumber, ifsc: ifsc, upiId: upiId,
      );
      state = state.copyWith(isLoading: false, currentStep: OnboardingStep.kyc);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> uploadKyc(String documentType, String fileUrl) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.uploadKyc(documentType, fileUrl);
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> subscribe(String planId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final data = await repo.subscribe(planId);
      state = state.copyWith(isLoading: false, planData: data, currentStep: OnboardingStep.tour);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> completeOnboarding() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.completeOnboarding();
      state = state.copyWith(isLoading: false, currentStep: OnboardingStep.completed);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  OnboardingStep _mapStepFromApi(String step) {
    switch (step) {
      case 'WELCOME': return OnboardingStep.welcome;
      case 'MOBILE_VERIFICATION': return OnboardingStep.mobileVerification;
      case 'BASIC_INFO': return OnboardingStep.basicInfo;
      case 'LOCATION': return OnboardingStep.location;
      case 'DETAILS': return OnboardingStep.details;
      case 'TIMING': return OnboardingStep.timing;
      case 'PHOTOS': return OnboardingStep.photos;
      case 'SERVICES': return OnboardingStep.services;
      case 'STAFF': return OnboardingStep.staff;
      case 'BANK': return OnboardingStep.bank;
      case 'KYC': return OnboardingStep.kyc;
      case 'SUBSCRIPTION': return OnboardingStep.subscription;
      case 'TOUR': return OnboardingStep.tour;
      case 'COMPLETED': return OnboardingStep.completed;
      default: return OnboardingStep.welcome;
    }
  }
}

final onboardingControllerProvider = NotifierProvider<OnboardingController, OnboardingState>(OnboardingController.new);

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});
