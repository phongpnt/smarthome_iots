namespace IoTsAPI.Services;

public static class PowerAnalyzer
{
    public static double ZScore(IReadOnlyList<double> baseline, double value)
    {
        if (baseline.Count < 2) return 0;
        var mean = baseline.Average();
        var std = StdDev(baseline);
        return std < 0.001 ? 0 : (value - mean) / std;
    }

    public static double LinearRegressionSlope(IReadOnlyList<double> values)
    {
        int n = values.Count;
        if (n < 2) return 0;

        double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
        for (int i = 0; i < n; i++)
        {
            sumX += i;
            sumY += values[i];
            sumXY += i * values[i];
            sumX2 += i * i;
        }

        double denom = n * sumX2 - sumX * sumX;
        return denom == 0 ? 0 : (n * sumXY - sumX * sumY) / denom;
    }

    public static double MovingAverage(IReadOnlyList<double> values, int window = 7)
    {
        if (values.Count == 0) return 0;
        var take = values.TakeLast(window).ToList();
        return take.Average();
    }

    public static bool IsAnomaly(IReadOnlyList<double> baseline, double todayValue, double zThreshold = 2.0)
        => ZScore(baseline, todayValue) > zThreshold;

    public static bool IsIncreasingTrend(IReadOnlyList<double> values, double slopeThresholdWh = 10.0)
        => LinearRegressionSlope(values) > slopeThresholdWh;

    public static double StdDev(IReadOnlyList<double> values)
    {
        if (values.Count < 2) return 0;
        var mean = values.Average();
        var variance = values.Sum(v => Math.Pow(v - mean, 2)) / (values.Count - 1);
        return Math.Sqrt(variance);
    }
}
