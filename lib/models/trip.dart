import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String tripType;
  final String ownerUid;
  final List<String> collaborators;

  Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.tripType,
    required this.ownerUid,
    required this.collaborators,
  });

  factory Trip.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Trip(
      id:            doc.id,
      name:          d['name'] ?? '',
      destination:   d['destination'] ?? '',
      startDate:     (d['startDate'] as Timestamp).toDate(),
      endDate:       (d['endDate'] as Timestamp).toDate(),
      tripType:      d['tripType'] ?? 'Other',
      ownerUid:      d['ownerUid'] ?? '',
      collaborators: List<String>.from(d['collaborators'] ?? []),
    );
  }

  Map<String, dynamic> toMap(String uid) => {
    'name':          name,
    'destination':   destination,
    'startDate':     Timestamp.fromDate(startDate),
    'endDate':       Timestamp.fromDate(endDate),
    'tripType':      tripType,
    'ownerUid':      uid,
    'collaborators': [uid],
    'createdAt':     FieldValue.serverTimestamp(),
  };
}