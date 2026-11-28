"use strict";

const assert = require("node:assert/strict");
const { after, test } = require("node:test");

const emulatorEnabled = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
let app;
let db;
let FieldValue;
const { createNotificationOnce } = require("../notification_writer");

if (emulatorEnabled) {
  const { initializeApp } = require("firebase-admin/app");
  const { FieldValue: firestoreFieldValue, getFirestore } = require("firebase-admin/firestore");
  FieldValue = firestoreFieldValue;
  app = initializeApp(
    { projectId: process.env.GCLOUD_PROJECT || "demo-irshogram-rules" },
    `irshogram-notification-writer-tests-${process.pid}`,
  );
  db = getFirestore(app);
}

after(async () => {
  if (app) await app.delete();
});

test(
  "a retried notification event never resets an already-read notification",
  { skip: !emulatorEnabled },
  async () => {
    const recipientId = `retry-recipient-${Date.now()}-${process.pid}`;
    const eventId = `event-${Date.now()}-${process.pid}`;
    const recipientRef = db.collection("users").doc(recipientId);
    const payload = {
      type: "like",
      actorId: "actor",
      recipientId,
      postId: "post-1",
      read: false,
    };

    const firstWrite = await createNotificationOnce({
      db,
      recipientRef,
      eventId,
      payload,
      serverTimestamp: () => FieldValue.serverTimestamp(),
    });
    assert.equal(firstWrite, true);

    const notificationRef = recipientRef.collection("notifications").doc(eventId);
    await notificationRef.update({ read: true });

    const retryWrite = await createNotificationOnce({
      db,
      recipientRef,
      eventId,
      payload,
      serverTimestamp: () => FieldValue.serverTimestamp(),
    });
    assert.equal(retryWrite, false);

    const saved = await notificationRef.get();
    assert.equal(saved.data().read, true);
    assert.equal(saved.data().actorId, "actor");
    assert.equal(saved.data().postId, "post-1");

    const notifications = await recipientRef.collection("notifications").get();
    assert.equal(notifications.size, 1);
  },
);
