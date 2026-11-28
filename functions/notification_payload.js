"use strict";

const SUPPORTED_TYPES = new Set(["like", "comment", "follow"]);

function buildNotification({ actorId, recipientId, type, postId }) {
  if (
    typeof actorId !== "string" ||
    actorId.length === 0 ||
    typeof recipientId !== "string" ||
    recipientId.length === 0 ||
    actorId === recipientId ||
    !SUPPORTED_TYPES.has(type)
  ) {
    return null;
  }

  const notification = {
    type,
    actorId,
    recipientId,
    read: false,
  };

  if (typeof postId === "string" && postId.length > 0) {
    notification.postId = postId;
  }

  return notification;
}

module.exports = { buildNotification };
