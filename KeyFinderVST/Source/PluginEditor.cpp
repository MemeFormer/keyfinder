#include "PluginProcessor.h"
#include "PluginEditor.h"

KeyFinderAudioProcessorEditor::KeyFinderAudioProcessorEditor (KeyFinderAudioProcessor& p)
    : AudioProcessorEditor (&p), audioProcessor (p)
{
    // Set window size
    setSize (400, 500);

    // Configure analyze button
    analyzeButton.setButtonText ("ANALYZE");
    analyzeButton.onClick = [this] { audioProcessor.startAnalysis(); };
    analyzeButton.setColour (juce::TextButton::buttonColourId, juce::Colours::black);
    analyzeButton.setColour (juce::TextButton::textColourOffId, juce::Colours::white);
    addAndMakeVisible (analyzeButton);

    // Configure labels
    auto setupLabel = [this](juce::Label& label, const juce::String& text)
    {
        label.setText (text, juce::dontSendNotification);
        label.setFont (juce::Font ("Courier", 48.0f, juce::Font::plain));
        label.setColour (juce::Label::textColourId, juce::Colours::white);
        label.setJustificationType (juce::Justification::centred);
        addAndMakeVisible (label);
    };

    setupLabel (keyLabel, "--");
    setupLabel (camelotLabel, "--");
    setupLabel (bpmLabel, "--");

    statusLabel.setFont (juce::Font ("Courier", 12.0f, juce::Font::plain));
    statusLabel.setColour (juce::Label::textColourId, juce::Colours::white.withAlpha(0.7f));
    statusLabel.setJustificationType (juce::Justification::centred);
    addAndMakeVisible (statusLabel);

    // Start timer to update UI
    startTimer (100);
}

KeyFinderAudioProcessorEditor::~KeyFinderAudioProcessorEditor()
{
}

void KeyFinderAudioProcessorEditor::paint (juce::Graphics& g)
{
    // Black background
    g.fillAll (juce::Colours::black);

    // Title
    g.setColour (juce::Colours::white);
    g.setFont (juce::Font ("Courier", 14.0f, juce::Font::plain));
    g.drawText ("KEY FINDER VST", 0, 20, getWidth(), 30, juce::Justification::centred);

    // Section labels
    g.setFont (juce::Font ("Courier", 10.0f, juce::Font::plain));
    g.setColour (juce::Colours::white.withAlpha(0.5f));
    g.drawText ("KEY", 0, 100, getWidth(), 20, juce::Justification::centred);
    g.drawText ("CAMELOT", 0, 220, getWidth(), 20, juce::Justification::centred);
    g.drawText ("BPM", 0, 340, getWidth(), 20, juce::Justification::centred);

    // Dividing lines
    g.setColour (juce::Colours::white.withAlpha(0.1f));
    g.drawLine (40, 200, getWidth() - 40, 200, 1.0f);
    g.drawLine (40, 320, getWidth() - 40, 320, 1.0f);
}

void KeyFinderAudioProcessorEditor::resized()
{
    auto area = getLocalBounds();

    analyzeButton.setBounds (area.removeFromBottom(60).reduced(20));

    statusLabel.setBounds (area.removeFromBottom(30).reduced(20));

    // Key
    area.removeFromTop(120);
    keyLabel.setBounds (area.removeFromTop(70));

    // Camelot
    area.removeFromTop(30);
    camelotLabel.setBounds (area.removeFromTop(70));

    // BPM
    area.removeFromTop(30);
    bpmLabel.setBounds (area.removeFromTop(70));
}

void KeyFinderAudioProcessorEditor::timerCallback()
{
    if (audioProcessor.isAnalyzing())
    {
        statusLabel.setText ("Analyzing...", juce::dontSendNotification);
        analyzeButton.setEnabled (false);
    }
    else if (audioProcessor.hasResults())
    {
        keyLabel.setText (audioProcessor.getDetectedKey(), juce::dontSendNotification);
        camelotLabel.setText (audioProcessor.getCamelotNotation(), juce::dontSendNotification);
        bpmLabel.setText (juce::String (audioProcessor.getDetectedBPM(), 1), juce::dontSendNotification);
        statusLabel.setText ("Analysis complete", juce::dontSendNotification);
        analyzeButton.setEnabled (true);
    }
    else
    {
        statusLabel.setText ("Press ANALYZE to detect key and BPM", juce::dontSendNotification);
        analyzeButton.setEnabled (true);
    }
}
