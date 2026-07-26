# **Mold: Density Engine Architecture & Evolution**

This document serves as both a theoretical primer on the density engine's architecture and a historical analysis of its evolution across recent iterations (Bayes 3 through Bayes 7).

## **Part 1: What the Experiment is and Why (Programmer Notes)**

### **The Core Premise: Why do this?**

Traditional layout analysis (like rigid XY-cuts or heavy ML models like LayoutLM) often struggles with organic, messy, or highly variable document structures. They rely on strict rules about white space or require massive compute.

This engine treats document layout as a **biological/physics simulation**. By leveraging fast localized math (Integral Images) and cellular automata principles, the engine organically "discovers" the layout structure based entirely on ink density, regardless of font size, language, or rigid grid rules.

### **Phase 1: The "Mold" Growth (Why White and Dark Mold?)**

Instead of doing traditional edge detection or contour finding, the engine uses a competing region-growing algorithm (similar to a watershed transformation).

* **The "Dark Mold" (Black Queue):** Seeded in areas of high ink density. It wants to consume all contiguous dense pixels (text, images, graphics).  
* **The "White Mold" (White Queue):** Seeded in empty areas. It wants to consume all empty space (margins, gutters, padding).  
* **Why do it this way?** By letting these two forces compete pixel-by-pixel outward from their seed points, they naturally collide at the exact visual boundaries of content. It gracefully handles noise, bleed-through, and irregular shapes without needing a hardcoded definition of "what is a margin."

### **Phase 2: Rectangle Stretching (Why the Physics Engine?)**

Once the dark mold has consumed the ink, we extract the resulting blobs. However, these blobs are irregular and heavily fragmented (e.g., every word or line might be its own blob). Modern UIs and LLMs need structured, consolidated bounding boxes.

* **The Physics Tick:** We wrap every atomic blob in a tight bounding box, then apply continuous outward "pressure" (growL, growR, growT, growB). The boxes stretch pixel-by-pixel until they hit the page edge or collide with another box.  
* **Why stretch them?** This process **tessellates** the 2D space. It guarantees that every single pixel on the page is claimed by a specific semantic block. It organically groups nearby fragments (like lines of text snapping together to form a paragraph) by closing the micro-gaps between them. It turns a complex raster pixel problem into a simple vector collision problem.

### **Phase 3: Semantic Routing & Merging**

Once the space is tessellated, we are left with a grid of boxes. We then evaluate the original ink density beneath each box to classify it (e.g., \>35% density \= Image; 7-35% \= Text; sparse \= Table) and run specific merge heuristics to stitch them into logical reading blocks.

## **Part 2: Changes Over Time (Version Comparison)**

After analyzing the three source files, **File 1** is clearly the most advanced iteration ("Bayes 7"), featuring the two-stage Bayesian routing system, while **File 3** is the earliest primitive experiment.

The good news is that **no core foundational functionality was dropped**. The underlying physics engine, integral image calculations, and structural loops remain completely intact. Here is a breakdown of how the core features evolved.

### **1\. Core Continuity (Safely Preserved)**

* **The Physics Engine:** The mold growth algorithm (PIXELS\_PER\_FRAME, 8-way directional expansion, and the queue processing logic) is identical across all versions.  
* **Pre-Merge "Splinter" Fix:** File 3 explicitly introduced a "RESTORED OPTIMIZATION: Overlap Pre-Merge" loop to prevent text paragraphs from splintering horizontally. **This is safely preserved in File 1** inside the btnVectorize click handler (while(initialMerging)).  
* **Image Thresholding & Density Profiling:** Otsu thresholding and the getBrushDensity integral image lookups remain untouched and highly performant.

### **2\. Architectural Upgrades (File 3 → File 1\)**

* **Dynamic Master Combine:** File 3 hardcoded the heuristics for merging (e.g., semantic density threshold of 0.06, orphan area ratio of 0.25). File 1 maps these to the Stage 2 Bayes selection (Aggressive \= 0.15 / 0.50, Light \= 0.06 / 0.25), allowing the engine to adapt to different layouts rather than forcing a one-size-fits-all approach.  
* **Workflow Interruption (Bayes Routing):** File 3 automated the entire process, dumping the user at the final state. File 1 halts the pipeline at Stage 1 (Page Profiling) and Stage 2 (Tessellation) to allow the Bayes model to ingest feature counts and prompt the human-in-the-loop for routing.  
* **Banding/Tri-Split Evolution:**  
  * *File 3:* Used rigid, raw block counts to guess 1/3 and 2/3 fractional cuts.  
  * *File 2:* Upgraded to an "Elastic Snap-to-Edge" logic evaluating bounding box intersections.  
  * *File 1:* Completely replaced with a **Density-Based Gutter Search** (sweeping a 4px beam to find physical paths of least resistance).

### **3\. Potential Regressions & Risk Areas (To Watch)**

While no code was "lost" by accident, the evolution of certain algorithms means some edge cases might behave worse in File 1 than they did in File 2 or 3:

* **The Gutter Search Risk (Tri-Split):** File 1 sweeps a 4px line to find white space for its bands. If you process a document with continuous vertical or horizontal lines (like a heavily bordered table or a page-length margin rule), the density sweep might fail to find a "clean" cut, returning high resistance. File 2's geometric snap logic (bounding boxes only) would have ignored thin graphical lines. *Recommendation: Keep an eye on how File 1 handles tables with solid borders.*  
* **Stage 2 Bayes UI Behavior:** In File 2, there is a comment: // DO NOT HIDE the panel so user can back out and try different strategies instantly\!. In File 1, this comment is gone, though the panel remains visible by omission of a hide command. Just ensure the UX still supports rapid swapping of strategies without resetting the canvas awkwardly.  
* **Sub-Average Sweep:** File 1 disables the "Sub-Average Sweep" (paragraph reassembly) if the Bayes router selects the "Light" strategy. If the Bayes model incorrectly predicts a heavy text document as "Light" (perhaps due to small brush size or high thresholds), paragraphs will remain heavily fragmented.

### **Conclusion**

You are safe to proceed with **File 1 (Bayes 7\)** as your primary branch. The heuristic logic hasn't been lost; it has simply been parameter-driven by the new Bayes state manager. The overarching goal of organic, physics-based layout discovery remains the driving force behind the architecture.
