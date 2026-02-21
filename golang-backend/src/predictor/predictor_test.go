package predictor

import (
	"fmt"
	"math"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"larko.se/poke/src/domain"
)

// ── helpers ────────────────────────────────────────────────────────────────────

// makeAction builds a minimal Action whose events come from the supplied
// RFC3339 timestamp strings.
func makeAction(timestamps ...string) *domain.Action {
	events := make(map[string]interface{}, len(timestamps))
	for _, ts := range timestamps {
		events[ts] = true
	}
	a, err := domain.NewAction("test-action", "test", events, nil)
	if err != nil {
		panic(fmt.Sprintf("failed to create action: %v", err))
	}
	return a
}

// mustParse parses an RFC3339 string and panics on failure.
func mustParse(s string) time.Time {
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		panic(err)
	}
	return t.UTC()
}

// within asserts that got is within tolerance of want.
func within(t *testing.T, want, got time.Time, tolerance time.Duration, msg string) {
	t.Helper()
	diff := got.Sub(want).Abs()
	assert.LessOrEqualf(t, diff, tolerance, "%s: want %s, got %s (diff %s)", msg, want, got, diff)
}

// ── seasonalWeight unit tests ──────────────────────────────────────────────────

func TestSeasonalWeight_SameDay(t *testing.T) {
	now := mustParse("2025-06-15T12:00:00Z")
	w := seasonalWeight(now, now)
	assert.InDelta(t, 1.0, w, 0.001, "same day should have weight 1.0")
}

func TestSeasonalWeight_SixMonthsApart(t *testing.T) {
	now := mustParse("2025-06-15T12:00:00Z")
	event := mustParse("2025-12-15T12:00:00Z") // ~183 days away
	w := seasonalWeight(event, now)
	assert.InDelta(t, 0.0, w, 0.02, "6 months apart should have weight ~0")
}

func TestSeasonalWeight_ThreeMonthsApart(t *testing.T) {
	now := mustParse("2025-06-15T12:00:00Z")
	event := mustParse("2025-03-15T12:00:00Z") // ~92 days away
	w := seasonalWeight(event, now)
	assert.InDelta(t, 0.5, w, 0.05, "3 months apart should have weight ~0.5")
}

func TestSeasonalWeight_Symmetry(t *testing.T) {
	now := mustParse("2025-06-15T12:00:00Z")
	before := mustParse("2025-04-01T12:00:00Z")
	after := mustParse("2025-09-01T12:00:00Z")
	// They are roughly equidistant from now in calendar terms; weights should be close.
	wBefore := seasonalWeight(before, now)
	wAfter := seasonalWeight(after, now)
	assert.InDelta(t, wBefore, wAfter, 0.1, "equidistant events should have similar weights")
}

func TestSeasonalWeight_YearWrapAround(t *testing.T) {
	// now = Jan 5; event = Dec 26 of previous year -> only 10 days apart via wrap
	now := mustParse("2026-01-05T00:00:00Z")
	event := mustParse("2025-12-26T00:00:00Z")
	w := seasonalWeight(event, now)
	// 10 days apart -> should be very close to 1.0
	assert.Greater(t, w, 0.98, "Dec 26 is very close to Jan 5 in seasonal terms")
}

// ── PredictNext: insufficient data ────────────────────────────────────────────

func TestPredictNext_NoEvents(t *testing.T) {
	action := makeAction()
	now := mustParse("2025-06-15T12:00:00Z")
	result := PredictNext(action, now)
	assert.Nil(t, result, "no events -> nil")
}

func TestPredictNext_OneEvent(t *testing.T) {
	action := makeAction("2025-06-15T10:00:00Z")
	now := mustParse("2025-06-20T12:00:00Z")
	result := PredictNext(action, now)
	assert.Nil(t, result, "single event -> nil")
}

// ── PredictNext: simple in-season average ─────────────────────────────────────

