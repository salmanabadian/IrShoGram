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

test("attachment messages require a non-empty media URL", async () => {
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
  await assertSucceeds(setDoc(messageRef(alice, id, "image-message"), {
    senderId: "alice",
    text: "",
    mediaUrl: "https://firebasestorage.googleapis.com/v0/b/example/o/image.jpg",
    createdAt: serverTimestamp(),
    type: "image",
  }));
});
