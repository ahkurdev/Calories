import { OpenRouterModelService } from "../ai/openrouter_model_service.ts";

const catalog = [
  {
    id: "paid/vision",
    architecture: { input_modalities: ["text", "image"] },
    pricing: { prompt: "0.0001", completion: "0", request: "0", image: "0" },
    supported_parameters: ["response_format"],
  },
  {
    id: "free/text",
    architecture: { input_modalities: ["text"] },
    pricing: { prompt: "0", completion: "0", request: "0", image: "0" },
    supported_parameters: ["structured_outputs"],
  },
  {
    id: "free/vision",
    architecture: { input_modalities: ["text", "image"] },
    pricing: { prompt: "0", completion: "0", request: "0", image: "0" },
    supported_parameters: ["response_format"],
  },
];

Deno.test("OpenRouter selection is free-only and vision-aware", () => {
  const service = new OpenRouterModelService(() => Promise.resolve(catalog));
  const models = service.selectFromCatalog(catalog, {
    visionRequired: true,
    allowedModels: [],
  });
  if (models.length !== 1 || models[0].id !== "free/vision") {
    throw new Error(`Unexpected models: ${JSON.stringify(models)}`);
  }
});

Deno.test("OpenRouter allowlist narrows dynamic free catalog", () => {
  const service = new OpenRouterModelService(() => Promise.resolve(catalog));
  const models = service.selectFromCatalog(catalog, {
    visionRequired: false,
    allowedModels: ["free/text"],
  });
  if (models.length !== 1 || models[0].id !== "free/text") {
    throw new Error("Allowlist was not applied");
  }
});
