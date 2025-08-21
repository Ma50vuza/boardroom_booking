import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boardroom_booking/providers/auth_provider.dart';
import 'package:boardroom_booking/providers/booking_provider.dart';
import 'package:boardroom_booking/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, int> _bookingStats = {
    'total': 0,
    'upcoming': 0,
    'completed': 0,
    'cancelled': 0,
  };
  DateTime? _lastBookingDate;

  @override
  void initState() {
    super.initState();
    _loadBookingStats();
  }

  void _loadBookingStats() {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final bookings = bookingProvider.userBookings;

    int total = bookings.length;
    int upcoming = bookings
        .where((b) =>
            b.isUpcoming && (b.status == 'confirmed' || b.status == 'pending'))
        .length;
    int completed =
        bookings.where((b) => b.isPast && b.status == 'confirmed').length;
    int cancelled = bookings.where((b) => b.status == 'cancelled').length;

    DateTime? lastDate;
    if (bookings.isNotEmpty) {
      lastDate = bookings
          .map((b) => b.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    setState(() {
      _bookingStats = {
        'total': total,
        'upcoming': upcoming,
        'completed': completed,
        'cancelled': cancelled,
      };
      _lastBookingDate = lastDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authProvider.user;
          if (user == null) {
            return const Center(
              child: Text('No user data available'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information Section
                _buildSectionCard(
                  title: 'Personal Information',
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.person,
                        label: 'Full Name',
                        value: user.name,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.email,
                        label: 'Email Address',
                        value: user.email,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.phone,
                        label: 'Phone Number',
                        value: '0788404160', // From your web data
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.business,
                        label: 'Department',
                        value: 'Development', // From your web data
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.work,
                        label: 'Position',
                        value: 'Mobile App Dev', // From your web data
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.location_on,
                        label: 'Office Location',
                        value: 'East London', // From your web data
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Account Status Section
                _buildSectionCard(
                  title: 'Account Status',
                  child: Column(
                    children: [
                      _buildStatusRow(
                        label: 'Role',
                        value: user.role.toUpperCase(),
                        valueColor: const Color(0xFF6366F1),
                        hasBackground: true,
                      ),
                      const SizedBox(height: 16),
                      _buildStatusRow(
                        label: 'Member Since',
                        value:
                            'Unknown', // You'd need to add this to User model
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Booking Statistics Section
                _buildSectionCard(
                  title: 'Booking Statistics',
                  child: Column(
                    children: [
                      _buildStatRow(
                        icon: Icons.calendar_today,
                        label: 'Total Bookings',
                        value: _bookingStats['total'].toString(),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        icon: Icons.upcoming,
                        label: 'Upcoming',
                        value: _bookingStats['upcoming'].toString(),
                        valueColor: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        icon: Icons.check_circle,
                        label: 'Completed',
                        value: _bookingStats['completed'].toString(),
                        valueColor: const Color(0xFF6B7280),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        icon: Icons.cancel,
                        label: 'Cancelled',
                        value: _bookingStats['cancelled'].toString(),
                        valueColor: const Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusRow(
                        label: 'Last Booking',
                        value: _lastBookingDate != null
                            ? _formatDate(_lastBookingDate!)
                            : 'No bookings yet',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isRequired = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    Color? valueColor,
    bool hasBackground = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        hasBackground
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (valueColor ?? Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ],
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: valueColor ?? Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
