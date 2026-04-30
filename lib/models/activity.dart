import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String name;
  final String startTime;
  final String location;
  final double estimatedBudget;
  final String category;
  final String addedBy;

  Activity({
    required this.id,
    required this.name,
    required this.startTime,
    required this.location,
    required this.estimatedBudget,
    required this.category,
    required this.addedBy,
  });

  factory Activity.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Activity(
      id:              doc.id,
      name:            d['name'] ?? '',
      startTime:       d['startTime'] ?? '00:00',
      location:        d['location'] ?? '',
      estimatedBudget: (d['estimatedBudget'] ?? 0).toDouble(),
      category:        d['category'] ?? 'Other',
      addedBy:         d['addedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap(String uid) => {
    'name':            name,
    'startTime':       startTime,
    'location':        location,
    'estimatedBudget': estimatedBudget,
    'category':        category,
    'addedBy':         uid,
    'createdAt':       FieldValue.serverTimestamp(),
  };
}