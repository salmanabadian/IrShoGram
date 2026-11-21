import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { after, before, beforeEach, test } from "node:test";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from "firebase/firestore";

const projectId = "demo-irshogram-rules";
let testEnvironment;

function savedPostRef(database, ownerUid, postId = "post-1") {
  return doc(database, "users", ownerUid, "savedPosts", postId);
}

function conversationRef(database, firstUid = "alice", secondUid = "bob", id) {
  const participants = [firstUid, secondUid].sort();
  return doc(database, "conversations", id ?? participants.join("_"));
}

async function createConversation(database, firstUid = "alice", secondUid = "bob", id) {
  const participants = [firstUid, secondUid].sort();
  const reference = conversationRef(database, firstUid, secondUid, id);
  await setDoc(reference, {
    participantIds: participants,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  return reference;
}

function messageRef(database, conversationId, messageId = "message-1") {
  return doc(database, "conversations", conversationId, "messages", messageId);
}

function userRef(database, uid = "alice") {
  return doc(database, "users", uid);
}

function validUserProfile(uid = "alice") {
  return {
    uid,
    username: "alice_01",
    displayName: "Alice",
    bio: "Hello",
    photoUrl: "https://example.invalid/avatar.png",
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

function validPost(authorId = "alice") {
  return {
    authorId,
    caption: "A test post",
    mediaUrl: "https://firebasestorage.googleapis.com/v0/b/example/o/post.jpg",
    mediaType: "image",
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

function validStory(authorId = "alice") {
  return {
    authorId,
    mediaUrl: "https://firebasestorage.googleapis.com/v0/b/example/o/story.jpg",
    mediaType: "image",
    createdAt: serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + 60 * 60 * 1000),
  };
}

function validReel(authorId = "alice") {
  return {
    authorId,
    caption: "A test reel",
    mediaUrl: "https://firebasestorage.googleapis.com/v0/b/example/o/reel.mp4",
    createdAt: serverTimestamp(),
  };
}

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: await readFile("firestore.rules", "utf8"),
    },
  });
});

after(async () => {
  await testEnvironment?.cleanup();
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "posts", "post-1"), {
      authorId: "author-1",
      caption: "test post",
      mediaUrl: "https://example.invalid/post.jpg",
      mediaType: "image",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
  });
});

