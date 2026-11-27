"use strict";

/**
 * Creates a notification once for a CloudEvent ID.
 *
 * A trigger retry must not overwrite a notification that the recipient has
 * already read. The transaction makes the event ID an immutable idempotency
 * key: the first delivery creates the document; later deliveries leave it
 * untouched.
 */
async function createNotificationOnce({
  db,
  recipientRef,
  eventId,
  payload,
  serverTimestamp,
}) {
  if (
    !db ||
    !recipientRef ||
    typeof eventId !== "string" ||
    eventId.length === 0 ||
    !payload ||
    typeof serverTimestamp !== "function"
  ) {
    throw new TypeError("A database, recipient, event ID, payload, and server timestamp are required.");
  }

  const notificationRef = recipientRef.collection("notifications").doc(eventId);
  return db.runTransaction(async (transaction) => {
    const existing = await transaction.get(notificationRef);
    if (existing.exists) return false;

    transaction.create(notificationRef, {
      ...payload,
      createdAt: serverTimestamp(),
    });
    return true;
  });
}

module.exports = { createNotificationOnce };
