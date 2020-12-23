package com.crescentflare.simplemarkdownparser.conversion;

import com.crescentflare.simplemarkdownparser.symbolfinder.MarkdownSymbol;
import com.crescentflare.simplemarkdownparser.tagfinder.MarkdownTag;
import com.crescentflare.simplemarkdownparser.tagfinder.ProcessedMarkdownTag;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Simple markdown parser library: text conversion
 * Helper class to filter out markdown symbols and return processed tags
 */
public class SimpleMarkdownTextProcessor {

    // --
    // Members
    // --

    @NotNull public String text = "";
    @NotNull public List<ProcessedMarkdownTag> tags = new ArrayList<>();
    private final List<MarkdownTag> originalTags;
    private final String originalText;
    private final MarkdownSpanGenerator spanGenerator;


    // --
    // Initialization
    // --

    private SimpleMarkdownTextProcessor(String text, List<MarkdownTag> tags, MarkdownSpanGenerator spanGenerator) {
        originalText = text;
        this.originalTags = tags;
        this.spanGenerator = spanGenerator;
    }


    // --
    // Processing
    // --

    public static SimpleMarkdownTextProcessor process(@NotNull String text, @NotNull List<MarkdownTag> tags) {
        return process(text, tags, null);
    }

    public static SimpleMarkdownTextProcessor process(@NotNull String text, @NotNull List<MarkdownTag> tags, @Nullable MarkdownSpanGenerator spanGenerator) {
        SimpleMarkdownTextProcessor instance = new SimpleMarkdownTextProcessor(text, tags, spanGenerator);
        instance.processInternal();
        return instance;
    }

    public void rearrangeNestedTextStyles() {
        List<ProcessedMarkdownTag> originalTags = tags;
        int scanPosition = 0;
        int alternativeScanPosition = 0;
        tags = new ArrayList<>();
        for (int index = 0; index < originalTags.size(); index++) {
            ProcessedMarkdownTag checkTag = originalTags.get(index);
            if (checkTag.type == MarkdownTag.Type.TextStyle || checkTag.type == MarkdownTag.Type.AlternativeTextStyle) {
                if ((checkTag.type == MarkdownTag.Type.TextStyle && checkTag.startPosition >= scanPosition) || (checkTag.type == MarkdownTag.Type.AlternativeTextStyle && checkTag.startPosition >= alternativeScanPosition)) {
                    List<ProcessedMarkdownTag> nestedTags = getRearrangedTextStyleTags(originalTags, index);
                    tags.addAll(nestedTags);
                    if (nestedTags.size() > 0) {
                        ProcessedMarkdownTag lastNestedTag = nestedTags.get(nestedTags.size() - 1);
                        if (checkTag.type == MarkdownTag.Type.TextStyle) {
                            scanPosition = lastNestedTag.endPosition;
                        } else {
                            alternativeScanPosition = lastNestedTag.endPosition;
                        }
                    }
                }
            } else {
                tags.add(checkTag);
            }
        }
        Collections.sort(tags);
    }

