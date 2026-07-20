# **Developer Notes: Recursive XY-Cut Parser Evolution**

An analysis of the codebase variations reveals a clear evolutionary path of a document segmentation engine. The developer is actively experimenting with solving two classic Document Image Analysis (DIA) problems:

1. **Line vs. Text Disambiguation:** How to programmatically remove structural separator lines without accidentally erasing dense text.  
2. **Scale-Invariant Recursion:** How to make the XY-cut algorithm work just as well on a massive full page as it does inside a tiny sub-bounding box.

Here is the chronological breakdown of the experiments and the core changes between them.

## **📝 Version Changelog & Evolution**

### **Version 1 & 2: The Ray-Casting Walker**

* **Core Concept:** Uses a "momentum-based ray-casting walker" (extractGlobalLines) to detect horizontal and vertical lines.  
* **Mechanism:** It shoots a ray across the image. If it hits thick ink (text), it loses "gap energy" rapidly. If it finds thin ink, it restores energy and continues tracking the line trajectory.  
* **Changes:** Establishes the baseline recursive tree structure (vertical\_group / horizontal\_group).

### **Version 3: Morphological Line Erasure**

* **Core Concept:** Abandons ray-casting for Morphological Cross-Axis thickness scanning.  
* **Mechanism:** It checks every pixel. To be a valid horizontal line, the vertical thickness at that X/Y coordinate must be very thin (e.g., \< 5px).  
* **Changes:** Adds UI controls for "Line Splice Parameters".

### **Version 4: The Texture Classifier 🌟 *(Highly Notable)***

* **Core Concept:** Introduces advanced heuristics to prevent text from being classified as structural lines.  
* **Mechanism:** Adds hasSolidCore (checks for a 1D pixel-perfect spine of ink) and isTextTexture (a stroke/edge counter).  
* **Changes:** The algorithm counts white-to-black transitions. Because a solid line is one continuous stroke, and a sentence of text contains dozens of strokes (letters), the algorithm successfully ignores text by identifying its "texture."

### **Version 5 & 6: Density-Based Line Validation**

* **Core Concept:** Simplifies the complex heuristics from Version 4\.  
* **Mechanism:** Removes the isTextTexture stroke counter. Instead, it relies on an overall bounding box density check (analyzeBlockDensity \>= 0.75).  
* **Changes:** Less computationally expensive, but potentially more prone to false positives on very dark, bold text compared to the texture classifier.

### **Version 7: Adaptive XY-Cut Engine 🌟 *(Highly Notable)***

* **Core Concept:** Removes the global line erasure entirely to focus strictly on improving the core XY-Cut algorithm.  
* **Mechanism:** Introduces an **Auto-Tune Engine**. Instead of relying on a hardcoded, global noise tolerance (e.g., 0.3%), the tolerance scales dynamically based on the local region's height/width (localVNoiseTol \= Math.max(0.003, Math.min(0.035, 14 / trimmed.h))).  
* **Changes:** Adds a "Reading Flow" vector visualizer.

### **Version 8: True Recursive Fundamentals**

* **Core Concept:** A cleaned-up, highly optimized version of the pure XY-Cut.  
* **Mechanism:** Focuses on perfect column and row partitioning without pre-processing trickery.  
* **Changes:** Refines the mock document generator to test a specific edge case: a centered page number that blocks a full-page vertical column cut, proving the fallback logic works.

## **🏆 Which is the Best / Most Worthy of Consideration?**

There is no single "perfect" version, as the best concepts are currently split across different files. However, **Version 4** and **Version 7** contain brilliant computer vision breakthroughs that should be merged into the ultimate application.

### **1\. The Stroke/Edge Texture Classifier (From Version 4\)**

Using the isTextTexture function to count white-to-black transitions is an incredibly elegant and computationally cheap heuristic. Distinguishing lines from text based on bounding-box aspect ratios often fails, but checking the "frequency" of the ink transitions guarantees that a string of words will never be mistaken for a table border.

### **2\. Local Adaptive Thresholding (From Version 7\)**

The logic introduced here—Math.min(0.035, 14 / trimmed.h)—is a massive architectural improvement. In recursive layout parsing, a global threshold that works for finding a 20px gap between columns on a 1600px page will completely fail when evaluating a 100px bounding box nested deep in the tree. By dynamically scaling the noise tolerance based on the current trimmed coordinate space, the algorithm achieves **scale invariance**.

### **💡 Recommendation for the Final Build**

The most robust parser would be a combination of the two:

1. Run the **Morphological Erasure with the Texture Classifier (v4)** first to safely strip out all tables, underlines, and separator graphics.  
2. Pass that cleanly erased image array into the **Adaptive XY-Cut Engine (v7)**, utilizing the dynamic scaling thresholds to accurately carve the remaining text blocks into a hierarchical tree.
