#pragma once

#include <vector>

class BPMDetector
{
public:
    BPMDetector();
    double detectBPM(const std::vector<float>& audioSamples, double sampleRate);

private:
    std::vector<float> calculateOnsetStrength(const std::vector<float>& samples, double sampleRate);
    std::vector<float> performFFT(const std::vector<float>& samples, int size);
    std::vector<float> applyHannWindow(const std::vector<float>& samples);
    std::vector<float> calculateAutocorrelation(const std::vector<float>& onsetStrength);
    double findTempoPeak(const std::vector<float>& autocorrelation, double sampleRate);
};
