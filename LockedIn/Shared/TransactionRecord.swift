//
//  TransactionRecord.swift
//  LockedIn
//
//  Codable version of Transaction for SharedState persistence.
//  Stored in App Groups for cross-process access.
//
//  Used by both main app and extensions. The Transaction type is only
//  available in the main app, so conversion methods are excluded from extensions.
//

import Foundation

struct TransactionRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let amount: Int
    let source: String
    let timestamp: Date

    init(id: UUID = UUID(), amount: Int, source: String, timestamp: Date) {
        self.id = id
        self.amount = amount
        self.source = source
        self.timestamp = timestamp
    }
}

// MARK: - Main App Only (Transaction conversion)
// These methods require the Transaction type which is only in the main app.
// Extensions don't need these - they work directly with TransactionRecord.

#if MAIN_APP
extension TransactionRecord {
    /// Convert to in-memory Transaction for UI display
    func toTransaction() -> Transaction {
        Transaction(
            id: id,
            amount: amount,
            source: source,
            timestamp: timestamp
        )
    }

    /// Create from an in-memory Transaction
    init(from transaction: Transaction) {
        self.id = transaction.id
        self.amount = transaction.amount
        self.source = transaction.source
        self.timestamp = transaction.timestamp
    }
}
#endif
