import 'package:flutter/material.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/core/providers/core_providers.dart';

import '../../model/request/request_model.dart';

import 'package:flutter_riverpod/legacy.dart';

class RequestProvider extends ChangeNotifier {
  // Current request being created
  double? _amount;
  String? _reason;
  String _category = 'Entertainment';
  String? _note;
  DateTime? _dueDate;
  bool _isPrivate = true;
  List<Contact> _selectedContacts = [];
  DeliveryMethod _deliveryMethod = DeliveryMethod.inAppNotification;

  // All requests
  final List<MoneyRequest> _sentRequests = [];
  final List<MoneyRequest> _receivedRequests = [];

  // Loading state — drives shimmer in MyRequestsScreen
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Contacts
  final List<Contact> _recentContacts = [];
  final List<Contact> _allContacts = [];

  final DioClient _client;
  RequestProvider(this._client);

  // Getters
  double? get amount => _amount;
  String? get reason => _reason;
  String get category => _category;
  String? get note => _note;
  DateTime? get dueDate => _dueDate;
  bool get isPrivate => _isPrivate;
  List<Contact> get selectedContacts => _selectedContacts;
  DeliveryMethod get deliveryMethod => _deliveryMethod;
  List<MoneyRequest> get sentRequests => _sentRequests;
  List<MoneyRequest> get receivedRequests => _receivedRequests;
  List<Contact> get recentContacts => _recentContacts;
  List<Contact> get allContacts => _allContacts;

  // Setters
  void setAmount(double? value) {
    _amount = value;
    notifyListeners();
  }

  void setReason(String? value) {
    _reason = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setNote(String? value) {
    _note = value;
    notifyListeners();
  }

  void setDueDate(DateTime? value) {
    _dueDate = value;
    notifyListeners();
  }

  void setPrivacy(bool value) {
    _isPrivate = value;
    notifyListeners();
  }

  void setDeliveryMethod(DeliveryMethod value) {
    _deliveryMethod = value;
    notifyListeners();
  }

  void toggleContactSelection(Contact contact) {
    if (_selectedContacts.any((c) => c.id == contact.id)) {
      _selectedContacts.removeWhere((c) => c.id == contact.id);
    } else {
      _selectedContacts.add(contact);
    }
    notifyListeners();
  }

  void addContact(Contact contact) {
    if (!_selectedContacts.any((c) => c.id == contact.id)) {
      _selectedContacts.add(contact);
      notifyListeners();
    }
  }

  void removeContact(Contact contact) {
    _selectedContacts.removeWhere((c) => c.id == contact.id);
    notifyListeners();
  }

  void clearSelectedContacts() {
    _selectedContacts.clear();
    notifyListeners();
  }

  bool get canContinue {
    return _amount != null && _amount! > 0 && _selectedContacts.isNotEmpty;
  }

  // Request actions
  MoneyRequest createRequest() {
    if (!canContinue) {
      throw Exception('Cannot create request with incomplete data');
    }

    final request = MoneyRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      requesterId: 'current_user_id',
      requesterName: 'Current User',
      requesterPhone: '+2348012345678',
      amount: _amount!,
      reason: _reason,
      category: _category,
      description: _note,
      createdAt: DateTime.now(),
      dueDate: _dueDate,
      isPrivate: _isPrivate,
      recipientIds: _selectedContacts.map((c) => c.id).toList(),
      deliveryMethod: _deliveryMethod,
    );

    _sentRequests.add(request);
    resetForm();
    notifyListeners();
    return request;
  }

  void resetForm() {
    _amount = null;
    _reason = null;
    _category = 'Entertainment';
    _note = null;
    _dueDate = null;
    _isPrivate = true;
    _selectedContacts.clear();
    _deliveryMethod = DeliveryMethod.inAppNotification;
    notifyListeners();
  }

  // ✅ Fixed: contacts use distinct realistic phone numbers.
  // Received/sent requests now sourced from MockRequestData so they stay in
  // sync with the centralised mock API file.
  // isLoading set during fetch so UI can show RequestListShimmer.
  Future<void> loadRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Replace with your actual HTTP client instance
      final response = await _client.get<Map<String, dynamic>>('/requests');
      final raw = response.data!['requests'] as List<dynamic>;

      _sentRequests.clear();
      _receivedRequests.clear();

      for (final r in raw) {
        final request = MoneyRequest.fromJson(r as Map<String, dynamic>);
        // Route to correct list based on requesterId
        if (request.requesterId == 'current_user_id') {
          _sentRequests.add(request);
        } else {
          _receivedRequests.add(request);
        }
      }
    } on KudiApiException catch (e) {
      debugPrint('Load requests error: ${e.message}');
      // Optionally expose error: _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get statistics
  double get totalToReceive {
    return _receivedRequests
        .where((r) => r.status == RequestStatus.pending)
        .fold(0.0, (sum, r) => sum + r.amount);
  }

  double get totalWaitingOn {
    return _sentRequests
        .where((r) =>
            r.status == RequestStatus.pending ||
            r.status == RequestStatus.partial)
        .fold(0.0, (sum, r) => sum + r.remainingAmount);
  }

  List<MoneyRequest> getReceivedByStatus(RequestStatus status) {
    return _receivedRequests.where((r) => r.status == status).toList();
  }

  List<MoneyRequest> getSentByStatus(RequestStatus status) {
    return _sentRequests.where((r) => r.status == status).toList();
  }

  // Pay request
  Future<void> payRequest(MoneyRequest request, double amount) async {
    final index = _receivedRequests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      final updatedRequest = request.copyWith(
        paidAmount: (request.paidAmount ?? 0) + amount,
        status: (request.paidAmount ?? 0) + amount >= request.amount
            ? RequestStatus.paid
            : RequestStatus.partial,
        paidAt: DateTime.now(),
      );
      _receivedRequests[index] = updatedRequest;
      notifyListeners();
    }
  }

  // Decline request
  Future<void> declineRequest(MoneyRequest request) async {
    final index = _receivedRequests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      _receivedRequests[index] =
          request.copyWith(status: RequestStatus.declined);
      notifyListeners();
    }
  }
}

// Riverpod Provider
final requestProvider = ChangeNotifierProvider<RequestProvider>((ref) {
  return RequestProvider(ref.read(dioClientProvider));
});
