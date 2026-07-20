# **Developer Notes: D\&D DMG Parsing & OCR Pipeline**

## **Overview of Experiments**

The provided codebase represents a highly iterative development process aimed at parsing complex tabletop RPG PDFs (specifically the Dungeon Master's Guide) into LLM-friendly Markdown and optimizing images for Vision-Language Models (VLMs).

The experiments can be grouped into three main categories:

1. **Docling JSON to Markdown (Text Pipeline)**  
2. **Table Extraction Refinement (Structural Logic)**  
3. **Image Optimization & Batching (Vision Pipeline)**

## **1\. Evolution of the Text Pipeline**

### **Version 1: The Monolithic Parser (Initial Script)**

* **Features:** End-to-end processing. Takes raw Docling JSON, runs an Ollama model (gemma4) to clean OCR text, extracts semantic metadata via Ollama, and converts the parsed nodes to Markdown.  
* **Table Handling:** Basic grid traversal.  
* **Flaws:** Monolithic design means if Markdown generation fails, you have to re-run the expensive LLM OCR cleaning.

### **Version 2 & 3: The Split Architecture**

* **Changes:** The monolithic script was split into two distinct phases.  
  * **Phase 1 (Enrichment):** Iterates through JSON, cleans text with Ollama, adds an ocr\_cleaned flag, and saves as \_enriched.json.  
  * **Phase 2 (Markdown Gen):** Takes the \_enriched.json and focuses purely on structural conversion and extracting semantic YAML frontmatter.  
* **Why this mattered:** This is a crucial architectural improvement. Caching the LLM outputs prevents redundant api calls during UI/formatting tweaks.

### **Version 4: Advanced Table Logic & Optimized OCR (The "Best" Text Script)**

* **Changes:** Brings OCR cleaning back into a unified script but adds significant optimizations.  
  * **OCR Optimization:** Detects purely numeric cells (e.g., "01-20") and skips the LLM call, massively speeding up table processing.  
  * **Table Collapsing:** Introduces collapse\_multicol\_table. RPG books frequently use multi-column tables to save space. This version detects repeating layouts and flattens them into a single, LLM-readable list.  
* **Verdict:** This is the most mature iteration of the standard Docling pipeline.

## **2\. Structural Experimentation: Geometric Tables**

### **Version 5: Rebuilding Tables from Bounding Boxes (Highly Notable)**

* **Changes:** Completely abandons Docling's internal table logic. Instead, it extracts the raw bbox (bounding box) coordinates of every text element on the page. It then uses mathematical clustering (via a y\_tolerance threshold) to group elements into rows, and sorts them horizontally into columns.  
* **Why it's notable:** PDF table extraction (even with AI tools) notoriously fails on edge cases. Building a geometric fallback is a brilliant, highly robust engineering choice.

## **3\. Vision & Image Pipeline**

### **Version 6 & 9: LLM Image Token Optimizer**

* **Changes:** A script (complete with a Gradio UI) designed to resize high-resolution (300 DPI) scans into token-efficient dimensions for Vision LLMs (like GPT-4o or LLaVA).  
* **Features:** Implements standard LLM vision tiling math (512x512 grids) to estimate token costs. Uses LANCZOS resampling to maintain text crispness.

### **Version 7 & 8: Batch Processor & Organizer**

* **Changes:** Automates the pipeline. Scans a directory for BOOKNAME-PAGE.png, creates organized subfolders (p-18/original, p-18/docling), moves files, and runs the image token optimizer. Safely handles cross-drive file migrations.  
* **Why it's notable:** This bridges the gap between single-file experimentation and bulk processing an entire 300-page book.

## **🏆 Key Highlights & Recommendations for the Final Pipeline**

### **1\. The Multi-Column Table Collapser (Strongly Recommended)**

**Where to find it:** The Version 4 script (collapse\_multicol\_table).

**Why use it:** LLMs hallucinate heavily when reading wide, multi-column tables (e.g., a d100 loot table split into 4 visual columns on a page). This script solves a major RAG (Retrieval-Augmented Generation) headache.

### **2\. The Geometric Table Fallback (Crucial Consideration)**

**Where to find it:** The rebuild\_table\_from\_docling\_json script.

**Why use it:** You should integrate this into your main pipeline as a try/except fallback. If Docling returns a garbled grid, trigger the bounding-box math to reconstruct the table visually.

### **3\. OCR Numeric Skips (Performance Win)**

**Where to find it:** The regex check if all(c in "0123456789-.,/%+\*() " for c in raw\_text):

**Why use it:** Sending single numbers to a local LLM for "grammar cleaning" is a massive waste of compute. This one line will likely cut your processing time in half for table-heavy pages.
