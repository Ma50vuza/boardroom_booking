import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boardroom_booking/models/booking.dart';
import 'package:boardroom_booking/widgets/custom_text_field.dart';
import 'package:boardroom_booking/providers/booking_provider.dart';

class EditBookingScreen extends StatefulWidget {
  final Booking booking;

  const EditBookingScreen({
    super.key,
    required this.booking,
  });

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _externalEmailController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<Map<String, String>> _externalAttendees = [];
  List<Map<String, dynamic>> _internalAttendees = [];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _purposeController.text = widget.booking.purpose;
    _selectedDate = widget.booking.date;

    // Copy existing external attendees
    _externalAttendees =
        List<Map<String, String>>.from(widget.booking.externalAttendees);

    // Copy existing internal attendees as editable list
    _internalAttendees = widget.booking.attendees
        .map((user) => {
              'id': user.id,
              'name': user.name,
              'email': user.email,
              'role': user.role,
            })
        .toList();

    _startTime = _parseTimeString(widget.booking.startTime);
    _endTime = _parseTimeString(widget.booking.endTime);
  }

  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _externalEmailController.dispose();
    super.dispose();
  }

  void _addExternalAttendee() {
    if (_externalEmailController.text.trim().isEmpty) return;

    final email = _externalEmailController.text.trim();

    // Check if email is already added in external attendees
    if (_externalAttendees.any((attendee) => attendee['email'] == email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This attendee is already added')),
      );
      return;
    }

    // Check if email is already added in internal attendees
    if (_internalAttendees.any((attendee) => attendee['email'] == email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This attendee is already added')),
      );
      return;
    }

    // For now, add as external attendee. In a full implementation,
    // we would check if this email belongs to a registered user first
    setState(() {
      _externalAttendees.add({
        'email': email,
        'name': email.split('@')[0],
      });
      _externalEmailController.clear();
    });
  }

  void _removeExternalAttendee(int index) {
    setState(() {
      _externalAttendees.removeAt(index);
    });
  }

  void _removeInternalAttendee(int index) {
    setState(() {
      _internalAttendees.removeAt(index);
    });
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
      });
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
        if (_endTime != null) {
          final hours = picked.hour + 1;
          _endTime =
              TimeOfDay(hour: hours > 23 ? 23 : hours, minute: picked.minute);
        }
      });
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
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = picked.hour * 60 + picked.minute;

      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }

      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _updateBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    final success = await bookingProvider.updateBooking(
      bookingId: widget.booking.id,
      date: _selectedDate!,
      startTime: _formatTime(_startTime!),
      endTime: _formatTime(_endTime!),
      purpose: _purposeController.text.trim(),
      attendees: 1, // Keep for now, will be handled by the attendees list
      internalAttendees:
          _internalAttendees.map((a) => a['id'] as String).toList(),
      externalAttendees:
          _externalAttendees.isNotEmpty ? _externalAttendees : null,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.error ?? 'Failed to update booking'),
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
        title: const Text('Edit Booking'),
        actions: [
          Consumer<BookingProvider>(
            builder: (context, bookingProvider, child) {
              return TextButton(
                onPressed: bookingProvider.isLoading ? null : _updateBooking,
                child: bookingProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update',
                        style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Boardroom info (read-only)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.meeting_room, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.booking.boardroomName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Boardroom cannot be changed when editing',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
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
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  _selectedDate != null
                      ? _formatDate(_selectedDate!)
                      : 'Select date',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectDate,
              ),
            ),

            const SizedBox(height: 8),

            // Time Selection
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Start Time'),
                      subtitle: Text(
                        _startTime != null
                            ? _formatTime(_startTime!)
                            : 'Select time',
                      ),
                      onTap: _selectStartTime,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('End Time'),
                      subtitle: Text(
                        _endTime != null
                            ? _formatTime(_endTime!)
                            : 'Select time',
                      ),
                      onTap: _selectEndTime,
                    ),
                  ),
                ),
              ],
            ),

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

            const SizedBox(height: 24),

            // Attendees Section
            Text(
              'Attendees',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Internal Attendees (Editable)
            if (_internalAttendees.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          size: 20,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Internal Attendees (${_internalAttendees.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final entry in _internalAttendees.asMap().entries)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF6366F1).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (entry.value['email'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.value['email']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _removeInternalAttendee(entry.key),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Add attendees input
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _externalEmailController,
                    labelText: 'Add Attendees',
                    hintText: 'Enter email address',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _addExternalAttendee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),

            // External attendees list
            if (_externalAttendees.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'External Attendees (${_externalAttendees.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 14,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value['email'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _removeExternalAttendee(entry.key),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Update Button
            Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        bookingProvider.isLoading ? null : _updateBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: bookingProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Update Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
