"use strict";

const assert = require("node:assert/strict");
const { test } = require("node:test");

const { buildNotification } = require("../notification_payload");

test("builds a minimal like notification with the expected recipient and post", () => {
  assert.deepEqual(
    buildNotification({
      actorId: "bob",
      recipientId: "alice",
      type: "like",
      postId: "post-1",
    }),
    {
      type: "like",
      actorId: "bob",
      recipientId: "alice",
      read: false,
      postId: "post-1",
    },
  );
});

test("builds follow notifications without a post reference", () => {
  assert.deepEqual(
    buildNotification({
      actorId: "bob",
      recipientId: "alice",
      type: "follow",
    }),
    {
      type: "follow",
      actorId: "bob",
      recipientId: "alice",
      read: false,
    },
  );
});

test("suppresses self-notifications, missing identities, and unsupported types", () => {
  assert.equal(
    buildNotification({ actorId: "alice", recipientId: "alice", type: "like" }),
    null,
  );
  assert.equal(
    buildNotification({ actorId: "", recipientId: "alice", type: "follow" }),
    null,
  );
  assert.equal(
    buildNotification({ actorId: "bob", recipientId: "", type: "follow" }),
    null,
  );
  assert.equal(
    buildNotification({ actorId: "bob", recipientId: "alice", type: "mention" }),
    null,
  );
});
