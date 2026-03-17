#include "BPMDetector.h"
#include <JuceHeader.h>
#include <cmath>
#include <algorithm>

BPMDetector::BPMDetector()
{
}

double BPMDetector::detectBPM(const std::vector<float>& audioSamples, double sampleRate)
{
    auto onsetStrength = calculateOnsetStrength(audioSamples, sampleRate);
    auto tempogram = calculateAutocorrelation(onsetStrength);
    double bpm = findTempoPeak(tempogram, sampleRate);
    return bpm;
}

std::vector<float> BPMDetector::calculateOnsetStrength(const std::vector<float>& samples, double sampleRate)
{
    const int hopSize = 512;
    const int fftSize = 2048;
    std::vector<float> onsetStrength;
    std::vector<float> previousSpectrum(fftSize / 2, 0.0f);

    for (int frameStart = 0; frameStart < samples.size() - fftSize; frameStart += hopSize)
    {
        std::vector<float> frame(samples.begin() + frameStart,
                                 samples.begin() + frameStart + fftSize);

        auto windowedFrame = applyHannWindow(frame);
        auto spectrum = performFFT(windowedFrame, fftSize);

        float flux = 0.0f;
        for (size_t i = 0; i < spectrum.size(); ++i)
        {
            float diff = spectrum[i] - previousSpectrum[i];
            flux += std::max(0.0f, diff);
        }

        onsetStrength.push_back(flux);
        previousSpectrum = spectrum;
    }

    // Normalize
    auto maxFlux = *std::max_element(onsetStrength.begin(), onsetStrength.end());
    if (maxFlux > 0.0f)
    {
        for (auto& val : onsetStrength)
            val /= maxFlux;
    }

    return onsetStrength;
}

std::vector<float> BPMDetector::applyHannWindow(const std::vector<float>& samples)
{
    std::vector<float> windowed(samples.size());
    const int n = samples.size();

    for (int i = 0; i < n; ++i)
    {
        double window = 0.5 - 0.5 * std::cos(2.0 * M_PI * i / (n - 1));
        windowed[i] = samples[i] * window;
    }

    return windowed;
}

std::vector<float> BPMDetector::performFFT(const std::vector<float>& samples, int size)
{
    juce::dsp::FFT fft(11); // 2^11 = 2048
    std::vector<float> fftData(2048 * 2, 0.0f);

    for (size_t i = 0; i < std::min(samples.size(), size_t(2048)); ++i)
        fftData[i] = samples[i];

    fft.performFrequencyOnlyForwardTransform(fftData.data());

    std::vector<float> magnitudes(1024);
    for (int i = 0; i < 1024; ++i)
        magnitudes[i] = fftData[i];

    return magnitudes;
}

std::vector<float> BPMDetector::calculateAutocorrelation(const std::vector<float>& onsetStrength)
{
    const int n = onsetStrength.size();
    std::vector<float> autocorrelation(n, 0.0f);

    for (int lag = 0; lag < n; ++lag)
    {
        float sum = 0.0f;
        for (int i = 0; i < n - lag; ++i)
            sum += onsetStrength[i] * onsetStrength[i + lag];

        autocorrelation[lag] = sum;
    }

    return autocorrelation;
}

double BPMDetector::findTempoPeak(const std::vector<float>& autocorrelation, double sampleRate)
{
    const int hopSize = 512;
    const double framesPerSecond = sampleRate / hopSize;

    const double minBPM = 60.0;
    const double maxBPM = 180.0;

    const int minLag = static_cast<int>(60.0 / maxBPM * framesPerSecond);
    const int maxLag = std::min(static_cast<int>(60.0 / minBPM * framesPerSecond),
                                 static_cast<int>(autocorrelation.size()) - 1);

    float maxPeak = 0.0f;
    int maxPeakLag = minLag;

    for (int lag = minLag; lag <= maxLag; ++lag)
    {
        if (autocorrelation[lag] > maxPeak)
        {
            if (lag > 0 && lag < autocorrelation.size() - 1)
            {
                if (autocorrelation[lag] > autocorrelation[lag - 1] &&
                    autocorrelation[lag] > autocorrelation[lag + 1])
                {
                    maxPeak = autocorrelation[lag];
                    maxPeakLag = lag;
                }
            }
        }
    }

    double bpm = 60.0 * framesPerSecond / maxPeakLag;
    return std::round(bpm * 10.0) / 10.0;
}
