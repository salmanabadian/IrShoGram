"use strict";

const { initializeApp } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

const { buildNotification } = require("./notification_payload");
const { createNotificationOnce } = require("./notification_writer");

initializeApp();

const db = getFirestore();

async function createRecipientNotification(event, details) {
  const payload = buildNotification(details);
  if (!payload || typeof event.id !== "string" || event.id.length === 0) {
    return;
  }

  const recipientRef = db.collection("users").doc(payload.recipientId);
  const recipient = await recipientRef.get();
  if (!recipient.exists) {
    return;
  }

  // A retry must not reset the recipient's read state. The writer transaction
  // creates the event document once and leaves an existing notification intact.
  await createNotificationOnce({
    db,
    recipientRef,
    eventId: event.id,
    payload,
    serverTimestamp: () => FieldValue.serverTimestamp(),
  });
}

exports.notifyPostLike = onDocumentCreated(
  { document: "posts/{postId}/likes/{actorId}", retry: true },
  async (event) => {
    const postSnapshot = await db.collection("posts").doc(event.params.postId).get();
    const post = postSnapshot.data();
    if (!post || typeof post.authorId !== "string") {
      return;
    }

    await createRecipientNotification(event, {
      actorId: event.params.actorId,
      recipientId: post.authorId,
      type: "like",
      postId: event.params.postId,
    });
  },
);

exports.notifyPostComment = onDocumentCreated(
  { document: "posts/{postId}/comments/{commentId}", retry: true },
  async (event) => {
    const comment = event.data?.data();
    if (!comment || typeof comment.authorId !== "string") {
      return;
    }

    const postSnapshot = await db.collection("posts").doc(event.params.postId).get();
    const post = postSnapshot.data();
    if (!post || typeof post.authorId !== "string") {
      return;
    }

    await createRecipientNotification(event, {
      actorId: comment.authorId,
      recipientId: post.authorId,
      type: "comment",
      postId: event.params.postId,
    });
  },
);

exports.notifyNewFollower = onDocumentCreated(
  { document: "users/{followerUid}/following/{targetUid}", retry: true },
  async (event) => {
    const following = event.data?.data();
    if (!following || following.targetUid !== event.params.targetUid) {
      return;
    }

    await createRecipientNotification(event, {
      actorId: event.params.followerUid,
      recipientId: event.params.targetUid,
      type: "follow",
    });
  },
);
