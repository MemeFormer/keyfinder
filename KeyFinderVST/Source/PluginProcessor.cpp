#include "PluginProcessor.h"
#include "PluginEditor.h"

KeyFinderAudioProcessor::KeyFinderAudioProcessor()
     : AudioProcessor (BusesProperties()
                       .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                       .withOutput ("Output", juce::AudioChannelSet::stereo(), true))
{
    keyDetector = std::make_unique<KeyDetector>();
    bpmDetector = std::make_unique<BPMDetector>();
    audioBuffer.reserve(maxBufferSize);
}

KeyFinderAudioProcessor::~KeyFinderAudioProcessor()
{
}

const juce::String KeyFinderAudioProcessor::getName() const
{
    return JucePlugin_Name;
}

bool KeyFinderAudioProcessor::acceptsMidi() const
{
    return false;
}

bool KeyFinderAudioProcessor::producesMidi() const
{
    return false;
}

bool KeyFinderAudioProcessor::isMidiEffect() const
{
    return false;
}

double KeyFinderAudioProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int KeyFinderAudioProcessor::getNumPrograms()
{
    return 1;
}

int KeyFinderAudioProcessor::getCurrentProgram()
{
    return 0;
}

void KeyFinderAudioProcessor::setCurrentProgram (int index)
{
}

const juce::String KeyFinderAudioProcessor::getProgramName (int index)
{
    return {};
}

void KeyFinderAudioProcessor::changeProgramName (int index, const juce::String& newName)
{
}

void KeyFinderAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    currentSampleRate = sampleRate;
}

void KeyFinderAudioProcessor::releaseResources()
{
}

bool KeyFinderAudioProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
     && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;

    return true;
}

void KeyFinderAudioProcessor::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;

    // Pass audio through
    if (analyzing && bufferPosition < maxBufferSize)
    {
        // Collect audio for analysis (mono mix)
        const int numSamples = buffer.getNumSamples();
        const int numChannels = buffer.getNumChannels();

        for (int i = 0; i < numSamples && bufferPosition < maxBufferSize; ++i)
        {
            float sum = 0.0f;
            for (int ch = 0; ch < numChannels; ++ch)
                sum += buffer.getSample(ch, i);

            audioBuffer.push_back(sum / numChannels);
            bufferPosition++;
        }
    }
}

void KeyFinderAudioProcessor::startAnalysis()
{
    if (!analyzing)
    {
        audioBuffer.clear();
        bufferPosition = 0;
        analyzing = true;
        analysisComplete = false;

        // Start async analysis after collecting enough samples
        juce::Timer::callAfterDelay(5000, [this]() // Collect 5 seconds of audio
        {
            if (analyzing)
            {
                analyzing = false;

                // Perform analysis
                auto keyResult = keyDetector->detectKey(audioBuffer, currentSampleRate);
                detectedKey = keyResult.shortName;
                camelotNotation = keyResult.camelot;

                detectedBPM = bpmDetector->detectBPM(audioBuffer, currentSampleRate);

                analysisComplete = true;
            }
        });
    }
}

bool KeyFinderAudioProcessor::hasEditor() const
{
    return true;
}

juce::AudioProcessorEditor* KeyFinderAudioProcessor::createEditor()
{
    return new KeyFinderAudioProcessorEditor (*this);
}

void KeyFinderAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
}

void KeyFinderAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
}

juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new KeyFinderAudioProcessor();
}
