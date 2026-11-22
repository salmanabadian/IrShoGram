import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { after, before, beforeEach, test } from "node:test";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  deleteObject,
  getBytes,
  ref,
  uploadBytes,
} from "firebase/storage";

const projectId = "demo-irshogram-rules";
const smallImage = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
let testEnvironment;

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    storage: {
      rules: await readFile("storage.rules", "utf8"),
    },
  });
});

after(async () => {
  await testEnvironment?.cleanup();
});

beforeEach(async () => {
  await testEnvironment.clearStorage();
});

test("owners can upload images and videos only into their own media paths", async () => {
  const alice = testEnvironment.authenticatedContext("alice").storage();

  await assertSucceeds(uploadBytes(
    ref(alice, "users/alice/profile/avatar.jpg"),
    smallImage,
    { contentType: "image/jpeg" },
  ));
  await assertSucceeds(uploadBytes(
    ref(alice, "posts/alice/post.jpg"),
    smallImage,
    { contentType: "image/jpeg" },
  ));
  await assertSucceeds(uploadBytes(
    ref(alice, "stories/alice/story.mp4"),
    smallImage,
    { contentType: "video/mp4" },
  ));
  await assertSucceeds(uploadBytes(
    ref(alice, "reels/alice/reel.mp4"),
    smallImage,
    { contentType: "video/mp4" },
  ));
});

test("clients cannot upload media into another user's storage path", async () => {
  const alice = testEnvironment.authenticatedContext("alice").storage();

  await assertFails(uploadBytes(
    ref(alice, "users/bob/profile/avatar.jpg"),
    smallImage,
    { contentType: "image/jpeg" },
  ));
  await assertFails(uploadBytes(
    ref(alice, "posts/bob/post.jpg"),
    smallImage,
    { contentType: "image/jpeg" },
  ));
  await assertFails(uploadBytes(
    ref(alice, "stories/bob/story.mp4"),
    smallImage,
    { contentType: "video/mp4" },
  ));
  await assertFails(uploadBytes(
    ref(alice, "reels/bob/reel.mp4"),
    smallImage,
    { contentType: "video/mp4" },
  ));
});

test("media uploads reject unsupported MIME types and files at the size limit", async () => {
  const alice = testEnvironment.authenticatedContext("alice").storage();
  const oversizedImage = new Uint8Array(10 * 1024 * 1024);

  await assertFails(uploadBytes(
    ref(alice, "posts/alice/document.pdf"),
    smallImage,
    { contentType: "application/pdf" },
  ));
  await assertFails(uploadBytes(
    ref(alice, "users/alice/profile/oversized.jpg"),
    oversizedImage,
    { contentType: "image/jpeg" },
  ));
  await assertFails(uploadBytes(
    ref(alice, "reels/alice/not-a-video.jpg"),
    smallImage,
    { contentType: "image/jpeg" },
  ));
});

test("only authenticated users can read social media, and only owners can delete it", async () => {
  const path = "posts/alice/shared.jpg";
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), path), smallImage, {
      contentType: "image/jpeg",
    });
  });

  const alice = testEnvironment.authenticatedContext("alice").storage();
  const bob = testEnvironment.authenticatedContext("bob").storage();
  const anonymous = testEnvironment.unauthenticatedContext().storage();

  await assertSucceeds(getBytes(ref(alice, path)));
  // Public social-media reads are currently available to signed-in users.
  // Private-account media authorization remains a separate unfinished task.
  await assertSucceeds(getBytes(ref(bob, path)));
  await assertFails(getBytes(ref(anonymous, path)));
  await assertFails(deleteObject(ref(bob, path)));
  await assertSucceeds(deleteObject(ref(alice, path)));
});
