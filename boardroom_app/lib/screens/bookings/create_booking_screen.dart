import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boardroom_booking/models/boardroom.dart';
import 'package:boardroom_booking/widgets/custom_text_field.dart';
import 'package:boardroom_booking/providers/booking_provider.dart';
import 'package:boardroom_booking/providers/boardroom_provider.dart';

class CreateBookingScreen extends StatefulWidget {
  final Boardroom? selectedBoardroom;

  const CreateBookingScreen({
    super.key,
    this.selectedBoardroom,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();
  final _externalEmailController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Boardroom? _selectedBoardroom;
  final List<Map<String, String>> _externalAttendees = [];
  bool _isCheckingAvailability = false;
  String? _availabilityMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedBoardroom = widget.selectedBoardroom;
    
    // Load boardrooms and auto-select the first one if none is selected
    if (widget.selectedBoardroom == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final boardroomProvider = Provider.of<BoardroomProvider>(context, listen: false);
        boardroomProvider.fetchBoardrooms().then((_) {
          if (boardroomProvider.boardrooms.isNotEmpty && mounted) {
            setState(() {
              _selectedBoardroom = boardroomProvider.boardrooms.first;
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    _externalEmailController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _availabilityMessage = null; // Clear previous message
      });
      
      // Check availability after selecting date (if time is already selected)
      if (_startTime != null && _endTime != null) {
        _checkAvailability();
      }
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        // Auto-set end time to 1 hour later
        final hours = picked.hour + 1;
        _endTime =
            TimeOfDay(hour: hours > 23 ? 23 : hours, minute: picked.minute);
        _availabilityMessage = null; // Clear previous message
      });
      
      // Check availability after auto-setting both times
      if (_selectedDate != null) {
        _checkAvailability();
      }
    }
  }

  Future<void> _selectEndTime() async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start time first')),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ??
          TimeOfDay(hour: _startTime!.hour + 1, minute: _startTime!.minute),
    );
    if (picked != null) {
      // Validate end time is after start time
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = picked.hour * 60 + picked.minute;

      if (endMinutes <= startMinutes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End time must be after start time')),
          );
        }
        return;
      }

      setState(() {
        _endTime = picked;
        _availabilityMessage = null; // Clear previous message
      });
      