func TestPredictNext_SimpleWeeklyInSeason(t *testing.T) {
	// 4 events exactly 7 days apart, all in June; predict in June.
	action := makeAction(
		"2025-06-01T09:00:00Z",
		"2025-06-08T09:00:00Z",
		"2025-06-15T09:00:00Z",
		"2025-06-22T09:00:00Z",
	)
	now := mustParse("2025-06-23T12:00:00Z")
	result := PredictNext(action, now)
	require.NotNil(t, result)

	want := mustParse("2025-06-29T09:00:00Z")
	within(t, want, *result, 12*time.Hour, "weekly in-season prediction")
}

// ── Core seasonality tests ─────────────────────────────────────────────────────

// TestPredictNext_SummerCadence_PredictInSummer feeds the predictor a mix of:
//   - summer events every 3 days
//   - winter events every 7 days
//
// When "now" is summer, the prediction should reflect the ~3-day interval.
func TestPredictNext_SummerCadence_PredictInSummer(t *testing.T) {
	action := makeAction(
		// Summer: every 3 days
		"2025-06-01T10:00:00Z",
		"2025-06-04T10:00:00Z",
		"2025-06-07T10:00:00Z",
		"2025-06-10T10:00:00Z",
		// Winter: every 7 days
		"2025-12-01T10:00:00Z",
		"2025-12-08T10:00:00Z",
		"2025-12-15T10:00:00Z",
	)

	// Last event is 2025-12-15; "now" is June 2026 -- summer.
	now := mustParse("2026-06-15T12:00:00Z")
	result := PredictNext(action, now)
	require.NotNil(t, result)

	lastEvent := mustParse("2025-12-15T10:00:00Z")
	gap := result.Sub(lastEvent)

	// With summer weighting, the effective interval should be <= 4 days.
	assert.LessOrEqual(t, gap, 4*24*time.Hour,
		"summer 'now' should produce a short (<=4d) interval; got %s", gap)
}

// TestPredictNext_WinterCadence_PredictInWinter uses the same mixed data but
// "now" is in winter -- prediction should reflect the ~7-day interval.
func TestPredictNext_WinterCadence_PredictInWinter(t *testing.T) {
	action := makeAction(
		// Summer: every 3 days
		"2025-06-01T10:00:00Z",
		"2025-06-04T10:00:00Z",
		"2025-06-07T10:00:00Z",
		"2025-06-10T10:00:00Z",
		// Winter: every 7 days
		"2025-12-01T10:00:00Z",
		"2025-12-08T10:00:00Z",
		"2025-12-15T10:00:00Z",
	)

	// "now" is December -- winter.
	now := mustParse("2025-12-16T12:00:00Z")
	result := PredictNext(action, now)
	require.NotNil(t, result)

	lastEvent := mustParse("2025-12-15T10:00:00Z")
	gap := result.Sub(lastEvent)

	// With winter weighting, the effective interval should be >= 6 days.
	assert.GreaterOrEqual(t, gap, 6*24*time.Hour,
		"winter 'now' should produce a long (>=6d) interval; got %s", gap)
}

// TestPredictNext_SeasonalSymmetry verifies the direction: summer prediction
// from the last event should be a shorter gap than winter prediction.
func TestPredictNext_SeasonalSymmetry(t *testing.T) {
	action := makeAction(
		"2025-06-01T10:00:00Z",
		"2025-06-04T10:00:00Z",
		"2025-06-07T10:00:00Z",
		"2025-06-10T10:00:00Z",
		"2025-12-01T10:00:00Z",
		"2025-12-08T10:00:00Z",
		"2025-12-15T10:00:00Z",
	)
	lastEvent := mustParse("2025-12-15T10:00:00Z")

	summerNow := mustParse("2026-06-15T12:00:00Z")
	winterNow := mustParse("2025-12-16T12:00:00Z")

	summerResult := PredictNext(action, summerNow)
	winterResult := PredictNext(action, winterNow)

	require.NotNil(t, summerResult)
	require.NotNil(t, winterResult)

	summerGap := summerResult.Sub(lastEvent)
	winterGap := winterResult.Sub(lastEvent)

	assert.Less(t, summerGap, winterGap,
		"summer gap (%s) should be shorter than winter gap (%s)", summerGap, winterGap)
}

