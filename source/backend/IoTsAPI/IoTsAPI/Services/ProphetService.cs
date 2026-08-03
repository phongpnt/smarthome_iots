using System;
using System.Collections.Generic;
using System.Linq;

namespace IoTsAPI.Services;

public class ProphetService
{
    private const double WeeklyPeriod = 7.0;
    private const int    NHarmonics   = 2;  // weekly harmonics
    private const int    NCols        = 2 + 2 * NHarmonics;  // 6 columns: [1, t, sin1, cos1, sin2, cos2]

    public ProphetForecast? Forecast(
        List<(DateTime Date, double Wh)> history,
        int horizonDays = 14)
    {
        if (history.Count < 14) return null;

        var sorted = history.OrderBy(h => h.Date).ToList();
        int    N   = sorted.Count;
        var    t0  = sorted[0].Date;

        double[] tArr = sorted.Select(h => (h.Date - t0).TotalDays).ToArray();
        double[] yArr = sorted.Select(h => h.Wh).ToArray();

        double[,] X    = BuildDesignMatrix(tArr);
        double[]  beta = SolveOLS(X, yArr, N);

        double[] fitted = MatMulVec(X, beta, N);
        double   sigma  = Math.Sqrt(
            Enumerable.Range(0, N)
                      .Select(i => Math.Pow(yArr[i] - fitted[i], 2))
                      .Average());

        double[] tFuture = Enumerable.Range(1, horizonDays)
            .Select(i => (sorted.Last().Date.AddDays(i) - t0).TotalDays)
            .ToArray();

        double[,] XFut = BuildDesignMatrix(tFuture);
        double[]  pred = MatMulVec(XFut, beta, horizonDays);

        var points = Enumerable.Range(0, horizonDays).Select(i => (
            Date:      sorted.Last().Date.AddDays(i + 1),
            Predicted: Math.Max(0, pred[i]),
            Lower:     Math.Max(0, pred[i] - 1.96 * sigma),
            Upper:     pred[i] + 1.96 * sigma
        )).ToList();

        double trendSlope    = beta[1];  // Wh gained per calendar day
        double recentAvg     = sorted.TakeLast(7).Average(h => h.Wh);
        double forecastAvg   = pred.Average();
        double changePercent = recentAvg > 1e-6
            ? (forecastAvg - recentAvg) / recentAvg * 100.0
            : 0.0;

        return new ProphetForecast(
            points, trendSlope, sigma,
            recentAvg, forecastAvg, changePercent);
    }

    private static double[,] BuildDesignMatrix(double[] tArr)
    {
        int N = tArr.Length;
        double[,] X = new double[N, NCols];
        for (int i = 0; i < N; i++)
        {
            X[i, 0] = 1.0;
            X[i, 1] = tArr[i];
            for (int h = 1; h <= NHarmonics; h++)
            {
                double θ = 2.0 * Math.PI * h * tArr[i] / WeeklyPeriod;
                X[i, 2 + 2 * (h - 1)] = Math.Sin(θ);
                X[i, 3 + 2 * (h - 1)] = Math.Cos(θ);
            }
        }
        return X;
    }

    private static double[] SolveOLS(double[,] X, double[] y, int N)
    {
        double[,] XtX = new double[NCols, NCols];
        double[]  Xty = new double[NCols];

        for (int j = 0; j < NCols; j++)
        {
            for (int i = 0; i < N; i++) Xty[j] += X[i, j] * y[i];
            for (int k = 0; k < NCols; k++)
                for (int i = 0; i < N; i++)
                    XtX[j, k] += X[i, j] * X[i, k];
        }

        return GaussianElimination(XtX, Xty);
    }

    private static double[] GaussianElimination(double[,] A, double[] b)
    {
        int n = b.Length;

        double[,] aug = new double[n, n + 1];
        for (int i = 0; i < n; i++)
        {
            for (int j = 0; j < n; j++) aug[i, j] = A[i, j];
            aug[i, n] = b[i];
        }

        for (int col = 0; col < n; col++)
        {
            int pivot = col;
            for (int row = col + 1; row < n; row++)
                if (Math.Abs(aug[row, col]) > Math.Abs(aug[pivot, col]))
                    pivot = row;

            for (int j = 0; j <= n; j++)
                (aug[col, j], aug[pivot, j]) = (aug[pivot, j], aug[col, j]);

            if (Math.Abs(aug[col, col]) < 1e-12) continue;  // near-singular column

            for (int row = col + 1; row < n; row++)
            {
                double f = aug[row, col] / aug[col, col];
                for (int j = col; j <= n; j++)
                    aug[row, j] -= f * aug[col, j];
            }
        }

        double[] x = new double[n];
        for (int i = n - 1; i >= 0; i--)
        {
            x[i] = aug[i, n];
            for (int j = i + 1; j < n; j++) x[i] -= aug[i, j] * x[j];
            if (Math.Abs(aug[i, i]) > 1e-12) x[i] /= aug[i, i];
        }
        return x;
    }

    private static double[] MatMulVec(double[,] X, double[] beta, int N)
    {
        double[] result = new double[N];
        for (int i = 0; i < N; i++)
            for (int j = 0; j < NCols; j++)
                result[i] += X[i, j] * beta[j];
        return result;
    }
}

public record ProphetForecast(
    List<(DateTime Date, double Predicted, double Lower, double Upper)> Points,

    double TrendSlopeWhPerDay,

    double ResidualStdDev,

    double RecentAvgWh,

    double ForecastAvgWh,

    double ChangePercent
);
