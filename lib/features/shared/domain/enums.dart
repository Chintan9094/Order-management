enum StaffRole { admin, manager, waiter, kitchen }

enum DiningSessionStatus { open, closed }

enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  served,
  completed,
  cancelled,
}

enum PaymentStatus { unpaid, paymentPending, paid }

/// Derived display status — not a primary write model.
enum TableDisplayStatus {
  available,
  occupied,
  orderPlaced,
  preparing,
  ready,
  paymentPending,
  paid,
  completed,
}

enum MenuItemDiet { veg, nonVeg, egg, vegan, unknown }
