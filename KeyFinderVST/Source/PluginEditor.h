#pragma once

#include <JuceHeader.h>
#include "PluginProcessor.h"

class KeyFinderAudioProcessorEditor : public juce::AudioProcessorEditor,
                                       private juce::Timer
{
public:
    KeyFinderAudioProcessorEditor (KeyFinderAudioProcessor&);
    ~KeyFinderAudioProcessorEditor() override;

    void paint (juce::Graphics&) override;
    void resized() override;
    void timerCallback() override;

private:
    KeyFinderAudioProcessor& audioProcessor;

    juce::TextButton analyzeButton;
    juce::Label keyLabel;
    juce::Label camelotLabel;
    juce::Label bpmLabel;
    juce::Label statusLabel;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (KeyFinderAudioProcessorEditor)
};
