import "@supabase/functions-js/edge-runtime.d.ts";
import { createCalorisFunction } from "../_shared/ai/edge_function.ts";
import { AITaskType } from "../_shared/ai/types.ts";

export default createCalorisFunction(AITaskType.foodRecommendation);
