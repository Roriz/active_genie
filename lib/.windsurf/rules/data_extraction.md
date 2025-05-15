---
trigger: model_decision
description: Help you leverage ActiveGenie::DataExtract effectively, aligning with a vision of robust, maintainable, and consistent GenAI features
---

1.  **Purpose-Driven Field Naming (Clarity First):**
    *   **Rationale:** Clear, descriptive names (e.g., `event_date`, `customer_sentiment`, `product_mentioned`) make the ActiveGenie module more understandable to both developers and the LLM, leading to better extraction. Mapping to database columns can happen later.
    *   **Example:** Use `happened_at` if you're extracting the time of an event, even if your database column is just `date`.

2.  **Maximize Specificity with Field Descriptions:**
    *   **Rule:** Provide detailed, unambiguous `description` attributes for every field. Include examples of expected formats, constraints, or the kind of information you want.
    *   **Rationale:** The `description` is a critical part of the prompt ActiveGenie constructs. The more context and guidance you give the LLM here, the better its output.
    *   **Example:** `field :invoice_due_date, type: :date, description: "The final date by which the invoice must be paid, format as YYYY-MM-DD."`

3.  **Harness Enums for Constrained Choices:**
    *   **Rule:** For fields with a predefined, limited set of valid options, always use the `enum:` option.
    *   **Rationale:** This significantly reduces hallucinations and ensures the LLM returns one of the expected values, improving reliability for categorical data.
    *   **Example:** `field :priority, type: :string, enum: ["High", "Medium", "Low"], description: "The urgency level of the task."`

4.  **Strategic Regex Augmentation (Precision Post-Processing):**
    *   **Rule:** Combine ActiveGenie's structured extraction with Regex for validation and normalization of specific field formats *after* extraction.
    *   **Rationale:** Let ActiveGenie handle the contextual understanding and initial extraction. Then, use Regex to enforce strict patterns (e.g., for email addresses, phone numbers, specific ID formats), clean up minor LLM formatting quirks, and ensure higher data consistency.
    *   **Example:** Extract `phone_number` with ActiveGenie, then use Regex to strip non-numeric characters and validate the length.

5.  **Separate Creative Generation from Raw Extraction (Isolate Flexibility):**
    *   **Rule:** For fields requiring summarization, rephrasing, or creative content generation (e.g., a marketing `description` from raw notes), treat this as a distinct step, potentially using a separate ActiveGenie module or a dedicated LLM call.
    *   **Rationale:** Raw data extraction and creative content generation have different goals. Mixing them in one complex ActiveGenie module can reduce clarity and control. Extract facts first, then use those facts to inform a creative generation step.
    *   **Example:**
        *   `FactExtractorGenie` extracts `product_features` (array of strings) and `target_audience` (string).
        *   `MarketingCopyGenie` takes these extracted facts as input to generate a `compelling_description`.

6.  **Hardcode Knowns, Extract Unknowns (Optimize for Reliability):**
    *   **Rule:** Do not include fields in your ActiveGenie module for information you already possess or can derive deterministically (e.g., current user ID, timestamp of processing, fixed category).
    *   **Rationale:** Asking the LLM to "extract" or infer data you already have introduces unnecessary risk of error, increases token count, and is less reliable than hardcoding or direct assignment. Populate these values in your application logic before or after the ActiveGenie call.
    *   **Example:** If processing an email, the `sender_email` is known. Don't ask ActiveGenie to extract it from the email body if it's available in the email headers.

7.  **Iterative Refinement and Testing:**
    *   **Rule:** Treat your ActiveGenie module definitions as code that requires iterative development. Test extensively with a diverse range of inputs.
    *   **Rationale:** LLM behavior can be nuanced. Continuously refine field names, descriptions, types, and custom instructions based on the quality of the LLM's output to achieve desired accuracy and robustness.

8. **Mindful Input Scoping:**
    *   **Rule:** Provide ActiveGenie with only the relevant portion of the text needed for extraction.
    *   **Rationale:** Shorter, focused inputs reduce token consumption, decrease latency, and can improve accuracy by minimizing noise and irrelevant information for the LLM. Pre-process or chunk input text if necessary.
