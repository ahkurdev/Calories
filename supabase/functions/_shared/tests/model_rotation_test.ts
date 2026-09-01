import {
  resetModelRotationForTests,
  rotatingModelWindow,
} from "../ai/model_rotation.ts";

Deno.test("model rotation changes the first model while preserving fallback order", () => {
  resetModelRotationForTests();
  const models = ["alpha", "beta", "gamma", "delta"];

  const first = rotatingModelWindow("provider:text", models, 3);
  const second = rotatingModelWindow("provider:text", models, 3);

  if (first.join(",") !== "alpha,beta,gamma") {
    throw new Error(`Unexpected first window: ${first}`);
  }
  if (second.join(",") !== "beta,gamma,delta") {
    throw new Error(`Unexpected second window: ${second}`);
  }
});

Deno.test("model rotation keeps capability pools independent", () => {
  resetModelRotationForTests();
  const models = ["alpha", "beta"];

  rotatingModelWindow("provider:text", models, 2);
  const vision = rotatingModelWindow("provider:vision", models, 2);

  if (vision.join(",") !== "alpha,beta") {
    throw new Error(`Capability pools leaked state: ${vision}`);
  }
});
