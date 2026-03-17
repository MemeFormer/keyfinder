#pragma once

#include <vector>
#include <string>
#include <array>

class KeyDetector
{
public:
    struct KeyResult
    {
        std::string fullName;
        std::string shortName;
        std::string camelot;
    };

    KeyDetector();
    KeyResult detectKey(const std::vector<float>& audioSamples, double sampleRate);

private:
    static constexpr int NUM_PITCH_CLASSES = 12;

    // Krumhansl-Schmuckler key profiles
    static constexpr std::array<double, 12> majorProfile = {
        6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88
    };

    static constexpr std::array<double, 12> minorProfile = {
        6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17
    };

    std::vector<double> calculateChromagram(const std::vector<float>& samples, double sampleRate);
    std::vector<float> performFFT(const std::vector<float>& samples);
    std::vector<float> applyHammingWindow(const std::vector<float>& samples);
    int frequencyToPitchClass(double frequency);
    KeyResult correlateWithKeyProfiles(const std::vector<double>& chromagram);
    double calculateCorrelation(const std::vector<double>& chromagram, const std::array<double, 12>& profile);

    KeyResult getKeyForRotation(int rotation, bool major);
};
