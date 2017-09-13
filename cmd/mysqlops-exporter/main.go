package main

import (
	"flag"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

var (
	optAddr      string
	optBackupDir string
)

type dirInfo struct {
	Path string
	Time int64
	Size int64
}

type sortByTime []dirInfo

func (p sortByTime) Len() int           { return len(p) }
func (p sortByTime) Less(i, j int) bool { return p[i].Time < p[j].Time }
func (p sortByTime) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }

func dirSize(path string) (int64, error) {
	var size int64
	err := filepath.Walk(path, func(_ string, info os.FileInfo, err error) error {
		if !info.IsDir() {
			size += info.Size()
		}
		return err
	})
	return size, err
}

func getLastBackupInfo() *dirInfo {
	fullbackup := filepath.Join(optBackupDir, "full")
	log.Printf("fullbackup: %s", fullbackup)
	f, err := os.Open(fullbackup)
	if err != nil {
		log.Print(err)
		return nil
	}
	names, err := f.Readdirnames(-1)
	if err != nil {
		log.Print(err)
		return nil
	}
	dirInfos := make([]dirInfo, 0)
	for _, name := range names {
		// e.g. 2017-02-04_16-10-01 (UTC+8)
		loc, _ := time.LoadLocation("Asia/Shanghai")
		t, err := time.ParseInLocation("2006-01-02_15-04-05", name, loc)
		if err != nil {
			continue
		}
		dirInfos = append(dirInfos, dirInfo{
			Path: filepath.Join(optBackupDir, "full", name),
			Time: t.Unix(),
			Size: 0,
		})
	}
	sort.Sort(sortByTime(dirInfos))
	if len(dirInfos) <= 0 {
		return nil
	}
	latest := &dirInfos[len(dirInfos)-1]
	size, err := dirSize(latest.Path)
	if err != nil {
		log.Print(err)
	}
	latest.Size = size
	log.Printf("path: %s, time: %d, size: %d", latest.Path, latest.Time, latest.Size)
	return latest
}

func getMysqlBackupLastTime() float64 {
	dirinfo := getLastBackupInfo()
	if dirinfo != nil {
		return float64(dirinfo.Time)
	} else {
		return 0.0
	}
}

func getMysqlBackupLastSize() float64 {
	dirinfo := getLastBackupInfo()
	if dirinfo != nil {
		return float64(dirinfo.Size)
	} else {
		return 0.0
	}
}

func init() {
	flag.StringVar(&optAddr, "addr", "0.0.0.0:9105", "metrics addr")
	flag.StringVar(&optBackupDir, "backup-dir", "", "backup dir")
	prometheus.Register(prometheus.NewGaugeFunc(
		prometheus.GaugeOpts{
			Subsystem: "mysqlops",
			Name:      "backup_last_time",
			Help:      "mysql backup last time",
		},
		getMysqlBackupLastTime,
	))
	prometheus.Register(prometheus.NewGaugeFunc(
		prometheus.GaugeOpts{
			Subsystem: "mysqlops",
			Name:      "backup_last_size",
			Help:      "mysql backup last size",
		},
		getMysqlBackupLastSize,
	))
}

func main() {
	flag.Parse()

	if optBackupDir == "" {
		log.Fatal("--backup-dir missing, please specify it")
	}

	http.Handle("/metrics", prometheus.Handler())
	log.Fatal(http.ListenAndServe(optAddr, nil))
}
