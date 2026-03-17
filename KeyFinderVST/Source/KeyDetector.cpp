#include "KeyDetector.h"
#include <JuceHeader.h>
#include <cmath>
#include <algorithm>

KeyDetector::KeyDetector()
{
}

KeyDetector::KeyResult KeyDetector::detectKey(const std::vector<float>& audioSamples, double sampleRate)
{
    auto chromagram = calculateChromagram(audioSamples, sampleRate);
    return correlateWithKeyProfiles(chromagram);
}

std::vector<double> KeyDetector::calculateChromagram(const std::vector<float>& samples, double sampleRate)
{
    const int fftSize = 8192;
    const int hopSize = fftSize / 2;
    std::vector<double> pitchClassProfile(NUM_PITCH_CLASSES, 0.0);

    for (int frameStart = 0; frameStart < samples.size() - fftSize; frameStart += hopSize)
    {
        std::vector<float> frame(samples.begin() + frameStart,
                                 samples.begin() + frameStart + fftSize);

        auto windowedFrame = applyHammingWindow(frame);
        auto spectrum = performFFT(windowedFrame);

        for (int bin = 0; bin < fftSize / 2; ++bin)
        {
            double frequency = bin * sampleRate / fftSize;
            if (frequency > 60.0 && frequency < 5000.0)
            {
                int pitchClass = frequencyToPitchClass(frequency);
                pitchClassProfile[pitchClass] += spectrum[bin];
            }
        }
    }

    // Normalize
    double sum = 0.0;
    for (auto val : pitchClassProfile)
        sum += val;

    if (sum > 0.0)
    {
        for (auto& val : pitchClassProfile)
            val /= sum;
    }

    return pitchClassProfile;
}

std::vector<float> KeyDetector::applyHammingWindow(const std::vector<float>& samples)
{
    std::vector<float> windowed(samples.size());
    const int n = samples.size();

    for (int i = 0; i < n; ++i)
    {
        double window = 0.54 - 0.46 * std::cos(2.0 * M_PI * i / (n - 1));
        windowed[i] = samples[i] * window;
    }

    return windowed;
}

std::vector<float> KeyDetector::performFFT(const std::vector<float>& samples)
{
    juce::dsp::FFT fft(13); // 2^13 = 8192
    std::vector<float> fftData(8192 * 2, 0.0f);

    // Copy input
    for (size_t i = 0; i < std::min(samples.size(), size_t(8192)); ++i)
        fftData[i] = samples[i];

    fft.performFrequencyOnlyForwardTransform(fftData.data());

    std::vector<float> magnitudes(4096);
    for (int i = 0; i < 4096; ++i)
        magnitudes[i] = fftData[i];

    return magnitudes;
}

int KeyDetector::frequencyToPitchClass(double frequency)
{
    const double a4 = 440.0;
    double halfStepsFromA4 = 12.0 * std::log2(frequency / a4);
    int pitchClass = (static_cast<int>(std::round(halfStepsFromA4)) + 9 + 1200) % 12;
    return pitchClass;
}

KeyDetector::KeyResult KeyDetector::correlateWithKeyProfiles(const std::vector<double>& chromagram)
{
    double bestCorrelation = -std::numeric_limits<double>::infinity();
    KeyResult bestKey;

    for (int rotation = 0; rotation < 12; ++rotation)
    {
        // Rotate chromagram
        std::vector<double> rotated(12);
        for (int i = 0; i < 12; ++i)
            rotated[i] = chromagram[(i + rotation) % 12];

        // Test major
        double majorCorr = calculateCorrelation(rotated, majorProfile);
        if (majorCorr > bestCorrelation)
        {
            bestCorrelation = majorCorr;
            bestKey = getKeyForRotation(rotation, true);
        }

        // Test minor
        double minorCorr = calculateCorrelation(rotated, minorProfile);
        if (minorCorr > bestCorrelation)
        {
            bestCorrelation = minorCorr;
            bestKey = getKeyForRotation(rotation, false);
        }
    }

    return bestKey;
}

double KeyDetector::calculateCorrelation(const std::vector<double>& chromagram,
                                         const std::array<double, 12>& profile)
{
    double meanChroma = 0.0, meanProfile = 0.0;
    for (int i = 0; i < 12; ++i)
    {
        meanChroma += chromagram[i];
        meanProfile += profile[i];
    }
    meanChroma /= 12.0;
    meanProfile /= 12.0;

    double covariance = 0.0, chromaVariance = 0.0, profileVariance = 0.0;

    for (int i = 0; i < 12; ++i)
    {
        double chromaDiff = chromagram[i] - meanChroma;
        double profileDiff = profile[i] - meanProfile;
        covariance += chromaDiff * profileDiff;
        chromaVariance += chromaDiff * chromaDiff;
        profileVariance += profileDiff * profileDiff;
    }

    if (chromaVariance == 0.0 || profileVariance == 0.0)
        return 0.0;

    return covariance / std::sqrt(chromaVariance * profileVariance);
}

KeyDetector::KeyResult KeyDetector::getKeyForRotation(int rotation, bool major)
{
    const char* majorKeys[] = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};
    const char* minorKeys[] = {"Cm", "C#m", "Dm", "D#m", "Em", "Fm", "F#m", "Gm", "G#m", "Am", "A#m", "Bm"};
    const char* majorCamelot[] = {"8B", "3B", "10B", "5B", "12B", "7B", "2B", "9B", "4B", "11B", "6B", "1B"};
    const char* minorCamelot[] = {"5A", "12A", "7A", "2A", "9A", "4A", "11A", "6A", "1A", "8A", "3A", "10A"};

    KeyResult result;
    if (major)
    {
        result.shortName = majorKeys[rotation];
        result.fullName = std::string(majorKeys[rotation]) + " Major";
        result.camelot = majorCamelot[rotation];
    }
    else
    {
        result.shortName = minorKeys[rotation];
        result.fullName = std::string(minorKeys[rotation]) + " Minor";
        result.camelot = minorCamelot[rotation];
    }

    return result;
}
