import 'package:flutter/material.dart';
import 'package:boardroom_booking/models/boardroom.dart';
import 'package:boardroom_booking/screens/bookings/create_booking_screen.dart';

class BoardroomCard extends StatelessWidget {
  final Boardroom boardroom;

  const BoardroomCard({
    super.key,
    required this.boardroom,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
            ),
            child: boardroom.images.isNotEmpty
                ? Image.network(
                    boardroom.images.first.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.meeting_room,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : const Icon(
                    Icons.meeting_room,
                    size: 80,
                    color: Colors.grey,
                  ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        boardroom.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: boardroom.isActive
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        boardroom.isActive ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          fontSize: 12,
                          color: boardroom.isActive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      boardroom.location,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.people_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Capacity: ${boardroom.capacity} people',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                if (boardroom.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    boardroom.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Amenities
                if (boardroom.amenities.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: boardroom.amenities.take(3).map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          amenity,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 16),

                // Book Now Button (Full Width)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: boardroom.isActive
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CreateBookingScreen(
                                  selectedBoardroom: boardroom,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: boardroom.isActive
                          ? const Color(0xFF6366F1)
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      boardroom.isActive ? 'Book Now' : 'Unavailable',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
