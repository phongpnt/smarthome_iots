using IoTsAPI.Models;

namespace IoTsAPI.Services;

public class IsolationForestService
{

    private const int    NumTrees       = 100;
    private const int    SubsampleSize  = 256;
    private const double EulerMascheroni = 0.5772156649;

    public record AnomalyResult(
        string   DeviceId,
        DateTime Timestamp,
        double   PowerWh,
        double   AnomalyScore);

    public List<AnomalyResult> Detect(
        List<UsagePowerLog> trainingLogs,
        List<UsagePowerLog> targetLogs,
        double threshold = 0.65)
    {
        if (trainingLogs.Count < 10) return [];

        var trainVecs = trainingLogs.Select(ToVector).ToList();
        var forest    = BuildForest(trainVecs);
        int n         = trainVecs.Count;

        var results = new List<AnomalyResult>();
        foreach (var log in targetLogs)
        {
            var score = ComputeScore(ToVector(log), forest, n);
            if (score >= threshold)
            {
                results.Add(new AnomalyResult(
                    log.DeviceId,
                    log.CalculateDate,
                    log.PowerUsageWat,
                    Math.Round(score, 3)));
            }
        }
        return results;
    }

    private static double[] ToVector(UsagePowerLog l) =>
    [
        l.PowerUsageWat,
        l.CalculateDate.Hour,
        (double)l.CalculateDate.DayOfWeek,
    ];

    private static List<IsoNode> BuildForest(List<double[]> vecs)
    {
        var rng      = new Random(42);
        int n        = Math.Min(vecs.Count, SubsampleSize);
        int maxDepth = (int)Math.Ceiling(Math.Log2(n + 1));

        var forest = new List<IsoNode>(NumTrees);
        for (int t = 0; t < NumTrees; t++)
        {
            var sample = vecs.OrderBy(_ => rng.Next()).Take(n).ToList();
            forest.Add(BuildNode(sample, 0, maxDepth, rng));
        }
        return forest;
    }

    private static IsoNode BuildNode(
        List<double[]> vecs, int depth, int maxDepth, Random rng)
    {
        if (depth >= maxDepth || vecs.Count <= 1)
            return new IsoNode { Size = vecs.Count };

        int dims = vecs[0].Length;
        int feat = rng.Next(dims);

        double min = vecs.Min(v => v[feat]);
        double max = vecs.Max(v => v[feat]);

        if (max - min < 1e-10)
            return new IsoNode { Size = vecs.Count };

        double split = min + rng.NextDouble() * (max - min);

        var left  = vecs.Where(v => v[feat] <  split).ToList();
        var right = vecs.Where(v => v[feat] >= split).ToList();

        return new IsoNode
        {
            FeatureIndex = feat,
            SplitValue   = split,
            Left         = BuildNode(left,  depth + 1, maxDepth, rng),
            Right        = BuildNode(right, depth + 1, maxDepth, rng),
        };
    }

    private static double ComputeScore(double[] vec, List<IsoNode> forest, int n)
    {
        double avgPath = forest.Average(tree => PathLength(vec, tree, 0));
        double cn      = ExpectedPathLength(n);
        if (cn < 1e-9) return 0.5;
        return Math.Pow(2.0, -avgPath / cn);
    }

    private static double PathLength(double[] vec, IsoNode node, int depth)
    {
        if (node.Left is null || node.Right is null)
            return depth + ExpectedPathLength(node.Size);

        return vec[node.FeatureIndex] < node.SplitValue
            ? PathLength(vec, node.Left,  depth + 1)
            : PathLength(vec, node.Right, depth + 1);
    }

    private static double ExpectedPathLength(int n) => n switch
    {
        <= 1 => 0.0,
        2    => 1.0,
        _    => 2.0 * (Math.Log(n - 1) + EulerMascheroni) - 2.0 * (n - 1.0) / n
    };

    private sealed class IsoNode
    {
        public int      FeatureIndex { get; init; }
        public double   SplitValue   { get; init; }
        public int      Size         { get; init; }  // dùng cho leaf
        public IsoNode? Left         { get; init; }
        public IsoNode? Right        { get; init; }
    }
}