// ── Fallback: all events off-season ───────────────────────────────────────────

// TestPredictNext_AllEventsOffSeason checks that when every event is exactly
// 6 months from "now" (maximum seasonal distance, weight ~0), the predictor
// still returns a non-nil result by falling back to the unweighted average.
func TestPredictNext_AllEventsOffSeason_FallsBack(t *testing.T) {
	// "now" = June 15 -> events all in December, ~6 months away
	action := makeAction(
		"2025-12-01T10:00:00Z",
		"2025-12-08T10:00:00Z",
		"2025-12-15T10:00:00Z",
	)
	now := mustParse("2025-06-15T12:00:00Z")
	result := PredictNext(action, now)
	require.NotNil(t, result, "should fall back to unweighted average, not nil")

	// The unweighted average is 7 days; prediction = Dec 15 + 7 days
	lastEvent := mustParse("2025-12-15T10:00:00Z")
	want := lastEvent.AddDate(0, 0, 7)
	within(t, want, *result, 12*time.Hour, "fallback prediction")
}

// ── Weighted time-of-day ───────────────────────────────────────────────────────

// TestPredictNext_TimeOfDay_WeightedToSummer verifies that when all summer events
// happen at 10:00 and all winter events at 22:00, a summer "now" picks 10:00.
func TestPredictNext_TimeOfDay_WeightedToSummer(t *testing.T) {
	action := makeAction(
		// Summer events at 10:00
		"2025-06-01T10:00:00Z",
		"2025-06-04T10:00:00Z",
		"2025-06-07T10:00:00Z",
		"2025-06-10T10:00:00Z",
		// Winter events at 22:00
		"2025-12-01T22:00:00Z",
		"2025-12-08T22:00:00Z",
		"2025-12-15T22:00:00Z",
	)
	now := mustParse("2026-06-15T12:00:00Z") // summer
	result := PredictNext(action, now)
	require.NotNil(t, result)

	// Time-of-day of result should be around 10:00 UTC
	resultUTC := result.UTC()
	assert.Equal(t, 10, resultUTC.Hour(), "summer now -> time-of-day should be 10:00")
	assert.Equal(t, 0, resultUTC.Minute())
}

// TestPredictNext_TimeOfDay_WeightedToWinter verifies the same data but with a
// winter "now" picks 22:00.
func TestPredictNext_TimeOfDay_WeightedToWinter(t *testing.T) {
	action := makeAction(
		"2025-06-01T10:00:00Z",
		"2025-06-04T10:00:00Z",
		"2025-06-07T10:00:00Z",
		"2025-06-10T10:00:00Z",
		"2025-12-01T22:00:00Z",
		"2025-12-08T22:00:00Z",
		"2025-12-15T22:00:00Z",
	)
	now := mustParse("2025-12-16T12:00:00Z") // winter
	result := PredictNext(action, now)
	require.NotNil(t, result)

	resultUTC := result.UTC()
	assert.Equal(t, 22, resultUTC.Hour(), "winter now -> time-of-day should be 22:00")
	assert.Equal(t, 0, resultUTC.Minute())
}

// ── Year wrap-around ───────────────────────────────────────────────────────────

