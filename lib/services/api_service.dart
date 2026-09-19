import 'dart:io';
import 'api_config.dart';
import 'auth_service.dart';
import 'pet_service.dart';
import 'adoption_service.dart';
import 'health_service.dart';
import 'profile_service.dart';
import 'recommendation_service.dart';

export 'api_config.dart';
export 'api_client.dart';
export 'auth_service.dart';
export 'pet_service.dart';
export 'adoption_service.dart';
export 'health_service.dart';
export 'profile_service.dart';
export 'recommendation_service.dart';

/// Backward-compatible Facade for all mobile API services.
/// Delegates calls to focused domain services while maintaining compatibility with existing UI screens.
class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static String normalizeImageUrl(String? url) => ApiConfig.normalizeImageUrl(url);

  // Authentication & Session
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) => AuthService.register(
    name: name,
    email: email,
    password: password,
    passwordConfirmation: passwordConfirmation,
  );

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => AuthService.login(email: email, password: password);

  static Future<Map<String, dynamic>> checkEmailAvailability(String email) =>
      AuthService.checkEmailAvailability(email);

  static Future<Map<String, dynamic>> sendEmailOtp(String email) =>
      AuthService.sendEmailOtp(email);

  static Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
  }) => AuthService.verifyEmailOtp(email: email, otp: otp);

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) => AuthService.resetPassword(
    email: email,
    newPassword: newPassword,
    confirmPassword: confirmPassword,
  );

  static Future<String?> getToken() => AuthService.getToken();

  static Future<Map<String, dynamic>?> getUser() => AuthService.getUser();

  static Future<Map<String, dynamic>?> getProfile() => AuthService.getProfile();

  static Future<void> updateLastActiveTime() => AuthService.updateLastActiveTime();

  static Future<bool> isSessionExpired() => AuthService.isSessionExpired();

  static Future<void> clearSession() => AuthService.clearSession();

  static Future<void> saveFcmToken(String fcmToken) => AuthService.saveFcmToken(fcmToken);

  // Pets & Catalog
  static Future<List<Map<String, dynamic>>> getPets({
    String? type,
    String? search,
  }) => PetService.getPets(type: type, search: search);

  static Future<Map<String, dynamic>> getPetDetail(int id) => PetService.getPetDetail(id);

  // Adoption Applications & Contracts
  static Future<Map<String, dynamic>> submitAdoptionApplication({
    required Map<String, dynamic> data,
    String? validIdPath,
    String? certificatePath,
  }) => AdoptionService.submitAdoptionApplication(
    data: data,
    validIdPath: validIdPath,
    certificatePath: certificatePath,
  );

  static Future<String?> getContractDownloadUrl(int id) =>
      AdoptionService.getContractDownloadUrl(id);

  static Future<List<Map<String, dynamic>>> getMyApplications() =>
      AdoptionService.getMyApplications();

  static Future<Map<String, dynamic>> updatePetName({
    required int petId,
    required String name,
  }) => AdoptionService.updatePetName(
    petId: petId,
    name: name,
  );

  static Future<Map<String, dynamic>> signAdoptionContract({
    required int applicationId,
    String? signatureBase64,
    bool useSavedSignature = false,
  }) => AdoptionService.signAdoptionContract(
    applicationId: applicationId,
    signatureBase64: signatureBase64,
    useSavedSignature: useSavedSignature,
  );

  // Health Tracking & Vaccines
  static Future<Map<String, dynamic>> submitHealthUpdate({
    required int applicationId,
    required File photo,
    required String healthStatus,
    double? weight,
    String? notes,
  }) => HealthService.submitHealthUpdate(
    applicationId: applicationId,
    photo: photo,
    healthStatus: healthStatus,
    weight: weight,
    notes: notes,
  );

  static Future<List<Map<String, dynamic>>> getMyHealthUpdates({int? applicationId}) =>
      HealthService.getMyHealthUpdates(applicationId: applicationId);

  static Future<List<Map<String, dynamic>>> getVaccineReminders() =>
      HealthService.getVaccineReminders();

  static Future<Map<String, dynamic>> getPetMedicalPassport(int petId) =>
      HealthService.getPetMedicalPassport(petId);


  // Recommendations & Quiz
  static Future<List<Map<String, dynamic>>> getRecommendations({
    Map<String, dynamic>? profile,
  }) => RecommendationService.getRecommendations(profile: profile);

  static Future<Map<String, dynamic>?> getSavedPreferences() =>
      RecommendationService.getSavedPreferences();

  // User Profile
  static Future<Map<String, dynamic>?> fetchUserProfile() =>
      ProfileService.fetchUserProfile();

  static Future<Map<String, dynamic>> updateProfileName(String name) =>
      ProfileService.updateProfileName(name);

  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) =>
      ProfileService.uploadAvatar(imageFile);

  static Future<bool> updateAddress({
    required String address,
    String? city,
    String? province,
    String? phone,
  }) => ProfileService.updateAddress(
    address: address,
    city: city,
    province: province,
    phone: phone,
  );

  static Future<Map<String, dynamic>> updateUserSignature({
    required String signatureBase64,
  }) => ProfileService.updateUserSignature(signatureBase64: signatureBase64);
}