test("posts require complete owner-scoped metadata and a safe HTTPS media URL", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();
  const bob = testEnvironment.authenticatedContext("bob").firestore();
  const post = doc(alice, "posts", "valid-media-post");

  await assertSucceeds(setDoc(post, validPost()));
  await assertSucceeds(updateDoc(post, {
    caption: "Updated caption",
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(post, {
    mediaUrl: "https://firebasestorage.googleapis.com/v0/b/example/o/replaced.jpg",
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(bob, "posts", "spoofed-author"), validPost("alice")));

  const invalidUrls = [
    "",
    "http://example.invalid/post.jpg",
    "file:///data/local/post.jpg",
    "data:image/png;base64,AAAA",
    "https://",
    `https://example.invalid/${"x".repeat(2050)}`,
  ];
  for (let index = 0; index < invalidUrls.length; index += 1) {
    await assertFails(setDoc(
      doc(alice, "posts", `invalid-media-${index}`),
      { ...validPost(), mediaUrl: invalidUrls[index] },
    ));
  }

  await assertFails(setDoc(doc(alice, "posts", "missing-field"), {
    authorId: "alice",
    caption: "Missing media metadata",
    mediaUrl: "https://example.invalid/post.jpg",
    mediaType: "image",
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(alice, "posts", "unexpected-field"), {
    ...validPost(),
    localPath: "/private/device/path.jpg",
  }));
  await assertFails(setDoc(doc(alice, "posts", "invalid-type"), {
    ...validPost(),
    mediaType: "audio",
  }));
});

test("stories require safe media URLs, complete metadata, and a future expiry", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();
  const bob = testEnvironment.authenticatedContext("bob").firestore();

  await assertSucceeds(setDoc(doc(alice, "stories", "valid-story"), validStory()));
  await assertFails(setDoc(doc(bob, "stories", "spoofed-story"), validStory("alice")));
  await assertFails(setDoc(doc(alice, "stories", "unsafe-story-url"), {
    ...validStory(),
    mediaUrl: "file:///data/local/story.jpg",
  }));
  await assertFails(setDoc(doc(alice, "stories", "expired-story"), {
    ...validStory(),
    expiresAt: Timestamp.fromMillis(Date.now() - 60_000),
  }));
  await assertFails(setDoc(doc(alice, "stories", "extra-story-field"), {
    ...validStory(),
    devicePath: "/private/story.jpg",
  }));
});

test("reels require safe HTTPS media URLs and immutable media metadata", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();
  const bob = testEnvironment.authenticatedContext("bob").firestore();
  const reel = doc(alice, "reels", "valid-reel");

  await assertSucceeds(setDoc(reel, validReel()));
  await assertSucceeds(updateDoc(reel, { caption: "Updated reel caption" }));
  await assertFails(updateDoc(reel, {
    mediaUrl: "https://firebasestorage.googleapis.com/v0/b/example/o/other.mp4",
  }));
  await assertFails(setDoc(doc(bob, "reels", "spoofed-reel"), validReel("alice")));
  await assertFails(setDoc(doc(alice, "reels", "unsafe-reel-url"), {
    ...validReel(),
    mediaUrl: "http://example.invalid/reel.mp4",
  }));
  await assertFails(setDoc(doc(alice, "reels", "extra-reel-field"), {
    ...validReel(),
    localPath: "/private/device/reel.mp4",
  }));
});

test("following markers require a real target and a server timestamp", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();
  const bob = testEnvironment.authenticatedContext("bob").firestore();
  const following = doc(alice, "users", "alice", "following", "bob");

  await assertSucceeds(setDoc(userRef(alice), validUserProfile("alice")));
  await assertSucceeds(setDoc(userRef(bob, "bob"), validUserProfile("bob")));

  await assertFails(setDoc(following, { targetUid: "bob" }));
  await assertFails(setDoc(following, {
    targetUid: "bob",
    createdAt: Timestamp.fromMillis(0),
  }));
  await assertFails(setDoc(following, {
    targetUid: "bob",
    createdAt: serverTimestamp(),
    extra: true,
  }));
  await assertFails(setDoc(doc(alice, "users", "alice", "following", "charlie"), {
    targetUid: "charlie",
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(bob, "users", "alice", "following", "bob"), {
    targetUid: "bob",
    createdAt: serverTimestamp(),
  }));

  await assertSucceeds(setDoc(following, {
    targetUid: "bob",
    createdAt: serverTimestamp(),
  }));
});

test("likes require an existing post and an immutable server-created timestamp", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();
  const bob = testEnvironment.authenticatedContext("bob").firestore();
  const like = doc(alice, "posts", "post-1", "likes", "alice");

  await assertFails(setDoc(like, {}));
  await assertFails(setDoc(like, { createdAt: Timestamp.fromMillis(0) }));
  await assertFails(setDoc(like, {
    createdAt: serverTimestamp(),
    unexpected: true,
  }));
  await assertFails(setDoc(doc(alice, "posts", "missing-post", "likes", "alice"), {
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(bob, "posts", "post-1", "likes", "alice"), {
    createdAt: serverTimestamp(),
  }));

  await assertSucceeds(setDoc(like, { createdAt: serverTimestamp() }));
  await assertFails(updateDoc(like, { createdAt: serverTimestamp() }));
});

test("comments require complete owner metadata and a server timestamp", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();
  const bob = testEnvironment.authenticatedContext("bob").firestore();
  const comment = doc(alice, "posts", "post-1", "comments", "comment-1");

  await assertFails(setDoc(comment, {
    authorId: "alice",
    text: "Missing timestamp",
  }));
  await assertFails(setDoc(comment, {
    authorId: "alice",
    text: "Invalid timestamp",
    createdAt: Timestamp.fromMillis(0),
  }));
  await assertFails(setDoc(comment, {
    authorId: "alice",
    text: "Unexpected field",
    createdAt: serverTimestamp(),
    localDraft: true,
  }));
  await assertFails(setDoc(comment, {
    authorId: "bob",
    text: "Spoofed author",
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(alice, "posts", "missing-post", "comments", "comment-1"), {
    authorId: "alice",
    text: "Missing parent post",
    createdAt: serverTimestamp(),
  }));

  await assertSucceeds(setDoc(comment, {
    authorId: "alice",
    text: "A valid comment",
    createdAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(comment, { text: "Edited comment" }));
  await assertFails(updateDoc(comment, { authorId: "bob" }));
  await assertFails(updateDoc(comment, { createdAt: serverTimestamp() }));
});

test("a user can create a complete profile with validated fields and server timestamps", async () => {
  const database = testEnvironment.authenticatedContext("alice").firestore();
  const reference = userRef(database);

  await assertSucceeds(setDoc(reference, validUserProfile()));
  const profile = await assertSucceeds(getDoc(reference));
  assert.equal(profile.data().uid, "alice");
  assert.equal(profile.data().username, "alice_01");
});

test("profile creation rejects another user's path and invalid or unexpected fields", async () => {
  const database = testEnvironment.authenticatedContext("alice").firestore();

  await assertFails(setDoc(userRef(database, "bob"), validUserProfile("bob")));

  const invalidProfiles = [
    { ...validUserProfile(), username: "" },
    { ...validUserProfile(), username: "ab" },
    { ...validUserProfile(), username: "name with spaces" },
    { ...validUserProfile(), username: "u".repeat(31) },
    { ...validUserProfile(), displayName: "" },
    { ...validUserProfile(), bio: "b".repeat(301) },
    { ...validUserProfile(), photoUrl: "http://example.invalid/avatar.png" },
    { ...validUserProfile(), photoUrl: "https://" },
    { ...validUserProfile(), unexpected: true },
    { ...validUserProfile(), createdAt: Timestamp.fromMillis(0) },
  ];

  for (const profile of invalidProfiles) {
    await assertFails(setDoc(userRef(database), profile));
  }
});

test("profile updates preserve ownership and creation time and require a server update timestamp", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();
  const bob = testEnvironment.authenticatedContext("bob").firestore();
  const reference = userRef(alice);

  await assertSucceeds(setDoc(reference, validUserProfile()));
  await assertSucceeds(updateDoc(reference, {
    displayName: "Alice Updated",
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, {
    username: "",
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, {
    uid: "bob",
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, {
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, {
    updatedAt: Timestamp.fromMillis(0),
  }));
  await assertFails(updateDoc(userRef(bob, "alice"), {
    displayName: "Changed by another user",
    updatedAt: serverTimestamp(),
  }));
});

test("an owner can create and read a saved-post marker", async () => {
  const database = testEnvironment.authenticatedContext("alice").firestore();
  const reference = savedPostRef(database, "alice");

  await assertSucceeds(setDoc(reference, { savedAt: serverTimestamp() }));
  const saved = await assertSucceeds(getDoc(reference));
  assert.equal(saved.exists(), true);
});

test("a different signed-in user cannot read or write another user's saved posts", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();
  const bob = testEnvironment.authenticatedContext("bob").firestore();
  const aliceReference = savedPostRef(alice, "alice");

  await assertSucceeds(setDoc(aliceReference, { savedAt: serverTimestamp() }));
  await assertFails(getDoc(savedPostRef(bob, "alice")));
  await assertFails(setDoc(savedPostRef(bob, "alice"), {
    savedAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(savedPostRef(bob, "alice")));
});

test("saved-post creation rejects extra fields and future timestamps", async () => {
  const database = testEnvironment.authenticatedContext("alice").firestore();

  await assertFails(setDoc(savedPostRef(database, "alice"), {
    savedAt: serverTimestamp(),
    note: "unexpected client data",
  }));
  await assertFails(setDoc(savedPostRef(database, "alice"), {
    savedAt: Timestamp.fromMillis(Date.now() + 60_000),
  }));
});

test("a user cannot save a post document that does not exist", async () => {
  const database = testEnvironment.authenticatedContext("alice").firestore();

  await assertFails(setDoc(savedPostRef(database, "alice", "missing-post"), {
    savedAt: serverTimestamp(),
  }));
});

test("saved-post markers cannot be updated but can be deleted by their owner", async () => {
  const database = testEnvironment.authenticatedContext("alice").firestore();
  const reference = savedPostRef(database, "alice");

  await assertSucceeds(setDoc(reference, { savedAt: serverTimestamp() }));
  await assertFails(updateDoc(reference, { savedAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(reference));
});

test("unauthenticated clients cannot read or create saved-post markers", async () => {
  const database = testEnvironment.unauthenticatedContext().firestore();

  await assertFails(getDoc(savedPostRef(database, "alice")));
  await assertFails(setDoc(savedPostRef(database, "alice"), {
    savedAt: serverTimestamp(),
  }));
});


test("a conversation can only be created with two sorted participants and its canonical ID", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();

  await assertSucceeds(createConversation(alice));
  await assertFails(setDoc(doc(alice, "conversations", "alice"), {
    participantIds: ["alice"],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(alice, "conversations", "alice_bob_charlie"), {
    participantIds: ["alice", "bob", "charlie"],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(alice, "conversations", "wrong-id"), {
    participantIds: ["alice", "bob"],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(alice, "conversations", "bob_alice"), {
    participantIds: ["bob", "alice"],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
});

test("only conversation participants can read the conversation and its messages", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();
  const bob = testEnvironment.authenticatedContext("bob").firestore();
  const charlie = testEnvironment.authenticatedContext("charlie").firestore();
  const conversation = await createConversation(alice);
  const id = conversation.id;
  const message = messageRef(alice, id);

  await assertSucceeds(getDoc(conversationRef(bob)));
  await assertFails(getDoc(conversationRef(charlie)));
  await assertSucceeds(setDoc(message, {
    senderId: "alice",
    text: "Hello",
    mediaUrl: null,
    createdAt: serverTimestamp(),
    type: "text",
  }));
  await assertSucceeds(getDoc(messageRef(bob, id)));
  await assertFails(getDoc(messageRef(charlie, id)));
  await assertFails(setDoc(messageRef(charlie, id, "outsider-message"), {
    senderId: "charlie",
    text: "Not a participant",
    mediaUrl: null,
    createdAt: serverTimestamp(),
    type: "text",
  }));
});

test("direct messages reject sender spoofing, empty text, oversized text, and unknown types", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();
  const bob = testEnvironment.authenticatedContext("bob").firestore();
  const conversation = await createConversation(alice);
  const id = conversation.id;

  await assertFails(setDoc(messageRef(bob, id, "spoofed"), {
    senderId: "alice",
    text: "Spoofed sender",
    mediaUrl: null,
    createdAt: serverTimestamp(),
    type: "text",
  }));
  await assertFails(setDoc(messageRef(alice, id, "empty"), {
    senderId: "alice",
    text: "",
    mediaUrl: null,
    createdAt: serverTimestamp(),
    type: "text",
  }));
  await assertFails(setDoc(messageRef(alice, id, "oversized"), {
    senderId: "alice",
    text: "x".repeat(5001),
    mediaUrl: null,
    createdAt: serverTimestamp(),
    type: "text",
  }));
  await assertFails(setDoc(messageRef(alice, id, "unknown-type"), {
    senderId: "alice",
    text: "Hello",
    mediaUrl: null,
    createdAt: serverTimestamp(),
    type: "system",
  }));
});

test("attachment messages require a safe HTTPS media URL", async () => {
  const alice = testEnvironment.authenticatedContext("alice").firestore();
  const conversation = await createConversation(alice);
  const id = conversation.id;

  await assertFails(setDoc(messageRef(alice, id, "missing-media"), {
    senderId: "alice",
    text: "",
    mediaUrl: null,
    createdAt: serverTimestamp(),
    type: "image",
  }));

  const invalidUrls = [
    "",
    "http://example.invalid/image.jpg",
    "file:///data/local/image.jpg",
    "data:image/png;base64,AAAA",
    "https://",
  ];
  for (let index = 0; index < invalidUrls.length; index += 1) {
    await assertFails(setDoc(messageRef(alice, id, `invalid-media-${index}`), {
      senderId: "alice",
      text: "",
      mediaUrl: invalidUrls[index],
      createdAt: serverTimestamp(),
      type: "image",
    }));
  }

  await assertSucceeds(setDoc(messageRef(alice, id, "image-message"), {
    senderId: "alice",
    text: "",
    mediaUrl: "https://firebasestorage.googleapis.com/v0/b/example/o/image.jpg",
    createdAt: serverTimestamp(),
    type: "image",
  }));
});