// TestPredictNext_YearWrapAround feeds December events and a January "now".
// Because Dec and Jan are adjacent on the calendar circle, those December events
// should receive high seasonal weight and produce the expected cadence.
func TestPredictNext_YearWrapAround(t *testing.T) {
	action := makeAction(
		// December events, every 7 days
		"2025-12-01T08:00:00Z",
		"2025-12-08T08:00:00Z",
		"2025-12-15T08:00:00Z",
		"2025-12-22T08:00:00Z",
		// June events, every 3 days (far from Jan, low weight)
		"2025-06-01T08:00:00Z",
		"2025-06-04T08:00:00Z",
		"2025-06-07T08:00:00Z",
	)
	// Now = January -> Dec events are close (high weight), June events are far (low weight)
	now := mustParse("2026-01-05T12:00:00Z")
	result := PredictNext(action, now)
	require.NotNil(t, result)

	lastEvent := mustParse("2025-12-22T08:00:00Z")
	gap := result.Sub(lastEvent)

	// With Jan "now" the December 7-day cadence should dominate (gap >= 6 days).
	assert.GreaterOrEqual(t, gap, 6*24*time.Hour,
		"Jan 'now' -> Dec events dominate -> gap should be ~7d; got %s", gap)
}

// ── Single-season data ─────────────────────────────────────────────────────────

// TestPredictNext_OnlySummerData_PredictInWinter checks graceful behaviour when
// there is no winter data at all but we predict in winter (all data is off-season).
// The predictor must fall back and still return a useful answer.
func TestPredictNext_OnlySummerData_PredictInWinter(t *testing.T) {
	action := makeAction(
		"2025-06-01T09:00:00Z",
		"2025-06-08T09:00:00Z",
		"2025-06-15T09:00:00Z",
	)
	now := mustParse("2025-12-15T12:00:00Z") // winter
	result := PredictNext(action, now)
	require.NotNil(t, result, "should fall back to unweighted average when no in-season data")

	lastEvent := mustParse("2025-06-15T09:00:00Z")
	want := lastEvent.AddDate(0, 0, 7) // unweighted average is 7 days
	within(t, want, *result, 12*time.Hour, "fallback from summer-only data in winter")
}

// ── nearestQuarter unit tests ──────────────────────────────────────────────────

func TestNearestQuarter(t *testing.T) {
	cases := []struct {
		in   int
		want int
	}{
		{0, 0},
		{7, 0},
		{8, 15},
		{15, 15},
		{22, 15},
		{23, 30},
		{30, 30},
		{37, 30},
		{38, 45},
		{45, 45},
		{52, 45},
		{53, 45},
	}
	for _, c := range cases {
		got := nearestQuarter(c.in)
		assert.Equalf(t, c.want, got, "nearestQuarter(%d)", c.in)
	}
}

// ── weightedAverageInterval unit tests ────────────────────────────────────────

func TestWeightedAverageInterval_UniformWeights(t *testing.T) {
	// When all events are in the same season as "now", weighted avg == unweighted avg.
	sorted := []time.Time{
		mustParse("2025-06-01T00:00:00Z"),
		mustParse("2025-06-08T00:00:00Z"),
		mustParse("2025-06-15T00:00:00Z"),
	}
	now := mustParse("2025-06-10T00:00:00Z")

	weighted := weightedAverageInterval(sorted, now)
	unweighted := averageInterval(sorted)

	// Both should round to 7 days; allow small floating-point drift.
	diff := math.Abs(float64(weighted - unweighted))
	assert.Less(t, diff, float64(time.Minute),
		"near-uniform weights: weighted (%s) should equal unweighted (%s)", weighted, unweighted)
}

func TestWeightedAverageInterval_FallbackTriggered(t *testing.T) {
	// All events are ~6 months from "now" -> total weight < minTotalWeight -> fallback.
	sorted := []time.Time{
		mustParse("2025-12-01T00:00:00Z"),
		mustParse("2025-12-08T00:00:00Z"),
	}
	now := mustParse("2025-06-01T00:00:00Z")

	weighted := weightedAverageInterval(sorted, now)
	unweighted := averageInterval(sorted)

	assert.Equal(t, unweighted, weighted, "should fall back to unweighted average")
}
