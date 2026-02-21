package predictor

import (
	"math"
	"sort"
	"time"

	"larko.se/poke/src/domain"
	"larko.se/poke/src/utils"
)

// PredictNext returns the predicted next due date for an action, or nil if there
// is insufficient data (fewer than 2 events).
//
// Prediction algorithm:
//  1. Compute a seasonally-weighted average interval between consecutive events.
//     Each gap is weighted by the minimum seasonal weight of its two endpoints,
//     so cross-season transitions are naturally down-weighted.
//  2. Find the seasonally-weighted mode time-of-day across all events,
//     quantised to the nearest 15-minute mark.
//  3. Return (date-only part of weighted prediction) + (weighted time-of-day).
//
// now is passed explicitly so callers (and tests) can control the reference point.
func PredictNext(action *domain.Action, now time.Time) *time.Time {
	timestamps := eventTimestamps(action)
	if len(timestamps) < 2 {
		return nil
	}

	sort.Slice(timestamps, func(i, j int) bool {
		return timestamps[i].Before(timestamps[j])
	})

	avgInterval := weightedAverageInterval(timestamps, now)
	rawPrediction := timestamps[len(timestamps)-1].Add(avgInterval)

	// Strip time-of-day from the raw prediction and re-apply the seasonally-weighted one.
	dateOnly := time.Date(
		rawPrediction.Year(), rawPrediction.Month(), rawPrediction.Day(),
		0, 0, 0, 0, rawPrediction.Location(),
	)
	tod := weightedMostCommonTimeOfDay(timestamps, now)
	result := dateOnly.Add(tod).UTC()

	return &result
}

// seasonalWeight returns a weight in [0, 1] reflecting how "in-season" an event
// timestamp is relative to now, based purely on day-of-year and wrapping around
// the Dec 31 -> Jan 1 boundary:
//
//	weight = (1 + cos(pi * delta_days / 182.5)) / 2
//
// Results:
//
//	same calendar day   -> 1.0
//	~3 months apart     -> 0.5
//	~6 months apart     -> 0.0
func seasonalWeight(event, now time.Time) float64 {
	delta := abs(event.YearDay() - now.YearDay())
	if delta > 182 {
		delta = 365 - delta
	}
	return (1 + math.Cos(math.Pi*float64(delta)/182.5)) / 2
}

// weightedAverageInterval returns a seasonally-weighted mean gap between consecutive
// events. Each gap's weight is the minimum seasonal weight of its two endpoints, so
// a gap that spans a season boundary (one end in-season, one end out-of-season) is
// automatically suppressed rather than skewing the prediction.
//
// Fallback: if the total gap weight falls below minTotalWeight (all events are
// off-season), the function falls back to a plain unweighted average so that the
// predictor always returns a valid result.
func weightedAverageInterval(sorted []time.Time, now time.Time) time.Duration {
	const minTotalWeight = 0.5

	type weightedGap struct {
		gap    time.Duration
		weight float64
	}

	gaps := make([]weightedGap, len(sorted)-1)
	for i := 1; i < len(sorted); i++ {
		gap := sorted[i].Sub(sorted[i-1]).Abs()
		w := math.Min(seasonalWeight(sorted[i-1], now), seasonalWeight(sorted[i], now))
		gaps[i-1] = weightedGap{gap: gap, weight: w}
	}

	var totalWeight, weightedSum float64
	for _, g := range gaps {
		totalWeight += g.weight
		weightedSum += float64(g.gap) * g.weight
	}

	if totalWeight < minTotalWeight {
		return averageInterval(sorted)
	}

	return time.Duration(weightedSum / totalWeight)
}

// weightedMostCommonTimeOfDay returns the mode time-of-day (as a Duration since
// midnight) across all timestamps. Each event's vote is weighted by its seasonal
// proximity to now, so in-season times-of-day dominate out-of-season ones.
// Minutes are quantised to the nearest 15-minute mark.
func weightedMostCommonTimeOfDay(timestamps []time.Time, now time.Time) time.Duration {
	scores := make(map[time.Duration]float64)
	for _, t := range timestamps {
		minute := nearestQuarter(t.Minute())
		tod := time.Duration(t.Hour())*time.Hour + time.Duration(minute)*time.Minute
		scores[tod] += seasonalWeight(t, now)
	}

	var best time.Duration
	bestScore := -1.0
	for tod, s := range scores {
		if s > bestScore {
			bestScore = s
			best = tod
		}
	}
	return best
}

// eventTimestamps extracts timestamps from the action's event map, all normalised to UTC.
// Keys may be RFC3339Nano, RFC3339, or bare ISO-8601 (no offset, treated as UTC).
func eventTimestamps(action *domain.Action) []time.Time {
	var times []time.Time
	for k := range action.Events() {
		if t, err := utils.ParseTimestamp(k); err == nil {
			times = append(times, t)
		}
	}
	return times
}

// averageInterval returns the mean duration between consecutive timestamps.
// This is used as a fallback when all seasonal weights are negligible.
func averageInterval(sorted []time.Time) time.Duration {
	var total time.Duration
	for i := 1; i < len(sorted); i++ {
		total += sorted[i].Sub(sorted[i-1]).Abs()
	}
	return total / time.Duration(len(sorted)-1)
}

// nearestQuarter rounds a minute value to the nearest quarter-hour mark (0, 15, 30, 45).
func nearestQuarter(minute int) int {
	marks := [4]int{0, 15, 30, 45}
	best := marks[0]
	bestDiff := abs(minute - best)
	for _, m := range marks[1:] {
		if d := abs(minute - m); d < bestDiff {
			bestDiff = d
			best = m
		}
	}
	return best
}

func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}