    private void processInternal() {
        ArrayList<MarkdownTag> sectionTags = new ArrayList<>();
        StringBuilder textBuilder = new StringBuilder();
        for (MarkdownTag tag : originalTags) {
            if (tag.type.isSection()) {
                sectionTags.add(tag);
            }
        }
        for (int sectionIndex = 0; sectionIndex < sectionTags.size(); sectionIndex++) {
            // Determine tags and copy ranges for this section
            MarkdownTag sectionTag = sectionTags.get(sectionIndex);
            ArrayList<MarkdownTag> innerTags = new ArrayList<>();
            for (MarkdownTag tag : originalTags) {
                if (!tag.type.isSection() && tag.startPosition >= sectionTag.startPosition && tag.endPosition <= sectionTag.endPosition) {
                    innerTags.add(tag);
                }
            }
            List<ProcessorRange> copyRanges = getCopyRanges(sectionTag, innerTags);

            // Add to text
            int startTextPosition = textBuilder.length();
            for (ProcessorRange range : copyRanges) {
                if (range.type == ProcessorRangeType.Copy) {
                    textBuilder.append(originalText, range.startPosition, range.endPosition);
                } else if (range.insertText != null) {
                    textBuilder.append(range.insertText);
                }
            }

            // Add processed block tag
            ProcessedMarkdownTag processedSectionTag = new ProcessedMarkdownTag(sectionTag.type, sectionTag.weight, startTextPosition, textBuilder.length());
            tags.add(processedSectionTag);

            // Add processed inner tags
            List<ProcessorRange> deleteRanges = getDeleteRanges(sectionTag, copyRanges);
            ArrayList<Integer> listWeightCounter = new ArrayList<>();
            int blockPositionAdjustment = sectionTag.startPosition - startTextPosition;
            for (MarkdownTag innerTag : innerTags) {
                // Calculate position offset adjustments
                int startOffset = -blockPositionAdjustment;
                int endOffset = -blockPositionAdjustment;
                for (ProcessorRange range : deleteRanges) {
                    if (range.type == ProcessorRangeType.Delete && range.startPosition < innerTag.endText) {
                        int rangeLength = range.endPosition - range.startPosition;
                        int tagLength = innerTag.endText - innerTag.startText;
                        int startAdjustment = Math.max(0, Math.min(rangeLength, innerTag.startText - range.startPosition));
                        startOffset -= startAdjustment;
                        endOffset -= startAdjustment + Math.min(tagLength, Math.min(rangeLength, Math.max(0, Math.min(innerTag.endText - range.startPosition, range.endPosition - innerTag.startText))));
                    } else if (range.type.isInsert() && range.startPosition < innerTag.endText) {
                        int length = range.insertText != null ? range.insertText.length() : 0;
                        if (range.endPosition <= innerTag.startText) {
                            startOffset += length;
                        }
                        endOffset += length;
                    }
                }

                // Create processed tag
                int startPosition = innerTag.startText + startOffset;
                int endPosition = innerTag.endText + endOffset;
                ProcessedMarkdownTag processedTag = new ProcessedMarkdownTag(innerTag.type, innerTag.weight, startPosition, endPosition);
                if (innerTag.type == MarkdownTag.Type.Link) {
                    if (innerTag.startExtra >= 0 && innerTag.endExtra >= 0) {
                        processedTag.link = originalText.substring(innerTag.startExtra, innerTag.endExtra);
                    } else {
                        processedTag.link = originalText.substring(innerTag.startText, innerTag.endText);
                    }
                }

                // Count list items
                if ((processedTag.type == MarkdownTag.Type.OrderedListItem || processedTag.type == MarkdownTag.Type.UnorderedListItem) && spanGenerator != null) {
                    int weightIndex = Math.max(0, processedTag.weight - 1);
                    if (weightIndex >= listWeightCounter.size()) {
                        for (int i = listWeightCounter.size(); i <= weightIndex; i++) {
                            listWeightCounter.add(0);
                        }
                    } else if (weightIndex + 1 < listWeightCounter.size()) {
                        int removeItems = listWeightCounter.size() - weightIndex - 1;
                        for (int i = 0; i < removeItems; i++) {
                            listWeightCounter.remove(listWeightCounter.size() - 1);
                        }
                    } else if ((listWeightCounter.get(weightIndex) > 0) != (processedTag.type == MarkdownTag.Type.OrderedListItem)) {
                        listWeightCounter.set(weightIndex, 0);
                    }
                    processedTag.counter = Math.abs(listWeightCounter.get(weightIndex)) + 1;
                    listWeightCounter.set(weightIndex, listWeightCounter.get(weightIndex) + (processedTag.type == MarkdownTag.Type.OrderedListItem ? 1 : -1));
                }

                // And add it
                tags.add(processedTag);
            }

            // Add section spacer and newlines between sections
            if (sectionIndex + 1 < sectionTags.size()) {
                if (spanGenerator != null) {
                    textBuilder.append("\n\n");
                    tags.add(new ProcessedMarkdownTag(MarkdownTag.Type.SectionSpacer, 0, textBuilder.length() - 1, textBuilder.length()));
                } else {
                    textBuilder.append("\n");
                }
            }
        }
        text = textBuilder.toString();
    }

    private List<ProcessedMarkdownTag> getRearrangedTextStyleTags(List<ProcessedMarkdownTag> checkTags, int index) {
        return getRearrangedTextStyleTags(checkTags, index, 0);
    }

    private List<ProcessedMarkdownTag> getRearrangedTextStyleTags(List<ProcessedMarkdownTag> checkTags, int index, int addWeight) {
        // Scan nested tags
        ProcessedMarkdownTag textStyleTag = checkTags.get(index);
        ArrayList<ProcessedMarkdownTag> result = new ArrayList<>();
        int scanPosition = textStyleTag.startPosition;
        for (int i = index + 1; i < checkTags.size(); i++) {
            // Break when reaching the end of the current text style tag
            ProcessedMarkdownTag checkTag = checkTags.get(i);
            if (checkTag.startPosition >= textStyleTag.endPosition) {
                break;
            }

            // Check nested text style tag
            if (checkTag.startPosition >= scanPosition && checkTag.type == textStyleTag.type) {
                List<ProcessedMarkdownTag> nestedTags = getRearrangedTextStyleTags(checkTags, i, textStyleTag.weight + addWeight);
                result.add(new ProcessedMarkdownTag(textStyleTag.type, textStyleTag.weight + addWeight, scanPosition, checkTag.startPosition));
                result.addAll(nestedTags);
                if (nestedTags.size() > 0) {
                    scanPosition = nestedTags.get(nestedTags.size() - 1).endPosition;
                }
            }
        }

        // Finish current tag and return result
        if (scanPosition < textStyleTag.endPosition) {
            result.add(new ProcessedMarkdownTag(textStyleTag.type, textStyleTag.weight + addWeight, scanPosition, textStyleTag.endPosition));
        }
        return result;
    }


