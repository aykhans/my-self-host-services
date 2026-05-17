package main

import (
	"encoding/json"
	"log"
	"net/http"
	"net/netip"
	"os"
	"strconv"
	"time"

	"github.com/oschwald/geoip2-golang/v2"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var geoDB *geoip2.Reader

// countryFlag converts a 2-letter ISO-3166-1 alpha-2 country code into its
// emoji flag using the Unicode regional indicator pairs trick (A-Z -> 0x1F1E6-FF).
func countryFlag(iso string) string {
	if len(iso) != 2 {
		return ""
	}
	a, b := iso[0], iso[1]
	if a < 'A' || a > 'Z' || b < 'A' || b > 'Z' {
		return ""
	}
	return string([]rune{rune(a-'A') + 0x1F1E6, rune(b-'A') + 0x1F1E6})
}

// lookupGeo returns "<flag> <country name> (<city>)" for the given IP, falling
// back gracefully (empty string, missing flag, missing city) when the DB is
// unavailable or the IP can't be resolved.
func lookupGeo(ip string) string {
	if geoDB == nil {
		return ""
	}
	addr, err := netip.ParseAddr(ip)
	if err != nil {
		return ""
	}
	rec, err := geoDB.City(addr)
	if err != nil || rec == nil {
		return ""
	}
	iso := rec.Country.ISOCode
	name := rec.Country.Names.English
	if name == "" {
		name = iso
	}
	out := name
	if flag := countryFlag(iso); flag != "" {
		out = flag + " " + name
	}
	if city := rec.City.Names.English; city != "" {
		out += " (" + city + ")"
	}
	return out
}

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

	decisionRemaining = prometheus.NewGaugeVec(prometheus.GaugeOpts{
		Name: "crowdsec_decision_remaining_seconds",
		Help: "Remaining seconds before each local decision expires. Only origin=crowdsec is exposed to keep cardinality bounded (CAPI/lists can contain tens of thousands of IPs).",
	}, []string{"origin", "ip", "country", "scenario", "type"})

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
	Duration string `json:"duration"`
}

func init() {
	prometheus.MustRegister(
		decisionsActive,
		decisionsUniqueIPs,
		decisionsUniqueIPsTotal,
		decisionRemaining,
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
	req, err := http.NewRequest("GET", lapiURL+"/v1/decisions", nil)
	if err != nil {
		log.Printf("[error] build request failed: %v", err)
		fetchErrors.Set(1)
		return
	}
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
	type localDecision struct {
		origin, ip, country, scenario, dtype string
		remaining                            float64
	}
	var locals []localDecision

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
		if origin == "crowdsec" {
			dur, perr := time.ParseDuration(d.Duration)
			if perr != nil {
				dur = 0
			}
			locals = append(locals, localDecision{origin, d.Value, lookupGeo(d.Value), scenario, dtype, dur.Seconds()})
		}
	}

	decisionsActive.Reset()
	decisionsUniqueIPs.Reset()
	decisionRemaining.Reset()
	for k, n := range counts {
		decisionsActive.WithLabelValues(k.origin, k.scenario, k.dtype).Set(float64(n))
	}
	for origin, s := range ips {
		decisionsUniqueIPs.WithLabelValues(origin).Set(float64(len(s)))
	}
	decisionsUniqueIPsTotal.Set(float64(len(allIPs)))
	for _, l := range locals {
		decisionRemaining.WithLabelValues(l.origin, l.ip, l.country, l.scenario, l.dtype).Set(l.remaining)
	}

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

	geoDBPath := getenv("GEOIP_CITY_DB", "")
	if geoDBPath != "" {
		if db, err := geoip2.Open(geoDBPath); err == nil {
			geoDB = db
			defer geoDB.Close()
			log.Printf("[start] GeoIP DB loaded: %s", geoDBPath)
		} else {
			log.Printf("[warn] GeoIP DB unavailable (%v); country label will be empty", err)
		}
	}

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
