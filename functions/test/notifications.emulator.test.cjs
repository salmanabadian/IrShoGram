"use strict";

const assert = require("node:assert/strict");
const { after, test } = require("node:test");

const emulatorEnabled = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
let app;
let db;

if (emulatorEnabled) {
  const { initializeApp } = require("firebase-admin/app");
  const { getFirestore } = require("firebase-admin/firestore");

  app = initializeApp(
    { projectId: process.env.GCLOUD_PROJECT || "demo-irshogram-rules" },
    `irshogram-notification-tests-${process.pid}`,
  );
  db = getFirestore(app);
}

const suffix = `${Date.now()}-${process.pid}`;

async function waitForNotification(recipientId, filters) {
  const startedAt = Date.now();
  while (Date.now() - startedAt < 15000) {
    let query = db
      .collection("users")
      .doc(recipientId)
      .collection("notifications");
    for (const [field, value] of Object.entries(filters)) {
      query = query.where(field, "==", value);
    }
    const result = await query.limit(1).get();
    if (!result.empty) return result.docs[0].data();
    await new Promise((resolve) => setTimeout(resolve, 150));
  }
  throw new Error("Timed out waiting for the notification trigger.");
}

after(async () => {
  if (app) await app.delete();
});

test(
  "a post like creates one recipient notification in the Firestore emulator",
  { skip: !emulatorEnabled },
  async () => {
    const actorId = `like-actor-${suffix}`;
    const recipientId = `like-owner-${suffix}`;
    const postId = `like-post-${suffix}`;

    await db.collection("users").doc(actorId).set({ uid: actorId });
    await db.collection("users").doc(recipientId).set({ uid: recipientId });
    await db.collection("posts").doc(postId).set({ authorId: recipientId });
    await db.collection("posts").doc(postId).collection("likes").doc(actorId).set({
      createdAt: new Date(),
    });

    const notification = await waitForNotification(recipientId, {
      type: "like",
      actorId,
      postId,
    });
    assert.equal(notification.recipientId, recipientId);
    assert.equal(notification.read, false);
    assert.ok(notification.createdAt);
  },
);

test(
  "a post comment creates a recipient notification in the Firestore emulator",
  { skip: !emulatorEnabled },
  async () => {
    const actorId = `comment-actor-${suffix}`;
    const recipientId = `comment-owner-${suffix}`;
    const postId = `comment-post-${suffix}`;

    await db.collection("users").doc(actorId).set({ uid: actorId });
    await db.collection("users").doc(recipientId).set({ uid: recipientId });
    await db.collection("posts").doc(postId).set({ authorId: recipientId });
    await db.collection("posts").doc(postId).collection("comments").add({
      authorId: actorId,
      text: "A test comment",
      createdAt: new Date(),
    });

    const notification = await waitForNotification(recipientId, {
      type: "comment",
      actorId,
      postId,
    });
    assert.equal(notification.recipientId, recipientId);
    assert.equal(notification.read, false);
  },
);

test(
  "a new following relationship creates a recipient notification in the Firestore emulator",
  { skip: !emulatorEnabled },
  async () => {
    const actorId = `follow-actor-${suffix}`;
    const recipientId = `follow-target-${suffix}`;

    await db.collection("users").doc(actorId).set({ uid: actorId });
    await db.collection("users").doc(recipientId).set({ uid: recipientId });
    await db.collection("users").doc(actorId)
      .collection("following")
      .doc(recipientId)
      .set({ targetUid: recipientId, createdAt: new Date() });

    const notification = await waitForNotification(recipientId, {
      type: "follow",
      actorId,
    });
    assert.equal(notification.recipientId, recipientId);
    assert.equal(notification.read, false);
  },
);