    // --
    // Helper
    // --

    private List<ProcessorRange> getCopyRanges(MarkdownTag sectionTag, List<MarkdownTag> innerTags) {
        // Mark possible escape characters from the entire block for removal
        ProcessorRange sectionRange = new ProcessorRange(sectionTag.startText, sectionTag.endText, ProcessorRangeType.Copy);
        ArrayList<ProcessorRange> modifyRanges = new ArrayList<>();
        modifyRanges.add(sectionRange);
        for (MarkdownSymbol escapeSymbol : sectionTag.escapeSymbols) {
            for (ProcessorRange modifyRange : modifyRanges) {
                ProcessorRange addRange = modifyRange.markRemoval(escapeSymbol.startPosition, escapeSymbol.endPosition);
                if (addRange != null) {
                    modifyRanges.add(addRange);
                    break;
                }
            }
        }

        // Process inner tags
        for (MarkdownTag innerTag : innerTags) {
            // Mark leading text for removal
            if (innerTag.startText > innerTag.startPosition) {
                for (ProcessorRange modifyRange : modifyRanges) {
                    ProcessorRange addRange = modifyRange.markRemoval(innerTag.startPosition, innerTag.startText);
                    if (addRange != null) {
                        modifyRanges.add(addRange);
                        break;
                    }
                }
            }

            // Mark trailing text for removal
            if (innerTag.endText < innerTag.endPosition) {
                for (ProcessorRange modifyRange : modifyRanges) {
                    ProcessorRange addRange = modifyRange.markRemoval(innerTag.endText, innerTag.endPosition);
                    if (addRange != null) {
                        modifyRanges.add(addRange);
                        break;
                    }
                }
            }

            // Insert text for newlines
            if (innerTag.type == MarkdownTag.Type.Line && innerTag.endPosition < sectionTag.endPosition) {
                modifyRanges.add(new ProcessorRange(innerTag.endText, innerTag.endText, ProcessorRangeType.Insert, "\n"));
            }
        }
        Collections.sort(modifyRanges);
        return modifyRanges;
    }

    private List<ProcessorRange> getDeleteRanges(MarkdownTag sectionTag, List<ProcessorRange> copyRanges) {
        // Add delete range between each copy range
        ArrayList<ProcessorRange> result = new ArrayList<>();
        ProcessorRange previousRange = new ProcessorRange(sectionTag.startPosition, sectionTag.startPosition, ProcessorRangeType.Copy);
        for (ProcessorRange range : copyRanges) {
            if (range.type == ProcessorRangeType.Copy) {
                if (range.startPosition > previousRange.endPosition) {
                    result.add(new ProcessorRange(previousRange.endPosition, range.startPosition, ProcessorRangeType.Delete));
                }
                previousRange = range;
            } else {
                result.add(range);
            }
        }

        // Check if there is something left to delete at the end
        if (previousRange.endPosition < sectionTag.endPosition) {
            result.add(new ProcessorRange(previousRange.endPosition, sectionTag.endPosition, ProcessorRangeType.Delete));
        }

        // Return result
        return result;
    }


    // --
    // Internal range type enum
    // --

    private enum ProcessorRangeType {
        Copy,
        Delete,
        Insert;

        public boolean isInsert() {
            return this == Insert;
        }
    }


    // --
    // Internal range helper class
    // --

    private static class ProcessorRange implements Comparable<ProcessorRange> {
        int startPosition;
        int endPosition;
        ProcessorRangeType type;
        String insertText;

        ProcessorRange(int startPosition, int endPosition, ProcessorRangeType type) {
            this(startPosition, endPosition, type, null);
        }

        ProcessorRange(int startPosition, int endPosition, ProcessorRangeType type, String insertText) {
            this.startPosition = startPosition;
            this.endPosition = endPosition;
            this.type = type;
            this.insertText = insertText;
        }

        ProcessorRange markRemoval(int removeStartPosition, int removeEndPosition) {
            if (type == ProcessorRangeType.Copy && isValid()) {
                if (removeStartPosition > startPosition && removeEndPosition < endPosition) {
                    ProcessorRange split = new ProcessorRange(removeEndPosition, endPosition, ProcessorRangeType.Copy);
                    endPosition = removeStartPosition;
                    return split;
                } else if (removeStartPosition <= startPosition && removeEndPosition > startPosition) {
                    startPosition = removeEndPosition;
                    endPosition = Math.max(startPosition, endPosition);
                } else if (removeStartPosition < endPosition && removeEndPosition >= endPosition) {
                    endPosition = removeStartPosition;
                    startPosition = Math.min(startPosition, endPosition);
                }
            }
            return null;
        }

        boolean isValid() {
            return startPosition < endPosition;
        }

        @Override
        public int compareTo(@Nullable ProcessorRange other) {
            if (other != null) {
                if (startPosition == other.startPosition && type.isInsert() && !other.type.isInsert()) {
                    return -1;
                }
                return startPosition - other.startPosition;
            }
            return 0;
        }
    }
}