      // Check availability after selecting end time
      _checkAvailability();
    }
  }

  void _addExternalAttendee() {
    if (_externalEmailController.text.isNotEmpty) {
      // Validate email format before adding
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_externalEmailController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _externalAttendees.add({
          'email': _externalEmailController.text.trim(),
          'name': _externalEmailController.text.split('@')[0],
        });
        _externalEmailController.clear();
      });
    }
  }

  void _removeExternalAttendee(int index) {
    setState(() {
      _externalAttendees.removeAt(index);
    });
  }

  Future<void> _checkAvailability() async {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      return;
    }

    setState(() {
      _isCheckingAvailability = true;
      _availabilityMessage = null;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      // Skip availability check if no boardroom is selected
      if (_selectedBoardroom == null) {
        setState(() {
          _availabilityMessage = 'Please select a boardroom first';
          _isCheckingAvailability = false;
        });
        return;
      }

      // Get boardroom bookings for the selected date
      final existingBookings = await bookingProvider.getBoardroomBookings(
        _selectedBoardroom!.id,
        startDate: _selectedDate,
        endDate: _selectedDate,
      );

      // Check for time conflicts
      final selectedStartMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final selectedEndMinutes = _endTime!.hour * 60 + _endTime!.minute;
      
      for (final booking in existingBookings) {
        // Skip cancelled bookings
        if (booking.status == 'cancelled') continue;
        
        // Check if booking is on the same date
        if (booking.date.year == _selectedDate!.year &&
            booking.date.month == _selectedDate!.month &&
            booking.date.day == _selectedDate!.day) {
          
          // Parse existing booking time
          final startParts = booking.startTime.split(':');
          final endParts = booking.endTime.split(':');
          final bookingStartMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final bookingEndMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
          
          // Check for overlap
          if (selectedStartMinutes < bookingEndMinutes && selectedEndMinutes > bookingStartMinutes) {
            setState(() {
              _availabilityMessage = '❌ Time slot conflicts with existing booking (${booking.startTime} - ${booking.endTime})';
            });
            break;
          }
        }
      }
      
      // If no conflicts found
      if (_availabilityMessage == null) {
        setState(() {
          _availabilityMessage = '✅ Time slot is available';
        });
      }
      
    } catch (e) {
      setState(() {
        _availabilityMessage = '⚠️ Unable to check availability. Please try again.';
      });
    } finally {
      setState(() {
        _isCheckingAvailability = false;
      });
    }
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    // Check for conflicts before booking
    if (_availabilityMessage != null && _availabilityMessage!.startsWith('❌')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot book - time slot is already taken'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if boardroom is selected
    if (_selectedBoardroom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for boardroom to load'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    // Re-check availability one more time before booking
    await _checkAvailability();
    if (_availabilityMessage != null && _availabilityMessage!.startsWith('❌')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot book - time slot is no longer available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Convert TimeOfDay to time strings (HH:mm format)
    final startTimeString = _formatTime(_startTime!);
    final endTimeString = _formatTime(_endTime!);

    final success = await bookingProvider.createBooking(
      boardroomId: _selectedBoardroom!.id,
      date: _selectedDate!,
      startTime: startTimeString,
      endTime: endTimeString,
      purpose: _purposeController.text.trim(),
      externalAttendees:
          _externalAttendees.isNotEmpty ? _externalAttendees : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.error ?? 'Failed to create booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedBoardroom != null
            ? 'Book ${_selectedBoardroom!.name}'
            : 'Create Booking'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Boardroom info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _selectedBoardroom == null 
                ? const Row(
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 16),
                      Text(
                        'Loading boardroom...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.meeting_room,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedBoardroom!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedBoardroom!.location,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.people, size: 16, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedBoardroom!.capacity} people',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Date & Time Selection
            Text(
              'Date & Time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Date Selection
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _selectedDate != null
                      ? _formatDate(_selectedDate!)
                      : 'Select date',
                  style: TextStyle(
                    color: _selectedDate != null ? Colors.black87 : Colors.grey[600],
                    fontWeight: _selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF6366F1)),
                onTap: _selectDate,
              ),
            ),

            const SizedBox(height: 8),

            // Time Selection
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: Color(0xFF6366F1),
                          size: 16,
                        ),
                      ),
                      title: const Text(
                        'Start Time',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        _startTime != null
                            ? _formatTime(_startTime!)
                            : 'Select time',
                        style: TextStyle(
                          color: _startTime != null ? Colors.black87 : Colors.grey[600],
                          fontWeight: _startTime != null ? FontWeight.w500 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      onTap: _selectStartTime,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: Color(0xFF6366F1),
                          size: 16,
                        ),
                      ),
                      title: const Text(
                        'End Time',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        _endTime != null
                            ? _formatTime(_endTime!)
                            : 'Select time',
                        style: TextStyle(
                          color: _endTime != null ? Colors.black87 : Colors.grey[600],
                          fontWeight: _endTime != null ? FontWeight.w500 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      onTap: _selectEndTime,
                    ),
                  ),
                ),
              ],
            ),

            // Availability Status
            if (_isCheckingAvailability || _availabilityMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _availabilityMessage != null && _availabilityMessage!.startsWith('✅')
                      ? Colors.green.withValues(alpha: 0.1)
                      : _availabilityMessage != null && _availabilityMessage!.startsWith('❌')
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _availabilityMessage != null && _availabilityMessage!.startsWith('✅')
                        ? Colors.green
                        : _availabilityMessage != null && _availabilityMessage!.startsWith('❌')
                            ? Colors.red
                            : Colors.blue,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (_isCheckingAvailability)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        _availabilityMessage != null && _availabilityMessage!.startsWith('✅')
                            ? Icons.check_circle
                            : _availabilityMessage != null && _availabilityMessage!.startsWith('❌')
                                ? Icons.error
                                : Icons.info,
                        size: 20,
                        color: _availabilityMessage != null && _availabilityMessage!.startsWith('✅')
                            ? Colors.green
                            : _availabilityMessage != null && _availabilityMessage!.startsWith('❌')
                                ? Colors.red
                                : Colors.blue,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isCheckingAvailability
                            ? 'Checking availability...'
                            : _availabilityMessage ?? '',
                        style: TextStyle(
                          color: _availabilityMessage != null && _availabilityMessage!.startsWith('✅')
                              ? Colors.green[700]
                              : _availabilityMessage != null && _availabilityMessage!.startsWith('❌')
                                  ? Colors.red[700]
                                  : Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Meeting Details
            Text(
              'Meeting Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _purposeController,
              labelText: 'Meeting Purpose',
              hintText: 'e.g., Team Planning Meeting',
              prefixIcon: Icons.business_center,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the meeting purpose';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _notesController,
              labelText: 'Notes (Optional)',
              hintText: 'e.g., Please prepare presentation screen',
              prefixIcon: Icons.note,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Attendees
            Text(
              'Attendees',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Add attendee form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add attendee email (optional)',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _externalEmailController,
                          labelText: 'Email',
                          hintText: 'attendee@company.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _addExternalAttendee,
                          icon: const Icon(Icons.add, color: Colors.white),
                          tooltip: 'Add Attendee',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Attendees list
            if (_externalAttendees.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Attendees (${_externalAttendees.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final entry in _externalAttendees.asMap().entries)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: Builder(
                          builder: (context) {
                            final index = entry.key;
                            final attendee = entry.value;
                            return Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (attendee['name']?[0] ?? 'A').toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attendee['name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        attendee['email'] ?? '',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeExternalAttendee(index),
                                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                  tooltip: 'Remove',
                                ),
                              ],
                            );
                          }
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Book Button
            Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: bookingProvider.isLoading ? null : _createBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: bookingProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Book Meeting Room',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
