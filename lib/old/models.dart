class Flight {
  final int id;
  final String name;
  final String origin;
  final String destination;
  final double price;

  Flight({required this.id, required this.name, required this.origin, required this.destination, required this.price});
}

class Booking {
  final int id;
  final String userId;
  final int flightId;
  final String status;

  Booking({required this.id, required this.userId, required this.flightId, required this.status});
}

class Transaction {
  final int id;
  final String userId;
  final double amount;
  final String status;

  Transaction({required this.id, required this.userId, required this.amount, required this.status});
}

