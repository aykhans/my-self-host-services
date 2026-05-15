package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	decisionsActive = prometheus.NewGaugeVec(prometheus.GaugeOpts{
		Name: "crowdsec_decisions_active",
		Help: "Active CrowdSec decisions counted directly from LAPI (no gauge drift).",
	}, []string{"origin", "scenario", "type"})

	decisionsUniqueIPs = prometheus.NewGaugeVec(prometheus.GaugeOpts{
		Name: "crowdsec_decisions_unique_ips",
		Help: "Unique IPs with at least one active decision, grouped by origin.",
	}, []string{"origin"})

	decisionsUniqueIPsTotal = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "crowdsec_decisions_unique_ips_total",
		Help: "Unique IPs with at least one active decision across all origins.",
	})

	lastFetchUnix = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "crowdsec_exporter_last_fetch_unix",
		Help: "Unix timestamp of the last successful LAPI fetch.",
	})

	fetchErrors = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "crowdsec_exporter_fetch_errors",
		Help: "1 if the most recent fetch errored, else 0.",
	})
)

type decision struct {
	Origin   string `json:"origin"`
	Scenario string `json:"scenario"`
	Type     string `json:"type"`
	Value    string `json:"value"`
}

func init() {
	prometheus.MustRegister(
		decisionsActive,
		decisionsUniqueIPs,
		decisionsUniqueIPsTotal,
		lastFetchUnix,
		fetchErrors,
	)
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func fetchAndUpdate(client *http.Client, lapiURL, apiKey string) {
	req, _ := http.NewRequest("GET", lapiURL+"/v1/decisions", nil)
	req.Header.Set("X-Api-Key", apiKey)
	req.Header.Set("User-Agent", "crowdsec-exporter/1.0")

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("[error] fetch failed: %v", err)
		fetchErrors.Set(1)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		log.Printf("[error] LAPI returned status %d", resp.StatusCode)
		fetchErrors.Set(1)
		return
	}

	var data []decision
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		log.Printf("[error] decode failed: %v", err)
		fetchErrors.Set(1)
		return
	}

	type key struct{ origin, scenario, dtype string }
	counts := map[key]int{}
	ips := map[string]map[string]struct{}{}
	allIPs := map[string]struct{}{}

	for _, d := range data {
		origin := d.Origin
		if origin == "" {
			origin = "unknown"
		}
		scenario := d.Scenario
		if scenario == "" {
			scenario = "unknown"
		}
		dtype := d.Type
		if dtype == "" {
			dtype = "unknown"
		}
		counts[key{origin, scenario, dtype}]++
		if d.Value != "" {
			if _, ok := ips[origin]; !ok {
				ips[origin] = map[string]struct{}{}
			}
			ips[origin][d.Value] = struct{}{}
			allIPs[d.Value] = struct{}{}
		}
	}

	decisionsActive.Reset()
	decisionsUniqueIPs.Reset()
	for k, n := range counts {
		decisionsActive.WithLabelValues(k.origin, k.scenario, k.dtype).Set(float64(n))
	}
	for origin, s := range ips {
		decisionsUniqueIPs.WithLabelValues(origin).Set(float64(len(s)))
	}
	decisionsUniqueIPsTotal.Set(float64(len(allIPs)))

	fetchErrors.Set(0)
	lastFetchUnix.Set(float64(time.Now().Unix()))

	log.Printf("[ok] %d decisions, %d unique IPs across %d origins",
		len(data), len(allIPs), len(ips))
}

func main() {
	lapiURL := getenv("CROWDSEC_LAPI_URL", "http://crowdsec:8080")
	apiKey := os.Getenv("CROWDSEC_API_KEY")
	if apiKey == "" {
		log.Fatal("CROWDSEC_API_KEY env var required")
	}
	intervalStr := getenv("POLL_INTERVAL_SECS", "30")
	interval, err := strconv.Atoi(intervalStr)
	if err != nil || interval < 1 {
		log.Fatalf("invalid POLL_INTERVAL_SECS: %q", intervalStr)
	}
	port := getenv("LISTEN_PORT", "9100")

	client := &http.Client{Timeout: 10 * time.Second}

	go func() {
		for {
			fetchAndUpdate(client, lapiURL, apiKey)
			time.Sleep(time.Duration(interval) * time.Second)
		}
	}()

	http.Handle("/metrics", promhttp.Handler())
	log.Printf("[start] listening :%s, polling %s every %ds", port, lapiURL, interval)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}
