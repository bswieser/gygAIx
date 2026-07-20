# **Developer Notes: Evolution of the Document Layout & Parsing Pipeline**

This document reviews the progression of a Python-based document analysis pipeline, tracing its evolution from simple computer vision heuristics to a complex multi-agent LLM/VLM system.

## **Evolutionary Stages**

The provided code snippets demonstrate a clear, iterative learning process, tackling the notoriously difficult problem of hierarchical document parsing (specifically, complex layouts like RPG manuals):

1. **The Heuristic Era (Versions 1-3)**  
   * **V1:** Basic Recursive XY-Cut. Uses OpenCV/NumPy to project ink density and slice the document horizontally and vertically.  
   * **V2:** Global Line Detection. Adds a pre-pass to find strict horizontal/vertical lines (like table borders) to stop recursive cuts from bleeding across boundaries, slicing intersecting blocks.  
   * **V3:** Tree Serialization. Adds JSON export of the hierarchical layout tree and cropped debugging grids. *Limitation: Only yields coordinates, no semantic understanding.*  
2. **The VLM Experimentation Era (Versions 4-6)**  
   * **V4 (Per-block Crop):** Passes every cropped block to a Vision-Language Model (VLM) for classification. *Limitation: Highly inefficient, loses global page context.*  
   * **V5 & V6 (Graph Preflight):** Attempts to feed the entire page image and a list of bounding boxes to an LLM to generate a "Reading Order Graph" in JSON. *Limitation: Hallucinates frequently and fails to handle complex multi-column reading orders based purely on XY coordinates.*  
3. **The Multi-Agent Pipeline Era (Versions 7-9)**  
   * **V7 & V8:** Splits the task between a VLM (Visual Triage) and a Text LLM (Graph Builder), followed by a final Micro-Crop OCR pass.  
   * **V8.5 (JSON Enforcement Mode):** Attempted to force the LLM to output a complex, nested JSON structure representing the reading order and layout tree. *Outcome: Broke. The LLM (qwen3-vl:8b) failed entirely, resulting in a CRITICAL empty output. The strict JSON constraint proved too brittle for complex document logic.*  
   * **V9 (OCR-First):** Reverses the logic—extracts text blindly first, then gives the LLM the text *and* coordinates to merge fractured paragraphs. *Limitation: LLMs struggle to output highly nested JSON graphs reliably without breaking syntax.*

## **🏆 The Standout Winner: The 4-Phase Linguistic Pipeline (Version 10\)**

The final version (representing the "Phase 4 Assembly" script) is by far the most robust, intelligent, and production-ready architecture. It successfully parses complex multi-column layouts where previous JSON-heavy approaches failed.

### **Why it is worthy of consideration:**

1. **Dynamic Prompting Routing:**  
   Instead of using a one-size-fits-all OCR prompt, it uses an initial visual triage pass to classify nodes. It then dynamically routes the crop to specialized prompts:  
   * *Art/Figures:* Gets an "Art Historian" prompt to generate descriptive text (\[Description: ...\]).  
   * *Tables:* Gets a strict Markdown table prompt.  
   * *Text:* Gets a standard OCR prompt.  
2. **Linguistic Reading Order (Context-Aware):**  
   Earlier versions tried to guess reading order based strictly on geometry (e.g., "this box is higher than that box"). Version 10 feeds the actual extracted OCR text into the LLM. This allows the LLM to read the *flow of sentences* to determine if a paragraph at the bottom of Column A continues at the top of Column B.  
3. **PSV over JSON for Graph Logic:**  
   LLMs notoriously fail at outputting large, complex JSON structures perfectly (missing commas, escaped quotes). Version 10 brilliant forces the LLM to output a Pipe-Separated Values (PSV/CSV) table (id|box\_2|label|relates\_to|next\_id). This is significantly cheaper on tokens and virtually eliminates parsing errors. *This directly solved the empty-output failures seen in V8.5.*  
4. **Linked-List Document Assembly:**  
   By forcing the LLM to output a next\_id, the script builds a linked list. The final step simply walks this list to assemble a perfectly linearized, chronological Markdown file, ready for RAG (Retrieval-Augmented Generation) or human reading.

### **Future Recommendations**

* **Parallelization:** In the Phase 2 OCR step of the winning script, the crops are processed sequentially. Wrapping this in asyncio or a ThreadPoolExecutor would drastically reduce processing time.  
* **Fallback Mechanisms:** Add a retry loop if the PSV table parsing detects malformed rows.
