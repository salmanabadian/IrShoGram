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
