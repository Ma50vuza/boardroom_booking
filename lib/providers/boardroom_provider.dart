import 'package:flutter/foundation.dart';
import 'package:boardroom_booking/models/boardroom.dart';
import 'package:boardroom_booking/services/api_service.dart';

class BoardroomProvider with ChangeNotifier {
  List<Boardroom> _boardrooms = [];
  bool _isLoading = false;
  String? _error;

  List<Boardroom> get boardrooms => _boardrooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> createBooking({
    required String boardroomId,
    required DateTime startTime,
    required DateTime endTime,
    required String purpose,
    List<Map<String, String>>? externalAttendees,
    String? notes,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.createBooking(
        boardroomId: boardroomId,
        startTime: startTime,
        endTime: endTime,
        purpose: purpose,
        externalAttendees: externalAttendees,
        notes: notes,
      );

      if (result['success']) {
        _setLoading(false);
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to create booking: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchBoardrooms() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.getBoardrooms();

      if (result['success']) {
        _boardrooms = (result['data'] as List)
            .map((json) => Boardroom.fromJson(json))
            .toList();
      } else {
        _setError(result['message']);
      }
    } catch (e) {
      _setError('Failed to fetch boardrooms: ${e.toString()}');
    }

    _setLoading(false);
  }
}
